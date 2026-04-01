{
    "PII_Backup_Plan": {
        "regions": { "@@append":${allowed_regions} },
        "rules": {
            "Hourly": {
                "schedule_expression": { "@@assign": "cron(0 5 ? * * *)" },
                "start_backup_window_minutes": { "@@assign": "60" },
                "target_backup_vault_name": { "@@assign": "${backup_vault_name}" },
                "lifecycle": {
                    "move_to_cold_storage_after_days": { "@@assign": "28" },
                    "delete_after_days": { "@@assign": "180" },
                    "opt_in_to_archive_for_supported_resources": { "@@assign": "false" }
                },
            }
        },
        "selections": {
            "tags": {
                "datatype": {
                    "iam_role_arn": { "@@assign": "arn:aws:iam::$account:role/${role_name}" },
                    "tag_key": { "@@assign": "dataType" },
                    "tag_value": { "@@assign": [ "PII", "RED" ] }
                }
            }
        }
    }
}
