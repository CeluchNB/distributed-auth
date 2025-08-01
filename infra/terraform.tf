terraform {

  cloud {
    organization = "noahceluch"

    workspaces {
      name = "distributed-auth"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.6.0"
    }

    auth0 = {
      source = "auth0/auth0"
      version = "1.25.0"
    }

    archive = {
      source = "hashicorp/archive"
    }
    null = {
      source = "hashicorp/null"
    }
  }

  required_version = ">= 1.2"
}

provider "aws" {
  region = "us-east-1"
}

provider "auth0" {}