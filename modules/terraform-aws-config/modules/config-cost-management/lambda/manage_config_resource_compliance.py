import boto3
import argparse
import sys
import json
import os
import logging
from typing import Dict, List, Tuple, Optional

# Initialize logger
logger = logging.getLogger()
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()  # Default log level is INFO
logger.setLevel(LOG_LEVEL)
region = os.environ.get('AWS_REGION')

# Initialize AWS clients
sts_client = boto3.client("sts", region_name=region)
ssm_client = boto3.client("ssm", region_name=region)

# Parameter Store path for storing Config Recorder settings for each account
PARAMETER_PREFIX = "/config-recorder/settings/"

class AccountProcessingError(Exception):
    """Custom exception for account processing errors"""
    pass

def assume_role(account_id: str, role_name: str) -> Optional[Dict]:
    """Assume the user specified IAM role in the target member account."""

    role_arn = f"arn:aws:iam::{account_id}:role/{role_name}"
    try:
        response = sts_client.assume_role(
            RoleArn=role_arn,
            RoleSessionName="ConfigResourceComplianceOverride"
        )
        logger.info(f"✅ Assumed role {role_name} in account {account_id}")
        return response["Credentials"]
    except Exception as e:
        error_msg = f"Failed to assume role {role_name} in account {account_id}: {str(e)}"
        logger.error(f"❌ {error_msg}")
        raise AccountProcessingError(error_msg)

def get_config_recorder(config_client, account_id: str) -> Dict:
    """Fetches the settings of the target AWS account's Config Recorder."""

    try:
        response = config_client.describe_configuration_recorders()
        if not response.get("ConfigurationRecorders"):
            error_msg = f"No Config Recorder found in account {account_id}"
            logger.warning(f"⚠️ {error_msg}")
            raise AccountProcessingError(error_msg)
        return response["ConfigurationRecorders"][0]
    except Exception as e:
        error_msg = f"Failed to retrieve Config Recorder in account {account_id}: {str(e)}"
        logger.error(f"❌ {error_msg}")
        raise AccountProcessingError(error_msg)

def store_original_recorder_settings(account_id: str, all_supported: bool, include_global: bool, existing_exclusions: List[str] = None) -> None:
    """Stores the original Config Recorder values in AWS SSM Parameter Store."""

    param_name = f"{PARAMETER_PREFIX}{account_id}"
    value = {
        "allSupported": all_supported,
        "includeGlobalResourceTypes": include_global,
        "exclusionByResourceTypes": existing_exclusions or []
    }
    value = json.dumps(value)

    try:
        ssm_client.put_parameter(
            Name=param_name,
            Description=f"AWS Config Recorder settings for member account {account_id}",
            Value=value,
            Type="String",
            Overwrite=True
        )
        logger.info(f"💾 Stored previous Config Recorder settings for account {account_id}: {value}")
    except Exception as e:
        error_msg = f"Failed to store settings in SSM for account {account_id}: {str(e)}"
        logger.error(f"❌ {error_msg}")
        raise AccountProcessingError(error_msg)

def get_original_recorder_settings(account_id: str) -> Tuple[bool, bool, List[str]]:
    """Retrieves the original Config Recorder settings from AWS SSM Parameter Store."""

    param_name = f"{PARAMETER_PREFIX}{account_id}"

    try:
        response = ssm_client.get_parameter(Name=param_name)
        settings = json.loads(response["Parameter"]["Value"])
        logger.info(f"📥 Retrieved stored settings for account {account_id}: {settings}")
        return (
            settings["allSupported"],
            settings["includeGlobalResourceTypes"],
            settings.get("exclusionByResourceTypes", [])
        )

    except ssm_client.exceptions.ParameterNotFound:
        logger.warning(f"⚠️ No previous settings found for account {account_id}. Defaulting to True, True, [].")

        # If no parameter store parameters exist,
        # allSupported and includeGlobalResourceTypes are set to True
        # and exclusionByResourceTypes is set to an empty list
        return True, True, []

    except Exception as e:
        error_msg = f"Failed to retrieve settings from SSM for account {account_id}: {str(e)}"
        logger.error(f"❌ {error_msg}")
        raise AccountProcessingError(error_msg)

