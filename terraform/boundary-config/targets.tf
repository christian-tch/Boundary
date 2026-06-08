# ── Host Catalog ──────────────────────────────────────────────────────
resource "boundary_host_catalog_static" "minikube" {
  name        = "minikube-catalog"
  description = "Hosts dans le cluster Minikube"
  scope_id    = boundary_scope.project.id
}

# ── SSH host ──────────────────────────────────────────────────────────
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

# ── MySQL host ────────────────────────────────────────────────────────
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

# ── Vault credential store ────────────────────────────────────────────
# The worker_filter routes all Vault API calls through the in-cluster worker,
# so the address uses cluster-internal DNS (HCP controller never reaches Vault directly).
resource "boundary_credential_store_vault" "main" {
  name        = "vault"
  description = "Vault dynamic credentials"
  scope_id    = boundary_scope.project.id

  address       = "http://vault.boundary.svc.cluster.local:8200"
  token         = vault_token.boundary.client_token
  worker_filter = "\"k8s\" in \"/tags/type\""
}

# ── SSH credential library (Vault-signed certificate) ─────────────────
resource "boundary_credential_library_vault_ssh_certificate" "ssh" {
  name                = "ssh-signed-cert"
  description         = "Vault-signed SSH certificate for boundary-user"
  credential_store_id = boundary_credential_store_vault.main.id
  path                = "ssh/sign/boundary-ssh"
  username            = "boundary-user"
  ttl                 = "5m"
}

# ── MySQL credential library (dynamic user) ───────────────────────────
resource "boundary_credential_library_vault" "mysql" {
  name                = "mysql-dynamic"
  description         = "Vault dynamic MySQL credentials"
  credential_store_id = boundary_credential_store_vault.main.id
  path                = "database/creds/boundary-mysql"
  http_method         = "GET"
  credential_type     = "username_password"
}

# ── SSH target ────────────────────────────────────────────────────────
resource "boundary_target" "ssh" {
  name         = "ssh-minikube"
  description  = "Accès SSH au pod dans Minikube"
  type         = "ssh"
  scope_id     = boundary_scope.project.id
  default_port = 2222

  host_source_ids = [boundary_host_set_static.ssh.id]

  injected_application_credential_source_ids = [
    boundary_credential_library_vault_ssh_certificate.ssh.id
  ]

  egress_worker_filter = "\"k8s\" in \"/tags/type\""
}

# ── MySQL target ──────────────────────────────────────────────────────
resource "boundary_target" "mysql" {
  name         = "mysql-minikube"
  description  = "Accès MySQL dans Minikube"
  type         = "tcp"
  scope_id     = boundary_scope.project.id
  default_port = 3306

  host_source_ids = [boundary_host_set_static.mysql.id]

  brokered_credential_source_ids = [
    boundary_credential_library_vault.mysql.id
  ]

  egress_worker_filter = "\"k8s\" in \"/tags/type\""
}
