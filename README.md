# AFT Account Customizations

This repository is used to deploy account specific customizations using Terraform and the AFT framework. Each folder under [accounts](./accounts) corresponds to a single account within your AWS Organization. Customizations (i.e. terraform resources & customization modules) can be defined in each account specific folder.

> [!NOTE]
>
> Changes committed to this repo do `not` trigger the AFT pipeline. You have two options to trigger them:
>
> - Manually trigger each account's customization pipeline for them to pickup the changes.
>
> - Trigger the [aft-invoke-customizations](https://docs.aws.amazon.com/controltower/latest/userguide/aft-account-customization-options.html#aft-re-invoke-customizations) Step Function in the `AFT Management` AWS account to trigger customizations pipelines targeted accounts.
>
> All account customizations are defined using Terraform.
>
> You can extend the functionality of your account customization pipeline by utilizing the `API Helpers` to execute custom actions outside Terraform's runtime either with `Python` or `Bash` or both.

---

## Table of Contents

- [Account Customizations for Newly Created or Newly Imported AFT Accounts](#account-customizations-for-newly-created-or-newly-imported-aft-accounts)
- [Account Customizations for Existing AFT Accounts](#account-customizations-for-existing-aft-accounts)
- [Folder Structure](#folder-structure)
- [Customization Modules](#customization-modules)
  - [Terraform Cloud Customization Modules](#terraform-cloud-customization-modules)
- [API Helpers](#api-helpers)
  - [Python](#python)
  - [Bash](#bash)

---

## Account Customizations for Newly Created or Newly Imported AFT Accounts

Below are the steps required to start applying account specific customizations to newly created accounts:

1. Complete the requirements of the `account-request` repository by creating a new `aft-account-request` module call in the `aft-account-request` repository.

2. Back to this repo, duplicate the `template-account` folder into the `accounts` folder and rename it to match the **account_customizations_name** defined in your `aft-account-request` module call.

> [!IMPORTANT]
>
> If the account customization folder name does not match the `account_customizations_name`, AFT will not pick up any customizations and will produce an **error** during the account customization pipeline.
>
> **For example**
>
> If the `account_customizations_name` was defined like the following:
>
> ```hcl
> module "networking_account_request" {
>   source = "./modules/aft-account-request"
>
>  ... remaining account request module call ...
>
>   account_customizations_name = "accounts/networking-account"
> }
> ```
>
> Then the account customization folder in this repository must be named **networking-account**

3. Create customizations by defining inline Terraform resources or calling modules from the account's `terraform` folder.

4. Commit and push your changes to this repository.

5. Submit the account request by pushing the `aft-account-request` module call to the `aft-account-request` repository.

6. The account creation/import process can take up to 15 minutes to complete.

> [!NOTE]
>
> Submitting the account request to the `aft-account-request` repository will trigger the `ct-aft-account-request` CodePipeline within the AFT Management account. Once the `ct-aft-account-request` execution detects a new account request, it will create an account specific customization CodePipeline also within the AFT Management account. The account specific customization CodePipeline will then be triggered automatically upon its creation, which will apply any global customizations defined for the account and then subsequently apply its account customizations.

---

## Account Customizations for Existing AFT Accounts

When defining new customizations or modifying existing customizations for an existing AFT account:

1. Create new or change existing customizations within the account's `terraform` folder.

2. Commit and push the changes

3. Apply the customizations. You have three options:
  - Manually, through the CodePipeline console `Release Change` button
  - Locally, using the `file-generator.py` script
  - Automatically, via the `aft-invoke-customizations` Step Function


> [!NOTE]
>
> Instructions for each of these options are available in the `aft-main` repository's `README.md` file.

---

## Customization Modules

The `modules` folder contains the terraform modules that can be called by an account to apply customizations.

### Terraform Cloud Customization Modules

If you have integrated `AFT` with `Terraform Cloud`, you need to be aware that the way you must call a customization module is different than you normally would if you were using `Terraform OSS` (i.e. not using Terraform Cloud).

For context, given the location of the modules folder within this repository, you would normally call a specific module like the following:

```hcl
module "customization_module" {
  source = "../../../modules/customization_module"
}
```

However, Terraform Cloud will not be able to locate the source path within this repository which results in an error.

To resolve this issue, you need ensure the following:

1. For any account utilizing a customization module, its `pre-api-helpers.sh` script contains the following:

```bash
#!/bin/bash
# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#

echo "Executing Pre-API Helpers"

echo "DEFAULT_PATH" $DEFAULT_PATH
ls $DEFAULT_PATH
cp -rf $DEFAULT_PATH/modules $DEFAULT_PATH/$CUSTOMIZATION/terraform/
```

2. All customization module calls are defined using the following `source` path:

```hcl
module "customization_module" {
  source = "./modules/customization_module"
}
```

---

## Folder Structure

```
aft-account-customizations/
├── accounts/
│   ├── account-name/
│   │   ├── api_helpers/
│   │   │   ├── python/
│   │   │   │   └── requirements.txt
│   │   │   ├── post-api-helpers.sh
│   │   │   └── pre-api-helpers.sh
│   │   │
│   │   └── terraform/
│   │       ├── aft-providers.jinja
│   │       ├── backend.jinja
│   │       └── versions.tf
│   │       └── other-terraform-customization-files....
│   │
├── modules/
│   │
└── template-account/
```

### API Helpers

The purpose of API helpers is to perform actions that cannot be performed within Terraform.

#### Python

The `api_helpers/python` folder contains a `requirements.txt`, where you can specify libraries/packages to be installed via `PIP`.

#### Bash

> [!NOTE]
>
> The `pre-api-helpers.sh` & `post-api-helpers.sh` bash scripts can be used to extend the functionality of your global customization pipeline by performing other actions, such as:
>
> - Leveraging the `AWS CLI`
> - Executing custom custom actions via `Bash scripting`

The `pre-api-helpers.sh & post-api-helpers.sh` files are where you can define what runs **before** or **after** AFT executes Terraform.

You can also set the order of which to execute multiple `Python scripts` and pass `command line parameters` defined in the `api_helpers/python` folder.

---
