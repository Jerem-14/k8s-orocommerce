# 🚀 Guide d'Installation OroCommerce Kubernetes

## 🎯 Vue d'ensemble

Ce guide détaille l'installation complète d'OroCommerce sur Kubernetes en utilisant Helm Charts. Il couvre toutes les étapes depuis la préparation de l'environnement jusqu'au déploiement en production avec monitoring.

## ✅ Prérequis

### 🖥️ Infrastructure requise

| Composant | Version minimale | Recommandé |
|-----------|------------------|------------|
| **Kubernetes** | 1.25+ | 1.28+ |
| **Helm** | 3.8+ | 3.12+ |
| **kubectl** | Compatible avec cluster | Dernière version |

### 🔧 Outils nécessaires

```bash
# Vérifier les versions
kubectl version --client
helm version
git --version

# Vérifier l'accès au cluster
kubectl cluster-info
kubectl get nodes
```

### 💾 Ressources minimales du cluster

| Ressource | Minimum | Recommandé |
|-----------|---------|------------|
| **CPU** | 4 cores | 8+ cores |
| **RAM** | 8 GB | 16+ GB |
| **Stockage** | 100 GB | 200+ GB |
| **Nœuds** | 1 | 3+ (HA) |

## 📦 Étape 1 : Préparation de l'environnement

### 1.1 Clonage du projet

```bash
# Cloner le repository
git clone <votre-repository-url>
cd orocommerce-k8s

# Vérifier la structure
ls -la charts/
```

### 1.2 Configuration du namespace

```bash
# Créer le namespace principal
kubectl create namespace orocommerce

# Vérifier la création
kubectl get namespaces | grep orocommerce
```

### 1.3 Préparation des secrets (Optionnel)

```bash
# Créer les secrets pour la base de données
kubectl create secret generic postgres-secret \
  --from-literal=postgres-password=VotreMotDePasse \
  --namespace=orocommerce

# Vérifier les secrets
kubectl get secrets -n orocommerce
```

## ⚙️ Étape 2 : Configuration

### 2.1 Personnalisation des values

Créer un fichier `values-production.yaml` :

```yaml
# values-production.yaml

# Configuration de l'application
global:
  environment: "prod"
  domain: "votre-domaine.com"

# Configuration des ressources
resources:
  php-fpm:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "2000m" 
      memory: "2Gi"

# Configuration du stockage
storage:
  storageClass: "gp2"  # AWS EBS par exemple
  oroApp:
    size: "20Gi"
  publicStorage:
    size: "50Gi"

# Configuration de l'autoscaling
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

# Configuration du monitoring
monitoring:
  enabled: true
  
# Configuration de l'ingress
ingress:
  enabled: true
  hosts:
    - host: orocommerce.votre-domaine.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: orocommerce-tls
      hosts:
        - orocommerce.votre-domaine.com
```

### 2.2 Configuration des variables d'environnement

Modifier `charts/orocommerce/values.yaml` selon vos besoins :

```yaml
# Variables d'application
app:
  url: "https://orocommerce.votre-domaine.com"
  env: "prod"
  
# Variables de base de données
database:
  host: "database-orocommerce"
  port: "5432"
  name: "orocommerce"
  user: "orocommerce"
  
# Variables WebSocket
websocket:
  host: "websocket-orocommerce"
  port: "8080"
```

## 🚀 Étape 3 : Installation de base

### 3.1 Mise à jour des dépendances Helm

```bash
# Mettre à jour les dépendances des charts
helm dependency update charts/orocommerce/
helm dependency update charts/monitoring/

# Vérifier les dépendances
ls charts/orocommerce/charts/
```

### 3.2 Installation sèche (dry-run)

```bash
# Test d'installation sans déploiement réel
helm install orocommerce charts/orocommerce \
  --namespace orocommerce \
  --dry-run \
  --debug \
  -f values-production.yaml
```

### 3.3 Installation réelle

```bash
# Installation complète
helm install orocommerce charts/orocommerce \
  --namespace orocommerce \
  --create-namespace \
  -f values-production.yaml \
  --timeout 20m

# Suivre le déploiement
kubectl get pods -n orocommerce -w
```

## 🔍 Étape 4 : Vérification du déploiement

### 4.1 Statut des pods

```bash
# Vérifier tous les pods
kubectl get pods -n orocommerce

# Statut détaillé
kubectl get all -n orocommerce
```

Attendez que tous les pods soient en état `Running` :

```
NAME                                     READY   STATUS    RESTARTS
web-orocommerce-xxx                      1/1     Running   0
php-fpm-orocommerce-xxx                  1/1     Running   0
consumer-orocommerce-xxx                 1/1     Running   0
websocket-orocommerce-xxx                1/1     Running   0
cron-orocommerce-xxx                     1/1     Running   0
database-orocommerce-0                   1/1     Running   0
```