def delete_param_store_parameter(account_id: str) -> None:
    """Deletes the Parameter Store Parameter after ResourceCompliance has been enabled."""

    param_name = f"{PARAMETER_PREFIX}{account_id}"

    try:
        ssm_client.delete_parameter(Name=param_name)
        logger.info(f"🗑️ Deleted stored settings for account {account_id} from Parameter Store")
    except ssm_client.exceptions.ParameterNotFound:
        # Don't log anything for parameter not found as this is an expected case
        pass
    except Exception as e:
        error_msg = f"Failed to delete settings from SSM for account {account_id}: {str(e)}"
        logger.error(f"❌ {error_msg}")
        raise AccountProcessingError(error_msg)

def update_resource_exclusion(config_client, recorder: Dict, account_id: str, mode: str) -> str:
    """Modifies AWS Config Recorder settings to either enable or disable AWS::Config::ResourceCompliance."""

    recorder_name = recorder["name"]
    role_arn = recorder["roleARN"]

    # Store the current Config Recorder settings
    current_recording_group = recorder.get("recordingGroup", {})
    current_all_supported = current_recording_group.get("allSupported", True)
    current_include_global = current_recording_group.get("includeGlobalResourceTypes", True)
    current_exclusions = current_recording_group.get("exclusionByResourceTypes", {}).get("resourceTypes", [])

    logger.info(f"📌 Current settings in {account_id}: allSupported={current_all_supported}, "
                f"includeGlobalResourceTypes={current_include_global}, exclusions={current_exclusions}")

    if mode == "disable":
        # Store current Config Recorder settings including any existing exclusions
        store_original_recorder_settings(
            account_id,
            current_all_supported,
            current_include_global,
            current_exclusions
        )

        # Add ResourceCompliance to existing exclusions if not already present
        updated_exclusions = current_exclusions.copy()
        if "AWS::Config::ResourceCompliance" not in updated_exclusions:
            updated_exclusions.append("AWS::Config::ResourceCompliance")

        updated_recording_group = {
            "recordingStrategy": {"useOnly": "EXCLUSION_BY_RESOURCE_TYPES"},
            "allSupported": False,
            "includeGlobalResourceTypes": False,
            "resourceTypes": [],
            "exclusionByResourceTypes": {"resourceTypes": updated_exclusions}
        }
        logger.info(f"🚫 Updated exclusions in account {account_id}: {updated_exclusions}")

    else:  # mode == "enable"

        # Retrieve the Accounts original Config Recorder settings from Parameter Store
        # If no param store parameter exists for the account, set default values
        # Default values are allSupported = True, includeGlobalResourceTypes = True
        # and exclusionByResourceTypes = []
        restored_all_supported, restored_include_global, restored_exclusions = get_original_recorder_settings(account_id)

        # Remove ResourceCompliance from restored exclusions if present
        final_exclusions = [rt for rt in restored_exclusions if rt != "AWS::Config::ResourceCompliance"]

        # Determine recording strategy and group settings based on exclusions
        if final_exclusions:
            updated_recording_group = {
                "recordingStrategy": {"useOnly": "EXCLUSION_BY_RESOURCE_TYPES"},
                "allSupported": restored_all_supported,
                "includeGlobalResourceTypes": restored_include_global,
                "resourceTypes": [],
                "exclusionByResourceTypes": {"resourceTypes": final_exclusions}
            }
            strategy_msg = f"using EXCLUSION_BY_RESOURCE_TYPES with exclusions={final_exclusions}"
        else:
            updated_recording_group = {
                "recordingStrategy": {"useOnly": "ALL_SUPPORTED_RESOURCE_TYPES"},
                "allSupported": restored_all_supported,
                "includeGlobalResourceTypes": restored_include_global
            }
            strategy_msg = "using ALL_SUPPORTED_RESOURCE_TYPES"

        # Delete the parameter store parameter after getting the original settings
        # This is done to ensure that the parameter store parameter is deleted
        # after the original settings have been restored
        delete_param_store_parameter(account_id)

        logger.info(f"✅ Restoring AWS Config settings in account {account_id}: "
                    f"allSupported={restored_all_supported}, "
                    f"includeGlobalResourceTypes={restored_include_global}, {strategy_msg}")

    try:
        config_client.put_configuration_recorder(
            ConfigurationRecorder={
                "name": recorder_name,
                "roleARN": role_arn,
                "recordingGroup": updated_recording_group
            }
        )
        logger.info(f"✅ Successfully updated Config Recorder {recorder_name} in account {account_id}")
        return "Success"
    except Exception as e:
        error_msg = f"Failed to update Config Recorder in account {account_id}: {str(e)}"
        logger.error(f"❌ {error_msg}")
        raise AccountProcessingError(error_msg)

