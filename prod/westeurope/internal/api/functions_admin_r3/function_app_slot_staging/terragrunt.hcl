dependency "function_app" {
  config_path = "../function_app"
}

dependency "subnet" {
  config_path = "../subnet"
}

dependency "cosmosdb_account" {
  config_path = "../../cosmosdb/account"
}

dependency "cosmosdb_database" {
  config_path = "../../cosmosdb/database"
}

dependency "storage_account" {
  config_path = "../../storage/account"
}

# Internal
dependency "resource_group" {
  config_path = "../../../resource_group"
}

dependency "subnet_apimapi" {
  config_path = "../../../api/apim/subnet"
}

# Common
dependency "virtual_network" {
  config_path = "../../../../common/virtual_network"
}

dependency "application_insights" {
  config_path = "../../../../common/application_insights"
}

dependency "key_vault" {
  config_path = "../../../../common/key_vault"
}

dependency "storage_account_assets" {
  config_path = "../../../../common/cdn/storage_account_assets"
}

dependency "subnet_azure_devops" {
  config_path = "../../../../common/subnet_azure_devops"
}

dependency "storage_container_message-content" {
  config_path = "../../storage/container_message-content"
}

dependency "storage_account_user-data-download" {
  config_path = "../../storage_user-data-download/account"
}

dependency "storage_container_user-data-download" {
  config_path = "../../storage_user-data-download/container_user-data-download"
}

dependency "storage_account_userbackups" {
  config_path = "../../storage_userbackups/account"
}

dependency "storage_container_user-data-backup" {
  config_path = "../../storage_userbackups/container_user-data-backup"
}

dependency "app_service_appbackend" {
  config_path = "../../../../linux/appbackendli/app_service"
}

dependency "storage_table_subscriptionsfeedbyday" {
  config_path = "../../storage/table_subscriptionsfeedbyday"
}

dependency "storage_table_faileduserdataprocessing" {
  config_path = "../../storage/table_faileduserdataprocessing"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}


terraform {
  source = "git::git@github.com:pagopa/io-infrastructure-modules-new.git//azurerm_function_app_slot?ref=v3.0.3"
}