### 4.2 Vérification des services

```bash
# Lister les services
kubectl get svc -n orocommerce

# Tester la connectivité interne
kubectl run test-pod --image=busybox -it --rm --restart=Never -- \
  wget -qO- http://web-orocommerce:80
```

### 4.3 Vérification des volumes

```bash
# Vérifier les PVCs
kubectl get pvc -n orocommerce

# Vérifier l'utilisation des volumes
kubectl exec -n orocommerce deployment/php-fpm-orocommerce -- \
  df -h /var/www/oro
```

### 4.4 Logs d'initialisation

```bash
# Vérifier les logs des jobs d'initialisation
kubectl logs -n orocommerce job/oro-volume-init
kubectl logs -n orocommerce job/oro-install

# Logs de l'application
kubectl logs -n orocommerce deployment/php-fpm-orocommerce
```

## 🌐 Étape 5 : Configuration de l'accès externe

### 5.1 Installation de l'Ingress Controller (si nécessaire)

```bash
# Nginx Ingress Controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace
```

### 5.2 Configuration SSL/TLS (Optionnel)

```bash
# Cert-manager pour les certificats automatiques
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true
```

Créer un issuer pour Let's Encrypt :

```yaml
# cert-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: votre-email@domaine.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

```bash
kubectl apply -f cert-issuer.yaml
```

### 5.3 Test d'accès

```bash
# Port-forward pour test local
kubectl port-forward -n orocommerce service/web-orocommerce 8080:80

# Tester dans le navigateur : http://localhost:8080
```

## 📊 Étape 6 : Installation du monitoring

### 6.1 Déploiement Prometheus & Grafana

```bash
# Installer le monitoring
helm install monitoring charts/monitoring \
  --namespace orocommerce \
  -f monitoring-values.yaml
```

### 6.2 Configuration monitoring

Créer `monitoring-values.yaml` :

```yaml
# Configuration Grafana
grafana:
  adminPassword: "admin123"
  ingress:
    enabled: true
    hosts:
      - grafana.votre-domaine.com

# Configuration Prometheus
prometheus:
  retention: "30d"
  storageSpec:
    volumeClaimTemplate:
      spec:
        storageClassName: "gp2"
        resources:
          requests:
            storage: 50Gi

# Alertes par email
alertmanager:
  config:
    global:
      smtp_smarthost: 'smtp.company.com:587'
      smtp_from: 'alerts@company.com'
    route:
      group_by: ['alertname']
      receiver: 'web.hook'
    receivers:
    - name: 'web.hook'
      email_configs:
      - to: admin@company.com
        subject: '🚨 Alerte OroCommerce'
```

### 6.3 Accès aux dashboards

```bash
# Port-forward Grafana
kubectl port-forward -n orocommerce service/monitoring-grafana 3000:80

# Accès : http://localhost:3000
# Username: admin
# Password: admin123
```

## ⚡ Étape 7 : Configuration de l'autoscaling

### 7.1 Installation du Metrics Server (si nécessaire)

```bash
# Vérifier si le metrics server est installé
kubectl get deployment metrics-server -n kube-system

# Si absent, installer
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### 7.2 Activation de l'HPA

```bash
# Vérifier l'HPA
kubectl get hpa -n orocommerce

# Tester l'autoscaling avec charge
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- \
  /bin/sh -c "while sleep 0.01; do wget -q -O- http://web-orocommerce.orocommerce/; done"
```

## 🔄 Étape 8 : Migration et données

### 8.1 Import de données existantes (Optionnel)

```bash
# Copier un dump SQL dans le pod
kubectl cp dump.sql orocommerce/database-orocommerce-0:/tmp/

# Importer les données
kubectl exec -it -n orocommerce database-orocommerce-0 -- \
  psql -U orocommerce -d orocommerce -f /tmp/dump.sql
```

### 8.2 Configuration des tâches CRON

Vérifier que les tâches CRON sont actives :

```bash
# Vérifier les logs du pod cron
kubectl logs -n orocommerce deployment/cron-orocommerce -f

# Exécuter manuellement une tâche
kubectl exec -n orocommerce deployment/cron-orocommerce -- \
  php bin/console oro:cron:run
```

## 🧪 Étape 9 : Tests de validation

### 9.1 Tests de connectivité

