# Lock Terraform providers to specific versions to prevent upgrades causing breaking changes

terraform {
  required_providers {
    sumologic = {
      source = "SumoLogic/sumologic"
      version = "~> 2.9.3"
    }
  }
}
