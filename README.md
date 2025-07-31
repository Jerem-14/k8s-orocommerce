# Projet EII 5 - Migration OroCommerce vers Kubernetes

**Bloc RNCP** : EII 5 - Clusterisation de conteneurs  
**Modalité** : Projet en groupe (2 à 4 étudiants)  
---

## Objectif

Migrer l'application **OroCommerce Demo** (https://github.com/oroinc/docker-demo) depuis Docker Compose vers Kubernetes en utilisant Helm Charts.

---

## Critères d'Évaluation

### Critère 1 : Exploiter et surveiller l'activité du système (Coeff. 1)
- Maintenir un flux de données en temps réela
- Mettre en place des outils de monitoring
- Administrer les données selon les normes

### Critère 2 : Optimiser l'exploitation des données (Coeff. 2)
- Adapter la visualisation des données
- Optimiser les ressources (écoconception)
- Superviser la répartition de charge

---

## Livrables

### 1. Infrastructure
- **Helm Charts** complets pour tous les composants
OPTIONNEL: - **Auto-scaling** configuré (HPA) 
- **Monitoring** avec Prometheus/Grafana
OPTIONNEL: - Application **fonctionnelle** en haute disponibilité

### 2. Documentation 
- Architecture Kubernetes avec diagrammes
- Guide d'installation
- Analyse comparative avant/après

---

## Composants à Migrer

- **Frontend** : Nginx (Deployment + Service)
- **Backend** : PHP-FPM (Deployment + HPA - autoscaling (horizontale pods scalling))
- **Database** : MySQL (StatefulSet + PVC)
- **Cache** : Redis (StatefulSet)
- **Search** : Elasticsearch (StatefulSet)
- **Monitoring** : Prometheus + Grafana

ingress controlleur
---

## Contraintes Techniques

- Kubernetes 1.25+
- Helm 3.x
- Haute disponibilité OPTIONNELLE
- SSL/TLS configuré
- Secrets pour les mots de passe
- Resource limits définis

🚀 Étape 2 – Définir un ordre de migration
Voici l’ordre logique pour migrer la stack, en blocs fonctionnels :

🔹 Bloc 1 : Fondations
✅ Créer un Namespace Kubernetes

✅ Convertir .env → Secrets & ConfigMap K8s

✅ Créer les volumes partagés nécessaires (PVC)

✅ Créer les Services web et php-fpm sans dépendances (pour les tester seuls)

🔹 Bloc 2 : Services Applicatifs
📦 Helm Chart pour php-fpm

📦 Helm Chart pour web (NGINX)

📦 Helm Chart pour db (PostgreSQL)

📦 Init jobs (init-jobs chart) — ceux qui préparent les volumes (ex: web-init, volume-init)

🔹 Bloc 3 : Services secondaires
📦 ws, consumer, cron (mêmes images que php-fpm avec commandes différentes)

📦 install, restore (Jobs K8s déclenchables manuellement)

🔹 Bloc 4 : Infrastructure et observabilité
📡 Monitoring : Prometheus + Grafana (via Helm)

🌐 Ingress Controller + TLS (Cert-manager ou TLS manuel)

⚖️ Autoscaling HPA (php-fpm)


ORO_IMAGE_TAG=6.1.0
ORO_IMAGE=oroinc/orocommerce-application
ORO_IMAGE_INIT=${ORO_IMAGE}-init



oro-install-44289            0/1     Error                   0                15m
oro-install-6df52            0/1     Error                   0                13m
oro-install-85tmg            0/1     Error                   0                9m53s
oro-install-nvt8g            0/1     Error                   0                4m33s
oro-install-pndmg            0/1     Error                   0                12m
oro-install-s9xnr            0/1     Error                   0                14m
oro-install-zg5g4 



kubectl describe pod oro-install-44289 -n orocommerce
kubectl describe pod oro-install-6df52 -n orocommerce
kubectl describe pod oro-install-85tmg -n orocommerce
kubectl describe pod oro-install-nvt8g -n orocommerce
kubectl describe pod oro-install-pndmg -n orocommerce
kubectl describe pod oro-install-s9xnr -n orocommerce
kubectl describe pod oro-install-zg5g4 -n orocommerce

