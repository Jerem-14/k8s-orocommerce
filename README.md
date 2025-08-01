# 🚀 OroCommerce Kubernetes - Guide Complet

**Projet EII 5 - Migration OroCommerce vers Kubernetes**  
**Bloc RNCP** : EII 5 - Clusterisation de conteneurs

## 📋 Table des matières

- [🎯 Vue d'ensemble](#-vue-densemble)
- [✅ Prérequis](#-prérequis)
- [⚙️ Installation rapide](#️-installation-rapide)
- [🚀 Accès aux interfaces](#-accès-aux-interfaces)
- [🔧 Configuration avancée](#-configuration-avancée)
- [📊 Monitoring](#-monitoring)
- [🛠️ Dépannage](#️-dépannage)
- [📚 Documentation complète](#-documentation-complète)

## 🎯 Vue d'ensemble

Ce projet migre l'application **OroCommerce Demo** depuis Docker Compose vers Kubernetes en utilisant Helm Charts. L'objectif est de créer une infrastructure scalable et observable avec monitoring complet.

### Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Ingress       │    │   Load Balancer │    │   Monitoring    │
│   Controller    │    │   (HPA)         │    │   (Grafana)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Nginx         │    │   PHP-FPM       │    │   Prometheus    │
│   (Frontend)    │    │   (Backend)     │    │   (Metrics)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 ▼
                    ┌─────────────────┐
                    │   PostgreSQL    │
                    │   (Database)    │
                    └─────────────────┘
```

## ✅ Prérequis

### 🖥️ Infrastructure requise

| Composant | Version minimale | Recommandé |
|-----------|------------------|------------|
| **Kubernetes** | 1.25+ | 1.28+ |
| **Helm** | 3.8+ | 3.12+ |
| **kubectl** | Compatible avec cluster | Dernière version |

### 💾 Ressources minimales du cluster

| Ressource | Minimum | Recommandé |
|-----------|---------|------------|
| **CPU** | 4 cores | 8+ cores |
| **RAM** | 8 GB | 16+ GB |
| **Stockage** | 100 GB | 200+ GB |
| **Nœuds** | 1 | 3+ (HA) |

### 🔧 Vérification de l'environnement

```bash
# Vérifier les versions
kubectl version --client
helm version
git --version

# Vérifier l'accès au cluster
kubectl cluster-info
kubectl get nodes
```

## ⚙️ Installation rapide

### 1. Clonage du projet

```bash
git clone <votre-repository-url>
cd orocommerce-k8s
```

### 2. Vérification du namespace

```bash
# Nous utilisons le namespace default
kubectl get namespace default
```

### 3. Installation avec Helm

```bash
# Installation avec les valeurs par défaut
helm install orocommerce ./charts/orocommerce -n default

# Ou avec un fichier de valeurs personnalisé
helm install orocommerce ./charts/orocommerce -f values-production.yaml -n default
```

### 4. Vérification du déploiement

```bash
# Vérifier les pods
kubectl get pods -n default

# Vérifier les services
kubectl get services -n default

# Vérifier les persistent volumes
kubectl get pvc -n default
```

## 🚀 Accès aux interfaces

Une fois le déploiement terminé, accédez aux interfaces :

### 📊 Grafana (Monitoring & Dashboards)

```bash
kubectl port-forward service/monitoring-grafana 3000:80 -n default
```

- **URL** : http://localhost:3000
- **Username** : `admin`
- **Password** : `admin123`

**Dashboards OroCommerce disponibles :**
- 🎯 **OroCommerce - Vue d'ensemble**
- 🐘 **OroCommerce - PHP-FPM Détaillé**  
- 🗄️ **OroCommerce - Base de Données**

### 🔍 Prometheus (Métriques brutes)

```bash
kubectl port-forward service/prometheus-prometheus 9090:9090 -n default
```

- **URL** : http://localhost:9090
- Aller dans **Status → Targets** pour vérifier la collecte des métriques

### 🎯 Application OroCommerce

```bash
kubectl port-forward service/webserver-orocommerce 8080:80 -n default
```

- **URL** : http://localhost:8080
- Interface e-commerce complète

## 🔧 Configuration avancée

### Personnalisation des valeurs

Créer un fichier `values-production.yaml` :

```yaml
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
  cache:
    size: "10Gi"
  publicStorage:
    size: "50Gi"
```

### Configuration des secrets

```bash
# Créer les secrets pour la base de données
kubectl create secret generic postgres-secret \
  --from-literal=postgres-password=VotreMotDePasse \
  --namespace=default

# Créer les secrets pour l'application
kubectl create secret generic oro-secret \
  --from-literal=app-secret=VotreAppSecret \
  --namespace=default
```

## 📊 Monitoring

Le projet inclut un stack de monitoring complet avec Prometheus et Grafana.

### Installation du monitoring

```bash
# Installer le monitoring
helm install monitoring ./charts/monitoring -n default
```

### Configuration des alertes

```yaml
# Dans values-production.yaml
monitoring:
  enabled: true
  grafana:
    adminPassword: "admin123"
  prometheus:
    retention: "7d"
```

## 🛠️ Dépannage

### Commandes de diagnostic

```bash
# Vérifier le statut des pods
kubectl get pods -n default

# Vérifier les services
kubectl get svc -n default

# Vérifier les ServiceMonitors
kubectl get servicemonitor -n default

# Logs des applications
kubectl logs -l app.kubernetes.io/name=php-fpm -n default
kubectl logs -l app.kubernetes.io/name=webserver -n default
kubectl logs -l app.kubernetes.io/name=prometheus -n default
kubectl logs -l app.kubernetes.io/name=grafana -n default
```

### Problèmes courants

#### Si Grafana affiche "no data"
1. Vérifier que Prometheus fonctionne : `kubectl get pods -n default | grep prometheus`
2. Attendre 2-3 minutes pour la collecte des métriques
3. Changer la période dans Grafana : "Last 5 minutes"

#### Pods en erreur
```bash
# Décrire un pod pour voir les erreurs
kubectl describe pod <nom-du-pod> -n default

# Redémarrer les déploiements
kubectl rollout restart deployment/monitoring-grafana -n default
kubectl rollout restart deployment/php-fpm-orocommerce -n default
kubectl rollout restart deployment/webserver-orocommerce -n default
```

#### Problèmes de stockage
```bash
# Vérifier les persistent volumes
kubectl get pv
kubectl get pvc -n default

# Décrire un PVC
kubectl describe pvc <nom-du-pvc> -n default
```

#### Problèmes de réseau
```bash
# Vérifier les services
kubectl get services -n default

# Tester la connectivité
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup webserver-orocommerce

# Si les ports sont déjà utilisés, changer les ports de forwarding
kubectl port-forward service/monitoring-grafana 3001:80 -n default
kubectl port-forward service/prometheus-prometheus 9091:9090 -n default
```

## 📚 Documentation complète

- [Guide d'installation détaillé](docs/install-guide.md)
- [Architecture et composants](docs/architecture.md)
- [Configuration avancée](docs/configuration.md)
- [Monitoring et alertes](docs/monitoring.md)



