# -------------------------------------------------------
# Auth Method (password)
# -------------------------------------------------------
resource "boundary_auth_method" "password" {
  name        = "password-auth"
  description = "Authentification par mot de passe"
  type        = "password"
  scope_id    = boundary_scope.org.id
}

# -------------------------------------------------------
# User de démo
# -------------------------------------------------------
resource "boundary_account_password" "demo_user" {
  name           = "demo-user"
  description    = "Compte de démonstration pour l'article"
  login_name     = "demo"
  password       = "DemoPassword123!"
  auth_method_id = boundary_auth_method.password.id
}

resource "boundary_user" "demo_user" {
  name        = "demo-user"
  description = "Utilisateur de démonstration"
  scope_id    = boundary_scope.org.id
  account_ids = [boundary_account_password.demo_user.id]
}

# -------------------------------------------------------
# Rôle : voir les targets mais pas s'y connecter
# -------------------------------------------------------
resource "boundary_role" "k8s_access" {
  name        = "k8s-read-only"
  description = "Peut lister et voir les targets mais pas s'y connecter"
  scope_id    = boundary_scope.project.id

  principal_ids = [boundary_user.demo_user.id]

  grant_strings = [
    "ids=*;type=target;actions=list,read",
    "ids=*;type=session;actions=list,read:self",
  ]
}
