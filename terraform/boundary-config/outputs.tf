output "org_id" {
  description = "ID de l'organisation Boundary"
  value       = boundary_scope.org.id
}

output "project_id" {
  description = "ID du projet Boundary"
  value       = boundary_scope.project.id
}

output "ssh_target_id" {
  description = "ID de la cible SSH"
  value       = boundary_target.ssh.id
}

output "mysql_target_id" {
  description = "ID de la cible MySQL"
  value       = boundary_target.mysql.id
}

output "vault_ssh_ca_public_key" {
  description = "Vault SSH CA public key — paste into k8s/ssh-target/vault-ca-configmap.yaml"
  value       = vault_ssh_secret_backend_ca.boundary.public_key
}
