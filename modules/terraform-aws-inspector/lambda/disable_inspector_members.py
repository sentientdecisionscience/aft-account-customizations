import json
import logging
import os
import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    #
    # Disable Inspector for all member accounts except delegated admin
    #
    try:
        delegated_admin_id = os.environ.get('DELEGATED_ADMIN_ID')
        if not delegated_admin_id:
            error_msg = "DELEGATED_ADMIN_ID environment variable not set"
            logger.error(error_msg)
            return {
                'statusCode': 400,
                'body': json.dumps({'error': error_msg})
            }

        # Get AWS region from boto3 session
        session = boto3.Session()
        region = session.region_name
        if not region:
            logger.error("Failed to get AWS region")
            return {
                'statusCode': 500,
                'body': json.dumps({'error': 'Failed to get AWS region'})
            }

        inspector_client = session.client('inspector2')

        logger.info(f"=== Running Inspector Cleanup (Region: {region}) ===")
        logger.info(f"Delegated Admin Account: {delegated_admin_id}")

        # Get list of Inspector member accounts
        try:
            members = []
            paginator = inspector_client.get_paginator('list_members')
            for page in paginator.paginate():
                members.extend(page.get('members', []))
        except ClientError as e:
            error_msg = f"Failed to list members: {str(e)}"
            logger.error(error_msg)
            return {
                'statusCode': 500,
                'body': json.dumps({'error': error_msg})
            }

        # Print all members and their statuses for visibility
        logger.info("\nCurrent member status:")
        for member in members:
            logger.info(f"Account: {member['accountId']}, Status: {member.get('relationshipStatus', 'UNKNOWN')}")

        # Get only ENABLED Inspector member account ID's, excluding delegated admin
        member_accounts = [
            member['accountId']
            for member in members
            if (member['accountId'] != delegated_admin_id and
                member.get('relationshipStatus') == 'ENABLED')
        ]

        if not member_accounts:
            msg = "No ENABLED member accounts to process."
            logger.info(msg)
            return {
                'statusCode': 200,
                'body': json.dumps({'message': msg})
            }

        logger.info(f"\nProcessing {len(member_accounts)} ENABLED member accounts: {', '.join(member_accounts)}")

        # Track results for each account
        results = {
            'successful': [],
            'failed': []
        }

        #
        # Steps taken to disable Inspector in each member account
        # This results in Inspector being disabled in member accounts
        #

        for account_id in member_accounts:
            logger.info(f"\nProcessing account: {account_id}")
            account_success = True

            # Step 1: Disable all resource types (this triggers automatic disassociation from the delegated admin account)
            logger.info(f"Disabling all scanning features for account: {account_id}")
            try:
                # Disable each resource type
                for resource_type in ['EC2', 'ECR', 'LAMBDA', 'LAMBDA_CODE']:
                    inspector_client.disable(
                        accountIds=[account_id],
                        resourceTypes=[resource_type]
                    )
                logger.info(f"Successfully disabled all scanning features for account: {account_id}")
            except ClientError as e:
                logger.warning(f"Failed to disable features for account {account_id}: {str(e)}")
                account_success = False

            # Step 2: Completely disable the Inspector service
            if account_success:
                logger.info(f"Completely disabling Inspector for account: {account_id}")
                try:
                    inspector_client.disable(
                        accountIds=[account_id]
                    )
                    logger.info(f"Successfully disabled Inspector for account: {account_id}")
                    results['successful'].append(account_id)
                except ClientError as e:
                    logger.warning(f"Failed to completely disable Inspector for account {account_id}: {str(e)}")
                    account_success = False

            if not account_success:
                results['failed'].append(account_id)

        # Prepare response message
        response_message = {
            'message': 'Inspector cleanup completed',
            'successful_accounts': results['successful'],
            'failed_accounts': results['failed']
        }

        logger.info("\n*****IMPORTANT*****")
        logger.info("\nInspector is now DISABLED in all member accounts")
        logger.info("\nInspector does not continue to incur costs when DISABLED")

        return {
            'statusCode': 200,
            'body': json.dumps(response_message)
        }

    except Exception as e:
        error_msg = f"Unexpected error in cleanup_inspector: {str(e)}"
        logger.error(error_msg)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': error_msg})
        }