def lambda_handler(event, context):
    """Lambda function handler: Enables or disables AWS::Config::ResourceCompliance in target accounts."""

    logger.info(f"📥 Received event: {json.dumps(event)}")

    account_ids = event.get("accounts", [])
    role_name = event.get("default_role", "AWSControlTowerExecution")
    mode = event.get("mode", "disable")

    # Validate the input
    if not account_ids or mode not in ["disable", "enable"]:
        logger.error("❌ Invalid input: Must provide accounts and valid mode.")
        return {
            "statusCode": 400,
            "body": json.dumps({
                "status": "error",
                "message": "Invalid input: Must provide accounts and valid mode"
            })
        }

    results = {
        "successful": [],
        "failed": []
    }

    # Process each target account
    for account_id in account_ids:
        logger.info(f"\n🚀 Processing account {account_id} in {mode}-mode...")
        try:
            if process_account(account_id, role_name, mode):
                results["successful"].append(account_id)
            else:
                results["failed"].append(account_id)

        except Exception as e:
            logger.error(f"❌ Unexpected error processing account {account_id}: {str(e)}")
            results["failed"].append(account_id)

    # Prepare final status message
    if results["failed"]:
        status_message = f"Completed with errors. Failed accounts: {', '.join(results['failed'])}"
        status_code = 500
    else:
        status_message = f"Successfully processed all accounts: {', '.join(results['successful'])}"
        status_code = 200

    logger.info(f"\n{'❌' if results['failed'] else '✅'} Lambda execution completed: {status_message}")

    return {
        "statusCode": status_code,
        "body": json.dumps({
            "status": "completed",
            "message": status_message,
            "results": results
        })
    }

def process_account(account_id: str, role_name: str, mode: str) -> bool:
    """Processes the target AWS account. Returns True if successful, False otherwise."""

    try:
        # Assume the target accounts IAM role
        credentials = assume_role(account_id, role_name)

        session = boto3.Session(
            aws_access_key_id=credentials["AccessKeyId"],
            aws_secret_access_key=credentials["SecretAccessKey"],
            aws_session_token=credentials["SessionToken"]
        )

        config_client = session.client("config", region_name=region)

        # Get the target accounts current Config Recorder settings
        recorder = get_config_recorder(config_client, account_id)

        # Update the Config Recorder settings
        update_resource_exclusion(config_client, recorder, account_id, mode)

        return True

    except AccountProcessingError:
        return False
    except Exception as e:
        logger.error(f"❌ Unexpected error processing account {account_id}: {str(e)}")
        return False

def main():
    """Main function to execute the script."""

    # Parse the command line arguments
    parser = argparse.ArgumentParser(description="Enable or disable AWS::Config::ResourceCompliance in AWS Config for specified accounts.")
    parser.add_argument("--accounts", required=True, type=str, help="Comma-separated list of AWS account IDs.")
    parser.add_argument("--default-role", required=True, type=str, help="IAM role to assume.")
    parser.add_argument("--mode", required=True, choices=["disable", "enable"], help="Mode: disable or enable.")

    args = parser.parse_args()
    account_ids = [account.strip() for account in args.accounts.split(",")]

    # Track success/failure for each account
    results = {
        "successful": [],
        "failed": []
    }

    # Process each target account
    for account_id in account_ids:
        logger.info(f"\n🚀 Processing account {account_id} in {args.mode}-mode...")
        if process_account(account_id, args.default_role, args.mode):
            results["successful"].append(account_id)
        else:
            results["failed"].append(account_id)

    # Log final results
    if results["failed"]:
        logger.error("\n❌ Script execution completed with errors:")
        logger.info(f"   Successfully processed accounts: {', '.join(results['successful']) if results['successful'] else 'None'}")
        logger.error(f"   Failed to process accounts: {', '.join(results['failed'])}")
        sys.exit(1)
    else:
        logger.info("\n✅ Script execution completed successfully:")
        logger.info(f"   Successfully processed all accounts: {', '.join(results['successful'])}")
        sys.exit(0)

if __name__ == "__main__":
    main()