inputs = {
  name                       = "staging"
  resource_group_name        = dependency.resource_group.outputs.resource_name
  function_app_name          = dependency.function_app.outputs.name
  function_app_resource_name = dependency.function_app.outputs.resource_name
  app_service_plan_id        = dependency.function_app.outputs.app_service_plan_id
  storage_account_name       = dependency.function_app.outputs.storage_account.name
  storage_account_access_key = dependency.function_app.outputs.storage_account.primary_access_key

  runtime_version = "~3"

  application_insights_instrumentation_key = dependency.application_insights.outputs.instrumentation_key

  health_check_path = "info"

  # site_config
  pre_warmed_instance_count = 1

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME     = "node"
    WEBSITE_NODE_DEFAULT_VERSION = "14.16.0"
    WEBSITE_RUN_FROM_PACKAGE     = "1"
    NODE_ENV                     = "production"

    # DNS and VNET configuration to use private endpoint
    WEBSITE_DNS_SERVER     = "168.63.129.16"
    WEBSITE_VNET_ROUTE_ALL = 1

    COSMOSDB_URI               = dependency.cosmosdb_account.outputs.endpoint
    COSMOSDB_KEY               = dependency.cosmosdb_account.outputs.primary_master_key
    COSMOSDB_NAME              = dependency.cosmosdb_database.outputs.name
    COSMOSDB_CONNECTION_STRING = dependency.cosmosdb_account.outputs.connection_strings[0]

    StorageConnection = dependency.storage_account.outputs.primary_connection_string

    AssetsStorageConnection = dependency.storage_account_assets.outputs.primary_connection_string

    AZURE_APIM                = "io-p-apim-api"
    AZURE_APIM_HOST           = "api-internal.io.italia.it"
    AZURE_APIM_RESOURCE_GROUP = "io-p-rg-internal"

    MESSAGE_CONTAINER_NAME = dependency.storage_container_message-content.outputs.name

    UserDataArchiveStorageConnection = dependency.storage_account_user-data-download.outputs.primary_connection_string
    USER_DATA_CONTAINER_NAME         = dependency.storage_container_user-data-download.outputs.name

    PUBLIC_API_URL           = "http://api-internal.io.italia.it/"
    PUBLIC_DOWNLOAD_BASE_URL = "https://${dependency.storage_account_user-data-download.outputs.primary_blob_host}/${dependency.storage_container_user-data-download.outputs.name}"

    SESSION_API_URL                 = "https://${dependency.app_service_appbackend.outputs.default_site_hostname}"
    UserDataBackupStorageConnection = dependency.storage_account_userbackups.outputs.primary_connection_string
    USER_DATA_BACKUP_CONTAINER_NAME = dependency.storage_container_user-data-backup.outputs.name
    USER_DATA_DELETE_DELAY_DAYS     = 6
    FF_ENABLE_USER_DATA_DELETE      = 1

    // Disabled functions - Slot settings only.
    "AzureWebJobs.UserDataProcessingTrigger.Disabled"  = "1"
    "AzureWebJobs.UpdateVisibleServicesCache.Disabled" = "1"
    "AzureWebJobs.UpdateVisibleServicesCacheOrchestrator.Disabled" = "1"
    "AzureWebJobs.UpdateVisibleServicesCacheActivity.Disabled" = "1"

    SLOT_TASK_HUBNAME = "StagingTaskHub"

    MAIL_FROM = "IO - l'app dei servizi pubblici <no-reply@io.italia.it>"

    SUBSCRIPTIONS_FEED_TABLE          = dependency.storage_table_subscriptionsfeedbyday.outputs.name
    SubscriptionFeedStorageConnection = dependency.storage_account.outputs.primary_connection_string

    // table for saving failed user data processing requests
    FAILED_USER_DATA_PROCESSING_TABLE         = dependency.storage_table_faileduserdataprocessing.outputs.name
    FailedUserDataProcessingStorageConnection = dependency.storage_account.outputs.primary_connection_string

    # this app settings is required to solve the issue:
    # https://github.com/terraform-providers/terraform-provider-azurerm/issues/10499
    WEBSITE_CONTENTSHARE = "staging-content"
  }

  app_settings_secrets = {
    key_vault_id = dependency.key_vault.outputs.id
    map = {
      LOGOS_URL = "cdn-ASSETS-URL"

      AZURE_SUBSCRIPTION_ID = "common-AZURE-SUBSCRIPTION-ID"

      ADB2C_TENANT_ID            = "adb2c-TENANT-NAME"
      ADB2C_CLIENT_ID            = "devportal-CLIENT-ID"
      ADB2C_CLIENT_KEY           = "devportal-CLIENT-SECRET"
      ADB2C_TOKEN_ATTRIBUTE_NAME = "adb2c-TOKEN-ATTRIBUTE-NAME"

      SERVICE_PRINCIPAL_CLIENT_ID = "ad-APPCLIENT-APIM-ID"
      SERVICE_PRINCIPAL_SECRET    = "ad-APPCLIENT-APIM-SECRET"
      SERVICE_PRINCIPAL_TENANT_ID = "common-AZURE-TENANT-ID"

      PUBLIC_API_KEY = "apim-IO-GDPR-SERVICE-KEY"

      SESSION_API_KEY = "appbackend-PRE-SHARED-KEY"

      __DISABLED__SENDGRID_API_KEY = "common-SENDGRID-APIKEY"
      MAILUP_USERNAME              = "common-MAILUP2-USERNAME"
      MAILUP_SECRET                = "common-MAILUP2-SECRET"
    }
  }

  allowed_subnets = [
    dependency.subnet.outputs.id,
    dependency.subnet_apimapi.outputs.id,
    dependency.subnet_azure_devops.outputs.id
  ]

  subnet_id       = dependency.subnet.outputs.id
  function_app_id = dependency.function_app.outputs.id
}
