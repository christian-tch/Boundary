variable "boundary_cluster_url" {
  description = "HCP Boundary cluster URL (ex: https://xxxxxxxx.boundary.hashicorp.cloud)"
  type        = string
  default = "https://a6c5f3d8-06c5-4ddf-ad50-a58bf47f604e.boundary.hashicorp.cloud"
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
}

variable "ssh_target_address" {
  description = "DNS du service SSH dans K8s"
  type        = string
  default     = "ssh-target.boundary.svc.cluster.local"
}

variable "ssh_target_password" {
  description = "Mot de passe de l'user SSH (boundary-user)"
  type        = string
  sensitive   = true
}

variable "mysql_target_address" {
  description = "DNS du service MySQL dans K8s"
  type        = string
  default     = "mysql.boundary.svc.cluster.local"
}

variable "mysql_boundary_user" {
  description = "User MySQL pour Boundary"
  type        = string
  default     = "boundary"
}

variable "mysql_boundary_password" {
  description = "Mot de passe MySQL pour Boundary"
  type        = string
  sensitive   = true
}

variable "worker_id" {
  description = "ID du worker self-managed dans Minikube (ex: w_VYdz8lnOed)"
  type        = string
}
