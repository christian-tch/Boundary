resource "boundary_scope" "org" {
  name                     = "demo-org"
  description              = "Organisation de démonstration pour l'article"
  scope_id                 = "global"
  auto_create_admin_role   = true
  auto_create_default_role = true
}

resource "boundary_scope" "project" {
  name                   = "k8s-minikube"
  description            = "Projet pour les ressources Minikube"
  scope_id               = boundary_scope.org.id
  auto_create_admin_role = true
}
