# Lock Terraform providers to specific versions to prevent upgrades causing breaking changes

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.1.0"
    }
    local = {
      source = "hashicorp/local"
      version = "~> 1.4.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 2.3.0"
    }
    sumologic = {
      source = "SumoLogic/sumologic"
      version = "2.1.2"
    }
    template = {
      source = "hashicorp/template"
      version = "~> 2.1.2"
    }
    tls = {
      source = "hashicorp/tls"
      version = "~> 2.2.0"
    }
  }
}
