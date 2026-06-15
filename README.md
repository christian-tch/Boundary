# HCP Boundary + Minikube — Lab

Lab de démonstration pour un accès zero-trust à des ressources Kubernetes via HCP Boundary.

## Architecture

Le lab a deux couches :

1. Couche Kubernetes (`k8s/`):
- `vault` (dev mode, NodePort `30200`)
- `boundary-worker` (self-managed, NodePort `30202`)
- `ssh-target` (ClusterIP uniquement)
- `mysql` (ClusterIP uniquement)

2. Couche Terraform (`terraform/boundary-config/`):
- Configure Vault (engine database + SSH)
- Crée un token Vault orphelin pour Boundary
- Crée un `boundary_credential_store_vault` et les credential libraries
- Route toutes les sessions via le worker K8s avec `egress_worker_filter` et `worker_filter`

## Prérequis

- [minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [boundary CLI](https://developer.hashicorp.com/boundary/install)
- Un cluster HCP Boundary actif (Essentials)

## Valeurs à renseigner avant déploiement

Mets à jour les placeholders dans :

- `k8s/vault/secret.yaml`: `root-token`
- `k8s/mysql/secret.yaml`: `root-password` (doit correspondre à `mysql_root_password` dans `terraform.tfvars`)
- `k8s/ssh-target/deployment.yaml`: secret `user-password`
- `k8s/worker/deployment.yaml`: `public_addr` et `initial_upstreams`
- `terraform/boundary-config/terraform.tfvars`: au minimum `boundary_admin_password`, `vault_addr`, `mysql_root_password`

Exemple de valeur pour `public_addr` : `$(minikube ip):30202`.
Exemple de valeur pour `vault_addr` : `http://$(minikube ip):30200`.

## Déploiement

### 1. Démarrer Minikube

```bash
minikube start --cpus=4 --memory=4096 --driver=docker
```

### 2. Construire l'image worker dans le Docker de Minikube

```bash
eval $(minikube docker-env)
docker build -t boundary-worker-enterprise:0.21.3 k8s/worker/
```

### 3. Appliquer les manifests Kubernetes (Vault d'abord)

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/vault/
kubectl apply -f k8s/worker/
kubectl apply -f k8s/ssh-target/
kubectl apply -f k8s/mysql/
```

Vérifier que Vault est prêt (Terraform en dépend) :

```bash
kubectl wait --for=condition=ready pod -l app=vault -n boundary --timeout=60s
```

### 4. Enregistrer le worker dans HCP Boundary

Récupérer la demande d'enregistrement depuis les logs :

```bash
kubectl logs -n boundary -l app=boundary-worker | grep "Worker Auth Registration Request"
```

Puis dans l'UI HCP Boundary : `Workers -> New Worker`.

### 5. Configurer Vault + Boundary via Terraform

```bash
cd terraform/boundary-config
cp terraform.tfvars.example terraform.tfvars
# Édite terraform.tfvars
terraform init
terraform apply
```

### 6. Injecter la CA SSH de Vault dans le pod SSH

Après `terraform apply`, la clé publique de la CA est disponible en output :

```bash
kubectl create configmap ssh-vault-ca -n boundary \
  --from-literal=trusted-user-ca-keys.pem="$(terraform output -raw vault_ssh_ca_public_key)" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl rollout restart deployment/ssh-target -n boundary
```

Alternative : remplir `k8s/ssh-target/vault-ca-configmap.yaml` puis l'appliquer.

## Connexion aux cibles

### SSH (certificat signé par Vault injecté automatiquement)

```bash
export SSH_TARGET_ID=$(terraform -chdir=terraform/boundary-config output -raw ssh_target_id)
boundary connect ssh -target-id=$SSH_TARGET_ID
```

### MySQL (credentials dynamiques Vault)

```bash
export MYSQL_TARGET_ID=$(terraform -chdir=terraform/boundary-config output -raw mysql_target_id)
boundary connect -target-id=$MYSQL_TARGET_ID -exec mysql -- \
  -u {{boundary.username}} -p{{boundary.password}} \
  -h {{boundary.ip}} -P {{boundary.port}} demo
```

## Notes importantes

- Vault tourne en dev mode : un restart du pod efface l'état. Refaire `terraform apply` si Vault redémarre.
- La cible SSH écoute sur le port `2222` (pas `22`).
- `worker_filter` dans `boundary_credential_store_vault` permet au worker en cluster de proxy les appels Vault.

## Nettoyage

```bash
terraform -chdir=terraform/boundary-config destroy
kubectl delete namespace boundary
minikube stop
```
