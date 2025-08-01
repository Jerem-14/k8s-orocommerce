# 🏗️ Architecture Kubernetes OroCommerce

## 🎯 Vue d'ensemble

Cette documentation présente l'architecture complète de la migration d'OroCommerce depuis Docker Compose vers Kubernetes. L'architecture est conçue pour être scalable, résiliente et facile à maintenir grâce à l'utilisation de Helm Charts.

## 📊 Architecture Globale

```mermaid
graph TB
    subgraph "External Access"
        user[👤 User]
        admin[👤 Admin]
    end
    
    subgraph "Kubernetes Cluster (namespace: default)"
        subgraph "OroCommerce Application"
            subgraph "Frontend Layer"
                nginx[webserver<br/>Nginx Deployment<br/>✅ Running]
            end
            
            subgraph "Application Layer"
                phpfpm[orocommerce-app-php-fpm<br/>PHP-FPM Deployment<br/>✅ Running]
                websocket[orocommerce-websocket<br/>WebSocket Deployment<br/>✅ Running]
            end
            
            subgraph "Database Layer"
                postgres[database-orocommerce<br/>PostgreSQL Deployment<br/>✅ Running]
            end
            
            subgraph "Storage Layer"
                pvc1[pvc-oro-app<br/>10Gi]
                pvc2[pvc-cache<br/>5Gi]
                pvc3[pvc-public-storage<br/>20Gi]
                pvc4[pvc-private-storage<br/>10Gi]
                pvc5[pvc-maintenance<br/>1Gi]
                pvc6[pvc-postgres-data<br/>Auto-created]
            end
            
            subgraph "Initialization"
                initjobs[init-jobs<br/>volume-init ✅ Complete<br/>oro-restore ⏳ Running]
            end
        end
        
        subgraph "Monitoring Stack"
            prometheus[prometheus-prometheus<br/>Prometheus Deployment<br/>✅ Running]
            grafana[monitoring-grafana<br/>Grafana Deployment<br/>✅ Running]
            alertmanager[alertmanager-prometheus<br/>AlertManager StatefulSet<br/>✅ Running]
        end
    end
    
    subgraph "Port Forwards"
        pf1[localhost:8080 → webserver:80]
        pf2[localhost:3000 → grafana:80]
        pf3[localhost:9090 → prometheus:9090]
        pf4[localhost:5432 → postgres:5432]
    end
    
    user --> pf1
    admin --> pf2
    admin --> pf3
    admin --> pf4
    
    pf1 --> nginx
    pf2 --> grafana
    pf3 --> prometheus
    pf4 --> postgres
    
    nginx --> phpfpm
    nginx --> websocket
    phpfpm --> postgres
    websocket --> phpfpm
    
    phpfpm --> pvc1
    phpfpm --> pvc2
    phpfpm --> pvc3
    phpfpm --> pvc4
    nginx --> pvc1
    postgres --> pvc6
    
    initjobs --> pvc1
    initjobs --> pvc2
    initjobs --> pvc3
    initjobs --> pvc4
    initjobs --> pvc5
    
    prometheus --> phpfpm
    prometheus --> nginx
    prometheus --> postgres
    grafana --> prometheus
```

## 🎛️ Architecture Détaillée des Services

### Frontend Layer

```mermaid
graph LR
    subgraph "Nginx Webserver"
        nginx_pod[Nginx Pod<br/>- Static files serving<br/>- Reverse proxy<br/>- SSL termination]
        nginx_svc[Service ClusterIP]
        nginx_config[Nginx ConfigMap]
    end
    
    subgraph "Storage"
        public_pvc[Public Storage PVC<br/>Static assets]
        private_pvc[Private Storage PVC<br/>Protected files]
    end
    
    nginx_pod --> public_pvc
    nginx_pod --> private_pvc
    nginx_config -.-> nginx_pod
    nginx_svc --> nginx_pod
```

### Application Layer

