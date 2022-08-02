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
  }
}

provider "random" {}
provider "auth0" {}

resource "random_pet" "client_name" {}

resource "auth0_client" "client" {
  name           = random_pet.client_name.id
  description    = "Client configured for device authorization flow"
  app_type       = "native"
  is_first_party = true
  jwt_configuration {
    alg = "RS256"
  }
  grant_types     = ["urn:ietf:params:oauth:grant-type:device_code", "refresh_token"]
  oidc_conformant = true
  token_endpoint_auth_method = "none"
}

output "AUTH0_CLIENT_ID" {
  sensitive = true
  value     = auth0_client.client.client_id
}

data "auth0_tenant" "current" {}

output "AUTH0_ISSUER_BASE_URL" {
  sensitive = true
  value     = "https://${data.auth0_tenant.current.domain}"
}
