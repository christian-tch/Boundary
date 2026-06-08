# ── MySQL — Database secrets engine ──────────────────────────────────
resource "vault_mount" "db" {
  path = "database"
  type = "database"
}

resource "vault_database_secret_backend_connection" "mysql" {
  backend           = vault_mount.db.path
  name              = "mysql-minikube"
  allowed_roles     = ["boundary-mysql"]
  verify_connection = false

  mysql {
    # Vault connects to MySQL internally (in-cluster DNS)
    connection_url = "root:${var.mysql_root_password}@tcp(${var.mysql_target_address}:3306)/"
  }
}

resource "vault_database_secret_backend_role" "mysql" {
  backend = vault_mount.db.path
  name    = "boundary-mysql"
  db_name = vault_database_secret_backend_connection.mysql.name

  creation_statements = [
    "CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';",
    "GRANT ALL PRIVILEGES ON demo.* TO '{{name}}'@'%';",
  ]
  revocation_statements = ["DROP USER IF EXISTS '{{name}}'@'%';"]

  default_ttl = 3600
  max_ttl     = 7200
}

# ── SSH — Signed certificates engine ─────────────────────────────────
resource "vault_mount" "ssh" {
  path = "ssh"
  type = "ssh"
}

resource "vault_ssh_secret_backend_ca" "boundary" {
  backend              = vault_mount.ssh.path
  generate_signing_key = true
}

resource "vault_ssh_secret_backend_role" "boundary" {
  backend                 = vault_mount.ssh.path
  name                    = "boundary-ssh"
  key_type                = "ca"
  allow_user_certificates = true
  allowed_users           = "boundary-user"
  default_user            = "boundary-user"
  ttl                     = "5m"
}

# ── Policy: minimum permissions Boundary needs ───────────────────────
resource "vault_policy" "boundary" {
  name = "boundary-controller"

  policy = <<-EOT
    path "database/creds/boundary-mysql" {
      capabilities = ["read"]
    }
    path "ssh/sign/boundary-ssh" {
      capabilities = ["create", "update"]
    }
    path "sys/leases/renew" {
      capabilities = ["create", "update"]
    }
    path "sys/leases/revoke" {
      capabilities = ["update"]
    }
    path "auth/token/lookup-self" {
      capabilities = ["read"]
    }
    path "auth/token/renew-self" {
      capabilities = ["update"]
    }
    path "auth/token/revoke-self" {
      capabilities = ["update"]
    }
  EOT
}

# Orphan token stored in Boundary (long TTL, renewable)
resource "vault_token" "boundary" {
  policies  = [vault_policy.boundary.name]
  renewable = true
  period    = "768h"
  no_parent = true
}
