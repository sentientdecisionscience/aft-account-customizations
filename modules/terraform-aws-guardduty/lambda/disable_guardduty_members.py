import json
import logging
import os
import boto3
import time
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def get_all_members(guardduty_client, detector_id, only_associated=True):
    #
    # Get all GuardDuty Memeber Account IDs
    #
    members = []
    paginator = guardduty_client.get_paginator('list_members')

    try:
        page_iterator = paginator.paginate(
            DetectorId=detector_id,
            OnlyAssociated=str(only_associated).lower()
        )
        for page in page_iterator:
            members.extend(page.get('Members', []))
        return members
    except ClientError as e:
        logger.error(f"Error listing members: {str(e)}")
        raise

def process_members_in_batches(members, batch_size=50):
    #
    # Process member accounts in batches
    #
    for i in range(0, len(members), batch_size):
        yield members[i:i + batch_size]

# Checking if any orphaned accounts exist. If an account was a member of the GuardDuty organization
# but is no longer a member of the organization, it will be left in a SUSPENDED state.
# Any SUSPENDED accounts need to be removed before disabling GuardDuty in current member accounts.
def remove_suspended_accounts(guardduty_client, detector_id):
    logger.info("\nChecking for suspended member accounts...")
    all_members = get_all_members(guardduty_client, detector_id, only_associated=False)
    suspended_members = [member for member in all_members if member.get('RelationshipStatus') == 'AccountSuspended']

    if suspended_members:
        logger.info(f"Found {len(suspended_members)} suspended member accounts")
        suspended_account_ids = [member['AccountId'] for member in suspended_members]

        for batch in process_members_in_batches(suspended_account_ids):
            try:
                # Disassociate suspended members
                logger.info(f"Disassociating batch of {len(batch)} suspended accounts...")
                guardduty_client.disassociate_members(
                    DetectorId=detector_id,
                    AccountIds=batch
                )

                # Delete suspended members
                logger.info(f"Deleting batch of {len(batch)} suspended accounts...")
                guardduty_client.delete_members(
                    DetectorId=detector_id,
                    AccountIds=batch
                )

                # Rate limiting protection
                time.sleep(2)
            except ClientError as e:
                logger.error(f"Error processing suspended accounts: {str(e)}")
                raise

        logger.info("Suspended accounts have been removed from the GuardDuty's organization.")
    else:
        logger.info("No suspended member accounts found.")

def lambda_handler(event, context):
    #
    # Disassociate and delete all GuardDuty members from its organization configuration
    #
    try:
        detector_id = os.environ.get('DETECTOR_ID')
        if not detector_id:
            error_msg = "DETECTOR_ID environment variable not set"
            logger.error(error_msg)
            return {
                'statusCode': 400,
                'body': json.dumps({'error': error_msg})
            }

        guardduty_client = boto3.client('guardduty')

        #
        # Steps taken to remove each member account
        # GuardDuty in member accounts will be left in a SUSPENDED state
        #

        # Step 1: Check & remove any suspended organization accounts
        remove_suspended_accounts(guardduty_client, detector_id)

        # Step 2: Get list of associated member accounts
        members = get_all_members(guardduty_client, detector_id, only_associated=True)
        enabled_members = [member['AccountId'] for member in members]

        # Track results
        results = {
            'suspended_accounts_removed': True,
            'successful_accounts': [],
            'failed_accounts': []
        }

        if enabled_members:
            logger.info(f"Found {len(enabled_members)} enabled member accounts")

            for batch in process_members_in_batches(enabled_members):
                try:
                    # Step 3: Stop monitoring members accounts
                    logger.info(f"Stopping monitoring for batch of {len(batch)} accounts...")
                    guardduty_client.stop_monitoring_members(
                        DetectorId=detector_id,
                        AccountIds=batch
                    )

                    # Step 4: Disassociate member accounts
                    logger.info(f"Disassociating batch of {len(batch)} accounts...")
                    guardduty_client.disassociate_members(
                        DetectorId=detector_id,
                        AccountIds=batch
                    )

                    # Step 5: Delete member accounts from GuardDuty organization
                    logger.info(f"Deleting batch of {len(batch)} accounts...")
                    guardduty_client.delete_members(
                        DetectorId=detector_id,
                        AccountIds=batch
                    )

                    results['successful_accounts'].extend(batch)

                     # Rate limiting protection
                    time.sleep(2)
                except ClientError as e:
                    logger.warning(f"Error processing batch of accounts: {str(e)}")
                    results['failed_accounts'].extend(batch)

            logger.info("\n*****IMPORTANT*****")
            logger.info("\nGuardDuty is now SUSPENDED in all member accounts.")
            logger.info("\nGuardDuty does not continue to incur costs when SUSPENDED unless you have any active Malware Protection Plans for S3.")
            logger.info("In this case only these plans will continue to incur costs")
            logger.info("\nTo remove a Malware Protection Plan for S3, you will need to manually disable the plan directly in the member account")
        else:
            logger.info("No associated member accounts found. Nothing to remove.")

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'GuardDuty cleanup completed',
                'results': results
            })
        }

    except Exception as e:
        error_msg = f"Unexpected error in cleanup_guardduty: {str(e)}"
        logger.error(error_msg)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': error_msg})
        }
