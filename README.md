# HCP Boundary + Minikube — Lab

Lab de démonstration pour l'article : accès zero-trust à des ressources Kubernetes via HCP Boundary.

## Architecture

```
HCP Boundary (controller managé)
        │
        │ worker registration
        ▼
Minikube
├── boundary-worker   (pod — proxy les sessions)
├── ssh-target        (pod — OpenSSH, ClusterIP uniquement)
└── mysql             (pod — MySQL 8.0, ClusterIP uniquement)
```

## Prérequis

- [minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [boundary CLI](https://developer.hashicorp.com/boundary/install)
- Un cluster HCP Boundary actif (version Essentials)

## Déploiement

### 1. Démarrer Minikube

```bash
minikube start --cpus=4 --memory=4096 --driver=docker
```

### 2. Remplir les secrets

Édite les fichiers suivants et remplace les valeurs `REPLACE_WITH_*` :

```bash
k8s/ssh-target/deployment.yaml   # SSH user password
k8s/mysql/secret.yaml            # MySQL root + boundary passwords
k8s/worker/deployment.yaml       # HCP Boundary cluster ID + worker public addr
```

Pour l'adresse publique du worker, récupère l'IP Minikube :
```bash
minikube ip
# ex: 192.168.49.2 → public_addr = "192.168.49.2:30202"
```

### 3. Appliquer les manifests Kubernetes

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/worker/
kubectl apply -f k8s/ssh-target/
kubectl apply -f k8s/mysql/
```

Vérifie que les pods sont up :
```bash
kubectl get pods -n boundary
```

### 4. Enregistrer le worker dans HCP Boundary

Récupère le token d'activation généré par le worker :
```bash
kubectl logs -n boundary -l app=boundary-worker | grep "Worker Auth Registration Request"
```

Copie le token et enregistre le worker depuis l'UI HCP Boundary :
`Workers → New Worker → colle le token`

### 5. Configurer Boundary avec Terraform

```bash
cd terraform/boundary-config
cp terraform.tfvars.example terraform.tfvars
# Édite terraform.tfvars avec tes valeurs
terraform init
terraform apply
```

## Connexion aux cibles

### SSH

```bash
# Récupère l'ID de la cible SSH depuis les outputs Terraform
export SSH_TARGET_ID=$(terraform -chdir=terraform/boundary-config output -raw ssh_target_id)

boundary authenticate \
  -addr=<BOUNDARY_CLUSTER_URL> \
  -auth-method-id=<AUTH_METHOD_ID>

boundary connect ssh \
  -target-id=$SSH_TARGET_ID
```

### MySQL

```bash
export MYSQL_TARGET_ID=$(terraform -chdir=terraform/boundary-config output -raw mysql_target_id)

# Boundary ouvre un tunnel local et affiche les credentials brokered
boundary connect \
  -target-id=$MYSQL_TARGET_ID \
  -exec mysql -- \
    -u {{boundary.username}} \
    -p{{boundary.password}} \
    -h {{boundary.ip}} \
    -P {{boundary.port}} \
    demo
```

## Nettoyage

```bash
terraform -chdir=terraform/boundary-config destroy
kubectl delete namespace boundary
minikube stop
```