```bash
# Script de test complet
cat << 'EOF' > test-deployment.sh
#!/bin/bash

echo "🔍 Test de déploiement OroCommerce"
echo "=================================="

# Test des pods
echo "📦 Vérification des pods..."
kubectl get pods -n orocommerce --no-headers | while read line; do
  status=$(echo $line | awk '{print $3}')
  name=$(echo $line | awk '{print $1}')
  if [ "$status" != "Running" ]; then
    echo "❌ $name: $status"
  else
    echo "✅ $name: $status"
  fi
done

# Test des services
echo ""
echo "🌐 Test des services..."
for service in web php-fpm database redis websocket; do
  if kubectl get svc ${service}-orocommerce -n orocommerce >/dev/null 2>&1; then
    echo "✅ Service $service: OK"
  else
    echo "❌ Service $service: ERREUR"
  fi
done

# Test de l'application
echo ""
echo "🔗 Test de l'application..."
if kubectl run test-app --image=curlimages/curl --rm -i --restart=Never -- \
   curl -s -o /dev/null -w "%{http_code}" http://web-orocommerce.orocommerce:80 | grep -q "200\|301\|302"; then
  echo "✅ Application accessible"
else
  echo "❌ Application inaccessible"
fi

echo ""
echo "✅ Tests terminés!"
EOF

chmod +x test-deployment.sh
./test-deployment.sh
```

### 9.2 Test de performance (Optionnel)

```bash
# Test de charge avec Apache Bench
kubectl run perf-test --image=httpd:alpine --rm -it --restart=Never -- \
  ab -n 100 -c 10 http://web-orocommerce.orocommerce/
```

## 🔧 Étape 10 : Maintenance et mise à jour

### 10.1 Mise à jour de l'application

```bash
# Mettre à jour avec de nouvelles values
helm upgrade orocommerce charts/orocommerce \
  --namespace orocommerce \
  -f values-production.yaml \
  --set image.tag=6.1.1

# Suivre le rollout
kubectl rollout status deployment/php-fpm-orocommerce -n orocommerce
```

### 10.2 Sauvegarde

```bash
# Sauvegarde de la base de données
kubectl exec -n orocommerce database-orocommerce-0 -- \
  pg_dump -U orocommerce orocommerce > backup-$(date +%Y%m%d).sql

# Sauvegarde des volumes (dépend du CSI driver)
kubectl get pvc -n orocommerce -o yaml > pvc-backup.yaml
```

### 10.3 Rollback en cas de problème

```bash
# Voir l'historique des releases
helm history orocommerce -n orocommerce

# Rollback vers la version précédente
helm rollback orocommerce 1 -n orocommerce
```

## 🚨 Dépannage

### Problèmes courants

#### 1. Pods en état Pending

```bash
# Vérifier les événements
kubectl describe pod <pod-name> -n orocommerce

# Solutions possibles :
# - Ressources insuffisantes
# - PVC non créés
# - Node selector incorrect
```

#### 2. Init jobs en erreur

```bash
# Vérifier les logs
kubectl logs job/oro-volume-init -n orocommerce
kubectl logs job/oro-install -n orocommerce

# Supprimer et recréer les jobs
kubectl delete job oro-install -n orocommerce
helm upgrade orocommerce charts/orocommerce -n orocommerce --reuse-values
```

#### 3. Application inaccessible

```bash
# Vérifier l'ingress
kubectl get ingress -n orocommerce
kubectl describe ingress orocommerce-ingress -n orocommerce

# Vérifier la résolution DNS
nslookup orocommerce.votre-domaine.com
```

#### 4. Performance dégradée

```bash
# Vérifier les métriques
kubectl top pods -n orocommerce
kubectl top nodes

# Ajuster les ressources si nécessaire
helm upgrade orocommerce charts/orocommerce \
  --set resources.php-fpm.limits.memory=4Gi \
  -n orocommerce
```

## 📋 Checklist de validation

- [ ] ✅ Tous les pods sont `Running`
- [ ] ✅ Tous les services sont accessibles
- [ ] ✅ L'application répond sur l'URL configurée
- [ ] ✅ La base de données est initialisée
- [ ] ✅ Les volumes persistants sont montés
- [ ] ✅ Le monitoring fonctionne
- [ ] ✅ L'autoscaling est configuré
- [ ] ✅ Les logs sont visibles
- [ ] ✅ Les certificats SSL sont valides (si configurés)
- [ ] ✅ Les sauvegardes sont planifiées

## 🎓 Critères projet validés

Cette installation répond aux exigences :

### ✅ Critère 1 : Exploiter et surveiller l'activité
- **Monitoring en temps réel** avec Prometheus/Grafana
- **Dashboards spécialisés** pour chaque composant
- **Alertes configurées** pour les métriques critiques

### ✅ Critère 2 : Optimiser l'exploitation
- **Autoscaling HPA** pour adaptation automatique
- **Resource limits** pour l'écoconception
- **Load balancing** avec répartition de charge

## 📚 Ressources utiles

- [Documentation Kubernetes](https://kubernetes.io/docs/)
- [Documentation Helm](https://helm.sh/docs/)
- [OroCommerce Installation Guide](https://doc.oroinc.com/backend/setup/)
- [Prometheus Operator](https://prometheus-operator.dev/)

---

🎉 **Félicitations !** Votre application OroCommerce est maintenant déployée sur Kubernetes avec monitoring et autoscaling.
