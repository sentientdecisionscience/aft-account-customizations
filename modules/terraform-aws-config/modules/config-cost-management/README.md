# AWS Config Cost Management Module

Use this module to disable the `AWS::Config::ResourceCompliance` Recorder Resource Type in member accounts before removing an AWS Config Conformance Pack or Rule.

Subsequently, use this module to re-enable the `AWS::Config::ResourceCompliance` Recorder Resource Type after removing an AWS Config Conformance Pack or Rule.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Context](#context)
- [Module Inputs](#module-inputs)
- [Module Usage](#module-usage)
    - [Verify Lambda Execution](#verify-lambda-execution)
- [Local Execution](#local-execution)
- [Useful Notes](#useful-notes)

## Prerequisites

- The `target_iam_role_name` must be available in each member account passed in the `account_ids` parameter.
- The `target_iam_role_name` must allow the lambda function to assume the role from the organization management account and have suffiecient permissions to the accounts AWS Config Recorder.
- If running the python script locally, you must install the required python libraries in `requirements.txt`.

## Context

If you remove an AWS Config Conformance Pack or Rule without first disabling the `AWS::Config::ResourceCompliance` Recorder Resource Type, you will incur unexpected costs. You can find more information about this [here](https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config.html#config-cost-considerations).

## Module Inputs

This module creates a lambda function that accepts 3 parameters:

- `account_ids`: IDs of Organization member accounts to enable or disable the `AWS::Config::ResourceCompliance` Recorder Resource Type
- `target_iam_role_name`: Name of the IAM role the lambda function will assume in the target member accounts to update the `AWS::Config::ResourceCompliance` Recorder Resource Type
- `lambda_function_mode`: Mode that the `manage-config-resource-compliance` lambda function will execute in
  - `enable`: Enables the `AWS::Config::ResourceCompliance` Recorder Resource Type
  - `disable`: Disables the `AWS::Config::ResourceCompliance` Recorder Resource Type

## Module Usage

It is a requirement to call this module from your Organization's Management Account.

```hcl
module "config_cost_management" {
  source = "../../modules/config-cost-management"

  # List of account ids to enable or disable the AWS Config ResourceCompliance resource type
  account_ids = ["111111111111", "222222222222"]

  # Name of the IAM role the lambda function will assume in the target accounts
  # to update the AWS Config ResourceCompliance Recorder Resource
  target_iam_role_name = "AWSControlTowerExecution"

  # Mode that the manage-config-resource-compliance lambda function will execute in
  # Set to "enable" to enable the AWS Config ResourceCompliance resource type
  # Set to "disable" to disable the AWS Config ResourceCompliance resource type
  lambda_function_mode = "disable"
}
```

Run `terraform apply`.

### Verify Lambda Execution

You can verify if the `manage-config-resource-compliance` lambda function executed successfully by running the following cli command inside the target accounts or view the most recent execution of  the `manage-config-resource-compliance` lambda function in the CloudWatch Logs Group `/aws/lambda/manage-config-resource-compliance`.

#### After running in disable mode

```bash
aws configservice describe-configuration-recorders --query "ConfigurationRecorders[0].recordingGroup"
```

**Expected output:**

```json
{
    "allSupported": false,
    "includeGlobalResourceTypes": false,
    "resourceTypes": [],
    "exclusionByResourceTypes": {
        "resourceTypes": [
            "AWS::Config::ResourceCompliance"
        ]
    },
    "recordingStrategy": {
        "useOnly": "EXCLUSION_BY_RESOURCE_TYPES"
    }
}
```

#### After running in enable mode

```bash
aws configservice describe-configuration-recorders --query "ConfigurationRecorders[0].recordingGroup"
```

**Expected output:**

```json
{
    "allSupported": true,
    "includeGlobalResourceTypes": true,
    "resourceTypes": [],
    "exclusionByResourceTypes": {
        "resourceTypes": []
    },
    "recordingStrategy": {
        "useOnly": "ALL_SUPPORTED_RESOURCE_TYPES"
    }
}
```

- If the recorder was origionally excluding other resource types, the expected output will be something like the following:

```json
{
    "allSupported": false,
    "includeGlobalResourceTypes": false,
    "resourceTypes": [],
    "exclusionByResourceTypes": {
        "resourceTypes": [
            "AWS::Backup::RecoveryPoint"
        ]
    },
    "recordingStrategy": {
        "useOnly": "EXCLUSION_BY_RESOURCE_TYPES"
    }
}
```

## Local Execution

- You can run the `manage_config_resource_compliance.py` script locally. The script takes the same command line arguments as the lambda function parameters: `--accounts`, `--default-role`, and `--mode`. To execute the script, first create a python virtual environment & install the required libraries in `requirements.txt`.

**Git Bash:**

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

**Windows Powershell:**

```bash
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
```

**Mac/Linux:**

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

- Then, ensure you have active session credentials to your Organization's Management Account and run the following command:

**Windows:**

```bash
# Disable Mode
python manage_config_resource_compliance_local.py --accounts "123456789012, 234567890123" --default-role "AWSControlTowerExecution" --mode disable

# Enable Mode
python manage_config_resource_compliance_local.py --accounts "123456789012, 234567890123" --default-role "AWSControlTowerExecution" --mode enable
```

**Mac/Linux:**

```bash
# Disable Mode
AWS_REGION=us-east-1 python3 manage_config_resource_compliance_local.py --accounts "123456789012, 234567890123" --default-role "AWSControlTowerExecution" --mode disable

# Enable Mode
AWS_REGION=us-east-1 python3 manage_config_resource_compliance_local.py --accounts "123456789012, 234567890123" --default-role "AWSControlTowerExecution" --mode enable
```

## Useful Notes

1. When the script is first run in disable mode, it will store each Accounts Config Recorder settings for the `allSupported`, `includeGlobalResourceTypes` and `exclusionByResourceTypes` attributes in Parameter Store. The format of each accounts paramter is `/config-recorder/settings/<account_id>`. This is done so that when the script is run in enable mode, it can restore the original Config Recorder settings.

2. When the script is run in enable mode, it will first pull the recorders origional settings from Parameter Store. If the recorders origional settings are not found, it will set the `allSupported` and `includeGlobalResourceTypes` attributes to `true` and `exclusionByResourceTypes` to an empty list. After updating the Config Recorder settings, it will delete the Parameter Store Parameter containing the recorders origional settings.