```mermaid
graph TB
    subgraph "PHP-FPM (Main Application)"
        phpfpm_deploy[Deployment<br/>- Replicas: 2+<br/>- HPA enabled<br/>- Resource limits]
        phpfpm_hpa[HorizontalPodAutoscaler<br/>CPU: 70%<br/>Memory: 80%]
        phpfpm_svc[Service ClusterIP]
    end
    
    subgraph "Background Services"
        consumer_deploy[Consumer Deployment<br/>- Message processing<br/>- Queue handling]
        websocket_deploy[WebSocket Deployment<br/>- Real-time features<br/>- Persistent connections]
        cron_deploy[Cron Deployment<br/>- Scheduled tasks<br/>- Maintenance jobs]
    end
    
    subgraph "Shared Storage"
        app_pvc[oro-app PVC<br/>Application files]
        cache_pvc[Cache PVC<br/>Temp files]
    end
    
    phpfpm_hpa -.-> phpfpm_deploy
    phpfpm_deploy --> app_pvc
    phpfpm_deploy --> cache_pvc
    consumer_deploy --> app_pvc
    websocket_deploy --> app_pvc
    cron_deploy --> app_pvc
    
    phpfpm_svc --> phpfpm_deploy
```

### Database Layer

```mermaid
graph TB
    subgraph "Database Services"
        postgres_sts[PostgreSQL StatefulSet<br/>- Primary database<br/>- Persistent storage<br/>- Service headless]
        redis_sts[Redis StatefulSet<br/>- Session storage<br/>- Cache layer<br/>- Message broker]
        elastic_sts[Elasticsearch StatefulSet<br/>- Search engine<br/>- Document indexing<br/>- Analytics]
    end
    
    subgraph "Database Storage"
        pg_pvc[PostgreSQL PVC<br/>Database files]
        redis_pvc[Redis PVC<br/>Memory dumps]
        elastic_pvc[Elasticsearch PVC<br/>Indices & logs]
    end
    
    postgres_sts --> pg_pvc
    redis_sts --> redis_pvc
    elastic_sts --> elastic_pvc
```

## 🔧 Helm Charts Structure - Déploiement Individuel

