# 🏗️ Architecture Kubernetes OroCommerce

## 🎯 Vue d'ensemble

Cette documentation présente l'architecture complète de la migration d'OroCommerce depuis Docker Compose vers Kubernetes. L'architecture est conçue pour être scalable, résiliente et facile à maintenir grâce à l'utilisation de Helm Charts.

## 📊 Architecture Globale

```mermaid
graph TB
    subgraph "External Access"
        user[👤 User]
        admin[👤 Admin]
        ingress[Ingress Controller]
    end
    
    subgraph "Kubernetes Cluster"
        subgraph "OroCommerce Namespace"
            subgraph "Frontend Layer"
                nginx[Nginx Webserver<br/>Deployment]
            end
            
            subgraph "Application Layer"
                phpfpm[PHP-FPM<br/>Deployment + HPA]
                consumer[Consumer<br/>Deployment]
                websocket[WebSocket<br/>Deployment]
                cron[Cron Jobs<br/>Deployment]
            end
            
            subgraph "Database Layer"
                postgres[PostgreSQL<br/>StatefulSet]
                redis[Redis<br/>StatefulSet]
                elasticsearch[Elasticsearch<br/>StatefulSet]
            end
            
            subgraph "Storage Layer"
                pvc1[oro-app PVC]
                pvc2[cache PVC]
                pvc3[public-storage PVC]
                pvc4[private-storage PVC]
                pvc5[maintenance PVC]
            end
            
            subgraph "Configuration"
                configmap[Global ConfigMap]
                secrets[Database Secrets]
            end
            
            subgraph "Initialization"
                initjobs[Init Jobs<br/>Job Resources]
            end
        end
        
        subgraph "Monitoring Namespace"
            prometheus[Prometheus<br/>Deployment]
            grafana[Grafana<br/>Deployment]
            alertmanager[AlertManager<br/>Deployment]
        end
    end
    
    user --> ingress
    admin --> ingress
    ingress --> nginx
    nginx --> phpfpm
    phpfpm --> postgres
    phpfpm --> redis
    phpfpm --> elasticsearch
    
    consumer --> postgres
    consumer --> redis
    websocket --> phpfpm
    cron --> postgres
    
    phpfpm --> pvc1
    phpfpm --> pvc2
    nginx --> pvc3
    nginx --> pvc4
    
    configmap -.-> phpfpm
    configmap -.-> nginx
    configmap -.-> consumer
    configmap -.-> websocket
    configmap -.-> cron
    
    secrets -.-> postgres
    
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

## 🔧 Helm Charts Structure

```mermaid
graph TD
    subgraph "Main Chart: orocommerce"
        main_chart[orocommerce/<br/>Chart.yaml<br/>values.yaml]
        
        subgraph "Sub-charts"
            web_chart[web/<br/>Nginx deployment]
            phpfpm_chart[php-fpm/<br/>Application deployment]
            db_chart[db/<br/>PostgreSQL deployment]
            consumer_chart[consumer/<br/>Background processing]
            ws_chart[ws/<br/>WebSocket server]
            cron_chart[cron/<br/>Scheduled tasks]
            init_chart[init-jobs/<br/>Initialization]
        end
        
        subgraph "External Charts"
            monitoring_chart[monitoring/<br/>Prometheus + Grafana]
        end
    end
    
    main_chart --> web_chart
    main_chart --> phpfpm_chart
    main_chart --> db_chart
    main_chart --> consumer_chart
    main_chart --> ws_chart
    main_chart --> cron_chart
    main_chart --> init_chart
```

## 📦 Composants Kubernetes

### Deployments & StatefulSets

| Composant | Type | Replicas | Auto-scaling | Description |
|-----------|------|----------|--------------|-------------|
| **webserver** | Deployment | 1-3 | ❌ | Nginx frontend avec load balancing |
| **php-fpm** | Deployment | 2-10 | ✅ HPA | Application principale OroCommerce |
| **consumer** | Deployment | 1-3 | ❌ | Traitement des messages en arrière-plan |
| **websocket** | Deployment | 1-2 | ❌ | Serveur WebSocket pour temps réel |
| **cron** | Deployment | 1 | ❌ | Tâches planifiées et maintenance |
| **database** | StatefulSet | 1 | ❌ | PostgreSQL avec stockage persistant |
| **redis** | StatefulSet | 1 | ❌ | Cache et stockage de sessions |
| **elasticsearch** | StatefulSet | 1 | ❌ | Moteur de recherche |

### Services

| Service | Type | Port | Target | Description |
|---------|------|------|--------|-------------|
| **webserver-svc** | ClusterIP | 80 | nginx:80 | Frontend HTTP |
| **php-fpm-svc** | ClusterIP | 9000 | php-fpm:9000 | Application FastCGI |
| **database-svc** | ClusterIP | 5432 | postgres:5432 | Base de données |
| **redis-svc** | ClusterIP | 6379 | redis:6379 | Cache Redis |
| **websocket-svc** | ClusterIP | 8080 | websocket:8080 | WebSocket server |

### Persistent Volume Claims

| PVC | Taille | Mode d'accès | Utilisé par | Description |
|-----|--------|--------------|-------------|-------------|
| **oro-app** | 10Gi | ReadWriteMany | php-fpm, consumer, cron, websocket | Code application OroCommerce |
| **cache** | 5Gi | ReadWriteMany | php-fpm | Cache temporaire |
| **public-storage** | 20Gi | ReadWriteMany | webserver | Assets publics (images, CSS, JS) |
| **private-storage** | 10Gi | ReadWriteMany | webserver | Fichiers protégés |
| **maintenance** | 1Gi | ReadWriteOnce | init-jobs | Scripts de maintenance |

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

## 🔄 Flux de Données

### Requête utilisateur standard

```mermaid
sequenceDiagram
    participant User
    participant Ingress
    participant Nginx
    participant PHP-FPM
    participant PostgreSQL
    participant Redis
    
    User->>Ingress: HTTP Request
    Ingress->>Nginx: Route request
    Nginx->>Nginx: Serve static files OR
    Nginx->>PHP-FPM: Forward PHP request
    PHP-FPM->>PostgreSQL: Database query
    PHP-FPM->>Redis: Session/cache lookup
    Redis-->>PHP-FPM: Cache data
    PostgreSQL-->>PHP-FPM: Query result
    PHP-FPM-->>Nginx: Response
    Nginx-->>Ingress: HTTP Response
    Ingress-->>User: Final response
```

### Traitement asynchrone

```mermaid
sequenceDiagram
    participant PHP-FPM
    participant Redis as Redis Queue
    participant Consumer
    participant PostgreSQL
    
    PHP-FPM->>Redis: Add message to queue
    Consumer->>Redis: Poll for messages
    Redis-->>Consumer: Return message
    Consumer->>PostgreSQL: Process business logic
    Consumer->>Consumer: Update job status
    PostgreSQL-->>Consumer: Confirm update
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

---

Cette architecture Kubernetes moderne offre :
- ✅ **Scalabilité** automatique avec HPA
- ✅ **Résilience** avec redondance et health checks
- ✅ **Observabilité** complète avec monitoring
- ✅ **Sécurité** avec isolation et secrets
- ✅ **Maintenance** simplifiée avec Helm Charts
