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
      version = "~> 5.31.0"
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