**Approche utilisée** : Installation directe des charts individuels (pas d'umbrella chart)

```mermaid
graph TD
    subgraph "Charts Déployés Individuellement"
        subgraph "Infrastructure"
            pvc_k8s[k8s/pvc.yaml<br/>📦 PVCs principaux<br/>kubectl apply]
        end
        
        subgraph "Database Layer"
            db_chart[charts/db/<br/>🗄️ database<br/>helm install database]
        end
        
        subgraph "Initialization"
            init_chart[charts/init-jobs/<br/>⚙️ init-jobs<br/>helm install init-jobs]
        end
        
        subgraph "Application Layer"
            phpfpm_chart[charts/php-fpm/<br/>🐘 orocommerce-app<br/>helm install orocommerce-app]
            ws_chart[charts/ws/<br/>🔌 orocommerce-websocket<br/>helm install orocommerce-websocket]
        end
        
        subgraph "Frontend Layer"
            web_chart[charts/web/<br/>🌐 webserver<br/>helm install webserver]
        end
        
        subgraph "Monitoring Stack"
            monitoring_chart[charts/monitoring/<br/>📊 monitoring<br/>helm install monitoring]
        end
        
        subgraph "Manual Services"
            websocket_alias[websocket-alias.yaml<br/>🔗 orocommerce-websocket<br/>kubectl apply]
            manual_pvcs[Additional PVCs<br/>💾 cache + maintenance<br/>kubectl apply]
        end
    end
    
    pvc_k8s --> db_chart
    pvc_k8s --> init_chart
    db_chart --> init_chart
    init_chart --> phpfpm_chart
    phpfpm_chart --> ws_chart
    ws_chart --> websocket_alias
    websocket_alias --> web_chart
    manual_pvcs --> phpfpm_chart
```

### 📋 Ordre d'installation recommandé

| Étape | Commande | Description | Dépendances |
|-------|----------|-------------|-------------|
| **1** | `kubectl apply -f k8s/pvc.yaml` | PVCs principaux | - |
| **2** | `kubectl apply -f manual-pvcs.yaml` | PVCs additionnels | - |
| **3** | `helm install database charts/db` | Base PostgreSQL | PVCs |
| **4** | `helm install init-jobs charts/init-jobs` | Jobs d'initialisation | Database |
| **5** | `helm install orocommerce-app charts/php-fpm` | Application PHP-FPM | Init jobs |
| **6** | `helm install orocommerce-websocket charts/ws` | Serveur WebSocket | Application |
| **7** | `kubectl apply -f websocket-alias.yaml` | Alias pour webserver | WebSocket |
| **8** | `helm install webserver charts/web` | Frontend Nginx | WebSocket alias |
| **9** | `helm install monitoring charts/monitoring` | Prometheus + Grafana | - |

## 📦 Composants Kubernetes

### Deployments & StatefulSets - État Réel

| Composant | Type | Replicas | Auto-scaling | Release Helm | Description |
|-----------|------|----------|--------------|--------------|-------------|
| **webserver** | Deployment | 1 | ❌ | `webserver` | Nginx frontend ✅ Running |
| **orocommerce-app** | Deployment | 2 | ❌ | `orocommerce-app` | Application PHP-FPM ✅ Running |
| **orocommerce-websocket** | Deployment | 1 | ❌ | `orocommerce-websocket` | Serveur WebSocket ✅ Running |
| **database-orocommerce** | Deployment | 1 | ❌ | `database` | PostgreSQL ✅ Running |
| **init-jobs** | Deployment | 1 | ❌ | `init-jobs` | Jobs d'initialisation ⚠️ Failed |
| **monitoring-grafana** | Deployment | 1 | ❌ | `monitoring` | Grafana dashboard ✅ Running |
| **prometheus-prometheus** | StatefulSet | 1 | ❌ | `monitoring` | Prometheus metrics ✅ Running |
| **alertmanager-prometheus** | StatefulSet | 1 | ❌ | `monitoring` | AlertManager ✅ Running |

### Services - Noms Réels

| Service | Type | Port | Target | Helm Release | Description |
|---------|------|------|--------|--------------|-------------|
| **webserver** | ClusterIP | 80 | nginx:80 | `webserver` | Frontend HTTP |
| **orocommerce-app-php-fpm** | ClusterIP | 9000 | php-fpm:9000 | `orocommerce-app` | Application FastCGI |
| **orocommerce-websocket** | ClusterIP | 80 | websocket:80 | Manuel | Alias pour webserver |
| **orocommerce-websocket-ws** | ClusterIP | 80 | websocket:80 | `orocommerce-websocket` | WebSocket réel |
| **database-orocommerce** | ClusterIP | 5432 | postgres:5432 | `database` | Base de données |
| **monitoring-grafana** | ClusterIP | 80 | grafana:3000 | `monitoring` | Grafana interface |
| **prometheus-prometheus** | ClusterIP | 9090 | prometheus:9090 | `monitoring` | Prometheus API |

### Persistent Volume Claims - Configuration Réelle

| PVC | Taille | Mode d'accès | Créé par | Utilisé par | Description |
|-----|--------|--------------|----------|-------------|-------------|
| **pvc-oro-app** | 10Gi | RWO | `k8s/pvc.yaml` | php-fpm, nginx | Code application OroCommerce |
| **pvc-cache** | 5Gi | RWO | Manuel | php-fpm | Cache temporaire |
| **pvc-public-storage** | 20Gi | RWO | `k8s/pvc.yaml` | nginx | Assets publics (images, CSS, JS) |
| **pvc-private-storage** | 10Gi | RWO | `k8s/pvc.yaml` | nginx | Fichiers protégés |
| **pvc-maintenance** | 1Gi | RWO | Manuel | init-jobs | Scripts de maintenance |
| **postgresql-data-database-orocommerce** | 8Gi | RWO | Auto (database chart) | postgres | Données PostgreSQL |

## 🔐 Configuration et Secrets

### ConfigMap Global

Toutes les variables d'environnement partagées :
- **Variables d'image** : `ORO_IMAGE_TAG`, `ORO_IMAGE`
- **Variables d'application** : `ORO_APP_URL`, `ORO_ENV`
- **Variables de base de données** : `ORO_DB_HOST`, `ORO_DB_PORT`
- **Variables de services** : `ORO_MQ_DSN`, `ORO_SESSION_DSN`
- **Variables WebSocket** : `ORO_WEBSOCKET_BACKEND_HOST`

### Secrets

- **Database credentials** : Mots de passe PostgreSQL
- **Application secrets** : Clés d'encryption OroCommerce
- **TLS certificates** : Certificats SSL pour Ingress

## 🚀 Jobs d'Initialisation

### Séquence d'initialisation

```mermaid
sequenceDiagram
    participant Helm
    participant VolumeInit as Volume Init Job
    participant Install as Install Job
    participant RestoreInit as Restore Init Job
    participant App as Application Pods
    
    Helm->>VolumeInit: 1. Create & mount volumes
    VolumeInit->>VolumeInit: Initialize shared storage
    VolumeInit-->>Helm: Volume setup complete
    
    Helm->>Install: 2. Run installation
    Install->>Install: Install OroCommerce
    Install->>Install: Setup database schema
    Install-->>Helm: Installation complete
    
    Helm->>RestoreInit: 3. Restore data (if needed)
    RestoreInit->>RestoreInit: Import sample data
    RestoreInit-->>Helm: Restore complete
    
    Helm->>App: 4. Start application pods
    App->>App: Application ready
```

## 📊 Monitoring et Observabilité

### Architecture de Monitoring

```mermaid
graph TB
    subgraph "Application Pods"
        nginx_metrics[Nginx<br/>/metrics endpoint]
        phpfpm_metrics[PHP-FPM<br/>/status endpoint]
        postgres_metrics[PostgreSQL<br/>pg_stat_* tables]
    end
    
    subgraph "Monitoring Stack"
        prometheus[Prometheus<br/>- Metrics collection<br/>- Rules & alerts]
        grafana[Grafana<br/>- Dashboards<br/>- Visualization]
        alertmanager[AlertManager<br/>- Alert routing<br/>- Notifications]
    end
    
    subgraph "ServiceMonitors"
        sm_nginx[nginx-servicemonitor]
        sm_phpfpm[phpfpm-servicemonitor]
        sm_postgres[postgres-servicemonitor]
    end
    
    nginx_metrics --> sm_nginx
    phpfpm_metrics --> sm_phpfpm
    postgres_metrics --> sm_postgres
    
    sm_nginx --> prometheus
    sm_phpfpm --> prometheus
    sm_postgres --> prometheus
    
    prometheus --> grafana
    prometheus --> alertmanager
```

## 🔄 Flux de Données - Architecture Réelle

### Requête utilisateur standard (Port-Forward)

```mermaid
sequenceDiagram
    participant User
    participant PortForward as Port-Forward<br/>localhost:8080
    participant Nginx as webserver<br/>(Nginx)
    participant PHP-FPM as orocommerce-app-php-fpm<br/>(PHP-FPM)
    participant WebSocket as orocommerce-websocket<br/>(WebSocket)
    participant PostgreSQL as database-orocommerce<br/>(PostgreSQL)
    
    User->>PortForward: HTTP Request<br/>http://localhost:8080
    PortForward->>Nginx: Forward to webserver:80
    Nginx->>Nginx: Serve static files OR
    Nginx->>PHP-FPM: Forward PHP request<br/>orocommerce-app-php-fpm:9000
    PHP-FPM->>PostgreSQL: Database query<br/>database-orocommerce:5432
    PostgreSQL-->>PHP-FPM: Query result
    PHP-FPM-->>Nginx: Response
    Nginx-->>PortForward: HTTP Response
    PortForward-->>User: Final response
    
    Note over Nginx,WebSocket: WebSocket connections<br/>for real-time features
    Nginx->>WebSocket: WebSocket upgrade<br/>orocommerce-websocket:80
```

### Accès aux outils de monitoring

```mermaid
sequenceDiagram
    participant Admin
    participant GrafanaPF as Port-Forward<br/>localhost:3000
    participant Grafana as monitoring-grafana<br/>(Grafana)
    participant PrometheusPF as Port-Forward<br/>localhost:9090
    participant Prometheus as prometheus-prometheus<br/>(Prometheus)
    participant App as Application Pods
    
    Admin->>GrafanaPF: Access dashboards<br/>http://localhost:3000
    GrafanaPF->>Grafana: Forward to grafana:80
    Grafana->>Prometheus: Query metrics<br/>prometheus-prometheus:9090
    
    Admin->>PrometheusPF: Direct metrics access<br/>http://localhost:9090
    PrometheusPF->>Prometheus: Forward to prometheus:9090
    
    Prometheus->>App: Scrape metrics<br/>/metrics endpoints
    App-->>Prometheus: Return metrics
    Prometheus-->>Grafana: Metrics data
    Grafana-->>GrafanaPF: Dashboard display
    GrafanaPF-->>Admin: Visual dashboards
```

### Jobs d'initialisation

```mermaid
sequenceDiagram
    participant Helm as Helm Install
    participant InitJobs as init-jobs<br/>Deployment
    participant VolumeInit as volume-init<br/>Job (✅ Complete)
    participant OroRestore as oro-restore<br/>Job (⏳ Running)
    participant PVCs as Persistent Volumes
    participant Database as database-orocommerce
    
    Helm->>InitJobs: Deploy init-jobs chart
    InitJobs->>VolumeInit: Create volume-init job
    VolumeInit->>PVCs: Initialize shared volumes<br/>pvc-oro-app, pvc-cache, etc.
    VolumeInit-->>InitJobs: ✅ Volume setup complete
    
    InitJobs->>OroRestore: Create oro-restore job
    OroRestore->>Database: Connect to PostgreSQL<br/>database-orocommerce:5432
    OroRestore->>OroRestore: ⏳ Restore process running
    Note over OroRestore: Job en cours d'exécution
```

## 🏷️ Labels et Sélecteurs

### Stratégie de labelling

Tous les objets Kubernetes utilisent un système de labels cohérent :

```yaml
metadata:
  labels:
    app.kubernetes.io/name: orocommerce
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/component: webserver|php-fpm|database|consumer|websocket|cron
    app.kubernetes.io/part-of: orocommerce
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/version: "6.1.0"
```

## 🔧 Ressources et Limites

### Configuration des ressources par composant

| Composant | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| **nginx** | 100m | 500m | 128Mi | 256Mi |
| **php-fpm** | 500m | 1000m | 512Mi | 1Gi |
| **consumer** | 200m | 800m | 256Mi | 512Mi |
| **websocket** | 100m | 300m | 128Mi | 256Mi |
| **cron** | 100m | 200m | 128Mi | 256Mi |
| **postgresql** | 500m | 1000m | 1Gi | 2Gi |
| **redis** | 100m | 200m | 256Mi | 512Mi |

## 🌐 Networking

### Communication entre services

```mermaid
graph LR
    subgraph "External"
        internet[Internet]
    end
    
    subgraph "Cluster Network"
        ingress[Ingress Controller<br/>LoadBalancer/NodePort]
        
        subgraph "Internal Services"
            nginx[nginx:80]
            phpfpm[php-fpm:9000]
            postgres[postgres:5432]
            redis[redis:6379]
            websocket[websocket:8080]
        end
    end
    
    internet --> ingress
    ingress --> nginx
    nginx --> phpfpm
    phpfpm --> postgres
    phpfpm --> redis
    phpfpm --> websocket
```

## 🔒 Sécurité

### Network Policies (Optionnel)

```yaml
# Exemple de politique réseau pour isoler la base de données
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: postgres-network-policy
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/component: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app.kubernetes.io/part-of: orocommerce
    ports:
    - protocol: TCP
      port: 5432
```

### Security Context

Tous les pods sont configurés avec des contextes de sécurité appropriés :
- **Non-root user** pour les applications
- **Root access** uniquement pour l'initialisation des volumes
- **readOnlyRootFilesystem** quand possible

## 📈 Scalabilité

### Horizontal Pod Autoscaler (HPA)

Le composant PHP-FPM est configuré avec HPA :

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
spec:
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

## 🎯 Résilience

### Stratégies de déploiement

- **Rolling Update** : Mise à jour sans interruption
- **Readiness/Liveness Probes** : Vérification de santé des pods
- **PodDisruptionBudgets** : Protection contre les interruptions
- **Multi-AZ deployment** : Répartition sur plusieurs zones

## 🎯 État du Déploiement

### ✅ Services Opérationnels

| Service | URL d'accès | Status | Remarques |
|---------|-------------|--------|-----------|
| **OroCommerce App** | http://localhost:8080 | ✅ Running | Application principale accessible |
| **Grafana Monitoring** | http://localhost:3000 | ✅ Running | admin/admin - 6+ heures de métriques disponibles |
| **Prometheus Metrics** | http://localhost:9090 | ✅ Running | Collecte active des métriques |
| **PostgreSQL Database** | localhost:5432 | ✅ Running | oro/oro - Base fonctionnelle |
