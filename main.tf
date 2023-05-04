terraform {
  backend "s3" {}

  required_providers {
    random = {
      source  = "registry.terraform.io/hashicorp/random"
      version = "3.2.0"
    }
    auth0 = {
      source  = "registry.terraform.io/auth0/auth0"
      version = "0.32.0"
    }
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "random" {}
provider "auth0" {}
provider "aws" {}

data "aws_region" "current" {}

resource "random_pet" "client_name" {}

resource "auth0_client" "client" {
  name           = random_pet.client_name.id
  description    = "Client configured for device authorization flow"
  app_type       = "native"
  is_first_party = true
  jwt_configuration {
    alg = "RS256"
  }
  grant_types = [
    "urn:ietf:params:oauth:grant-type:device_code", "refresh_token"
  ]
  oidc_conformant            = true
  token_endpoint_auth_method = "none"
}

resource "aws_ssm_parameter" "client_secret" {
  name        = "/auth0_cli/${auth0_client.client.name}/client-secret"
  description = "The auth0 client secret"
  type        = "SecureString"
  value       = auth0_client.client.client_secret
}

output "AUTH0_CLIENT_ID" {
  sensitive = true
  value     = auth0_client.client.client_id
}

output "AUTH0_CLIENT_SECRET" {
  value = {
    type   = "ssm"
    arn    = aws_ssm_parameter.client_secret.arn
    key    = aws_ssm_parameter.client_secret.name
    region = data.aws_region.current.name
  }
}

data "auth0_tenant" "current" {}

output "AUTH0_ISSUER_BASE_URL" {
  sensitive = true
  value     = "https://${data.auth0_tenant.current.domain}"
}
