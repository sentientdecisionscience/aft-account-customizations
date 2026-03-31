module "config" {
  source = "../../"

  enable_recorder = true

  aggregator = {
    enabled          = true
    aggregation_mode = "ORGANIZATION"
    all_regions      = false
    scope_regions    = ["us-east-1"]
  }

  #Additional policy that will be assumed by the AWS Config role
  additional_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSConfigRulesExecutionRole"]

  #If you want to create a new generic bucket, set `create_delivery_bucket` to true
  #If you want to use an existing bucket, set `create_delivery_bucket` to false and specify `delivery_bucket_name`
  create_delivery_bucket = true
  #List of acceptable delivery frequencies: https://docs.aws.amazon.com/config/latest/APIReference/API_ConfigSnapshotDeliveryProperties.html#API_ConfigSnapshotDeliveryProperties_Contents
  delivery_frequency = "TwentyFour_Hours"

  recording_group = {
    include_global_resource_types = false
    # You can only specify one or nothing of the following: resource_types, excluded_resource_types.
    # If resource_types is specified, only the specified resource types going to be included in recording.
    # If excluded_resource_types is specified, all resource types except the specified ones going to be included in recording.
    # If none of them is specified, all supported resource types are included in recording.
    # If none of them is specified and include_global_resource_types is true, all supported resource types and global resource types are included in recording.
    resource_types = ["AWS::EC2::Instance"]
  }

  recording_mode = {
    recording_frequency = "CONTINUOUS"
    recording_mode_override = [
      {
        description = "AWS Config recording mode override"
        #List of available resource types: https://docs.aws.amazon.com/config/latest/APIReference/API_ResourceIdentifier.html#config-Type-ResourceIdentifier-resourceType
        resource_types      = ["AWS::EC2::Instance"]
        recording_frequency = "DAILY"
      }
    ]
  }
}
