# -------------------------------------------------------
# Host Catalog — regroupe tous les hosts du projet
# -------------------------------------------------------
resource "boundary_host_catalog_static" "minikube" {
  name        = "minikube-catalog"
  description = "Hosts dans le cluster Minikube"
  scope_id    = boundary_scope.project.id
}

# -------------------------------------------------------
# Cible SSH
# -------------------------------------------------------
resource "boundary_host_static" "ssh" {
  name            = "ssh-target"
  description     = "Pod OpenSSH dans Minikube"
  host_catalog_id = boundary_host_catalog_static.minikube.id
  address         = var.ssh_target_address
}

resource "boundary_host_set_static" "ssh" {
  name            = "ssh-host-set"
  host_catalog_id = boundary_host_catalog_static.minikube.id
  host_ids        = [boundary_host_static.ssh.id]
}

# Credentials SSH stockés dans Boundary (credential brokering)
resource "boundary_credential_store_static" "ssh" {
  name        = "ssh-credentials"
  description = "Credentials statiques pour la cible SSH"
  scope_id    = boundary_scope.project.id
}

resource "boundary_credential_username_password" "ssh" {
  name                = "ssh-boundary-user"
  description         = "User/password pour le pod SSH"
  credential_store_id = boundary_credential_store_static.ssh.id
  username            = "boundary-user"
  password            = var.ssh_target_password
}

resource "boundary_target" "ssh" {
  name         = "ssh-minikube"
  description  = "Accès SSH au pod dans Minikube"
  type         = "ssh"
  scope_id     = boundary_scope.project.id
  default_port = 2222

  host_source_ids = [boundary_host_set_static.ssh.id]

  # Injecte les credentials automatiquement à la connexion
  injected_application_credential_source_ids = [
    boundary_credential_username_password.ssh.id
  ]

  # Force l'utilisation du worker self-managed dans Minikube
  egress_worker_filter = "\"k8s\" in \"/tags/type\""
}

# -------------------------------------------------------
# Cible MySQL
# -------------------------------------------------------
resource "boundary_host_static" "mysql" {
  name            = "mysql-target"
  description     = "Pod MySQL dans Minikube"
  host_catalog_id = boundary_host_catalog_static.minikube.id
  address         = var.mysql_target_address
}

resource "boundary_host_set_static" "mysql" {
  name            = "mysql-host-set"
  host_catalog_id = boundary_host_catalog_static.minikube.id
  host_ids        = [boundary_host_static.mysql.id]
}

# Credentials MySQL stockés dans Boundary
resource "boundary_credential_store_static" "mysql" {
  name        = "mysql-credentials"
  description = "Credentials statiques pour MySQL"
  scope_id    = boundary_scope.project.id
}

resource "boundary_credential_username_password" "mysql" {
  name                = "mysql-boundary-user"
  description         = "User/password pour MySQL"
  credential_store_id = boundary_credential_store_static.mysql.id
  username            = var.mysql_boundary_user
  password            = var.mysql_boundary_password
}

resource "boundary_target" "mysql" {
  name         = "mysql-minikube"
  description  = "Accès MySQL dans Minikube"
  type         = "tcp"
  scope_id     = boundary_scope.project.id
  default_port = 3306

  host_source_ids = [boundary_host_set_static.mysql.id]

  # Brokers les credentials : Boundary les fournit au client à la connexion
  brokered_credential_source_ids = [
    boundary_credential_username_password.mysql.id
  ]

  # Force l'utilisation du worker self-managed dans Minikube
  egress_worker_filter = "\"k8s\" in \"/tags/type\""
}
