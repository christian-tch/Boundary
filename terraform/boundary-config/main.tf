terraform {
  required_providers {
    boundary = {
      source  = "hashicorp/boundary"
      version = "~> 1.1"
    }
  }
}

provider "boundary" {
  addr                   = var.boundary_cluster_url
  auth_method_login_name = var.boundary_admin_login
  auth_method_password   = var.boundary_admin_password
}
