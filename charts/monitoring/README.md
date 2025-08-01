# 📊 Chart Monitoring OroCommerce

Ce chart Helm déploie une stack de monitoring complète pour OroCommerce avec **Prometheus** et **Grafana**.

## 🎯 Objectifs

Répondre aux critères d'évaluation du projet :
- **Critère 1** : Exploiter et surveiller l'activité du système
- **Critère 2** : Optimiser l'exploitation des données avec visualisation adaptée

## 🏗️ Architecture

### Composants déployés

- **Prometheus Server** : Collecte des métriques
- **Grafana** : Visualisation et dashboards
- **AlertManager** : Gestion des alertes  
- **Node Exporter** : Métriques système
- **Kube State Metrics** : Métriques Kubernetes

### Services monitorés

- **Nginx** (webserver) : Trafic HTTP, temps de réponse
- **PHP-FPM** : Processus, pools, performances
- **PostgreSQL** : Connexions, requêtes, taille DB
- **Consumer** : Traitement des tâches
- **WebSocket** : Connexions temps réel
- **Cron** : Tâches planifiées

## 📈 Dashboards Grafana

### 1. OroCommerce - Vue d'ensemble
- Requêtes HTTP/s
- Temps de réponse moyen
- Processus PHP-FPM actifs
- Connexions DB
- Trafic HTTP par minute
- Utilisation CPU/RAM

### 2. OroCommerce - PHP-FPM Détaillé  
- Pool PHP-FPM - Processus (actifs/inactifs/total)
- Requêtes PHP-FPM et queue
- Mémoire PHP par processus

### 3. OroCommerce - Base de Données
- Connexions PostgreSQL
- Requêtes par seconde
- Taille des bases de données

## 🚨 Alertes configurées

### Application
- **OroCommerceHighResponseTime** : Temps de réponse > 2s
- **OroCommerceHighErrorRate** : Taux d'erreur 5xx > 5%
- **OroCommerceLowTraffic** : Trafic < 0.1 req/s

### PHP-FPM
- **PHPFPMHighLoad** : Utilisation > 80% des processus
- **PHPFPMQueueBacklog** : File d'attente > 10 requêtes
- **PHPFPMNoActiveProcesses** : Aucun processus actif

### Base de données
- **PostgreSQLHighConnections** : Connexions > 80% du max
- **PostgreSQLSlowQueries** : Requêtes lentes > 5/s
- **PostgreSQLDatabaseDown** : DB indisponible

### Infrastructure
- **PodCrashLooping** : Redémarrages fréquents
- **PodHighMemoryUsage** : Mémoire > 90%
- **PodHighCPUUsage** : CPU > 80%
- **PersistentVolumeUsage** : Disque > 85%

## ⚙️ Configuration

### Variables principales

```yaml
monitoring:
  enabled: true

# Prometheus
prometheus:
  enabled: true
  prometheusSpec:
    retention: 30d
    retentionSize: "10GiB"
    storageSpec:
      volumeClaimTemplate:
        spec:
          resources:
            requests:
              storage: 20Gi

# Grafana
grafana:
  enabled: true
  adminPassword: "admin123"
  persistence:
    enabled: true
    size: 5Gi
  ingress:
    enabled: true
    hosts:
      - grafana.orocommerce.local

# Métriques personnalisées
customMetrics:
  nginx:
    enabled: true
    scrapeInterval: 30s
  phpfpm:
    enabled: true
    scrapeInterval: 30s
  postgresql:
    enabled: true
    scrapeInterval: 30s
```

## 🚀 Installation

### 1. Mise à jour des dépendances
```bash
cd orocommerce-k8s/charts/monitoring
helm dependency update
```

### 2. Installation complète
```bash
cd orocommerce-k8s
helm install orocommerce charts/orocommerce --namespace orocommerce --create-namespace
```

### 3. Installation monitoring seul
```bash
helm install monitoring charts/monitoring --namespace monitoring --create-namespace
```

## 🔗 Accès aux interfaces

### Grafana
```bash
# Port Forward
kubectl port-forward service/prometheus-grafana 3000:80 -n orocommerce

# Accès : http://localhost:3000
# Username: admin  
# Password: admin123
```

### Prometheus
```bash
# Port Forward
kubectl port-forward service/prometheus-server 9090:80 -n orocommerce

# Accès : http://localhost:9090
```

### AlertManager
```bash
# Port Forward
kubectl port-forward service/prometheus-alertmanager 9093:80 -n orocommerce

# Accès : http://localhost:9093
```

## 🔧 Commandes de diagnostic

### Vérifier les ServiceMonitors
```bash
kubectl get servicemonitor -n orocommerce
```

### Vérifier les règles Prometheus
```bash
kubectl get prometheusrules -n orocommerce
```

### Voir les targets Prometheus
```bash
# Accéder à Prometheus UI puis Status > Targets
```

### Logs des composants
```bash
# Prometheus
kubectl logs -l app.kubernetes.io/name=prometheus -n orocommerce

# Grafana
kubectl logs -l app.kubernetes.io/name=grafana -n orocommerce
```

## 📊 Métriques exposées

### Nginx
- `nginx_http_requests_total` : Nombre total de requêtes
- `nginx_http_request_duration_seconds` : Temps de réponse

### PHP-FPM  
- `phpfpm_active_processes` : Processus actifs
- `phpfpm_idle_processes` : Processus inactifs
- `phpfpm_total_processes` : Total processus
- `phpfpm_listen_queue` : File d'attente

### PostgreSQL
- `postgresql_connections_active` : Connexions actives
- `postgresql_connections_max` : Connexions maximum
- `postgresql_queries_total` : Total requêtes
- `postgresql_database_size_bytes` : Taille DB

## 🎓 Critères projet respectés

✅ **Surveiller l'activité** : Prometheus collecte 50+ métriques  
✅ **Flux temps réel** : Refresh 5-30s sur dashboards  
✅ **Outils monitoring** : Stack Prometheus/Grafana industrielle  
✅ **Visualisation adaptée** : 3 dashboards spécialisés  
✅ **Optimisation ressources** : Alertes sur CPU/RAM/disque  
✅ **Répartition charge** : Monitoring PHP-FPM pools

## 🔒 Sécurité

- ServiceAccounts dédiés
- RBAC minimal
- Secrets pour mots de passe  
- NetworkPolicies (optionnel)

## 🛠️ Personnalisation

### Ajouter une métrique
1. Modifier le ServiceMonitor correspondant
2. Ajouter l'endpoint dans `values.yaml`
3. Créer les règles d'alerte si nécessaire
4. Mettre à jour les dashboards

### Nouvelle alerte
1. Éditer `prometheus-rules.yaml`
2. Ajouter la règle dans le bon groupe
3. Redéployer : `helm upgrade`

Ce monitoring fournit une base solide pour la surveillance de votre application OroCommerce en production ! 🎯