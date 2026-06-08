variable "boundary_cluster_url" {
  description = "HCP Boundary cluster URL (ex: https://xxxxxxxx.boundary.hashicorp.cloud)"
  type        = string
  default     = "https://a6c5f3d8-06c5-4ddf-ad50-a58bf47f604e.boundary.hashicorp.cloud"
}

variable "boundary_admin_login" {
  description = "Boundary admin login name"
  type        = string
  default     = "christian-tch"
}

variable "boundary_admin_password" {
  description = "Boundary admin password"
  type        = string
  sensitive   = true
  default = "xxxxxxxxxxxx"
}

variable "ssh_target_address" {
  description = "DNS du service SSH dans K8s"
  type        = string
  default     = "ssh-target.boundary.svc.cluster.local"
}

variable "mysql_target_address" {
  description = "DNS du service MySQL dans K8s"
  type        = string
  default     = "mysql.boundary.svc.cluster.local"
}

variable "vault_addr" {
  description = "External Vault URL reachable from the host (ex: http://192.168.49.2:30200)"
  type        = string
  default = "http://127.0.0.1:50919"
}

variable "vault_token" {
  description = "Vault root/admin token used by Terraform to configure Vault (dev mode default: root)"
  type        = string
  sensitive   = true
  default     = "xxxxxxxxxxx"
}

variable "mysql_root_password" {
  description = "MySQL root password — must match k8s/mysql/secret.yaml root-password"
  type        = string
  sensitive   = true
  default    = "xxxxxxxxxxx"
}