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
