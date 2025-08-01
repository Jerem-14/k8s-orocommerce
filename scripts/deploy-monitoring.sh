#!/bin/bash

# 📊 Script de déploiement monitoring OroCommerce
# Auteur: Équipe OroCommerce K8s
# Description: Déploie Prometheus et Grafana pour surveiller OroCommerce

set -e

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
NAMESPACE=${1:-orocommerce}
HELM_RELEASE=${2:-orocommerce}
CHARTS_DIR="$(dirname "$0")/../charts"

echo -e "${BLUE}🚀 Déploiement du monitoring OroCommerce${NC}"
echo "Namespace: $NAMESPACE"
echo "Release: $HELM_RELEASE"
echo ""

# Fonction de logging
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Vérifications préalables
log_info "Vérification des prérequis..."

# Vérifier kubectl
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl n'est pas installé"
    exit 1
fi

# Vérifier helm
if ! command -v helm &> /dev/null; then
    log_error "helm n'est pas installé"
    exit 1
fi

# Vérifier la connexion au cluster
if ! kubectl cluster-info &> /dev/null; then
    log_error "Impossible de se connecter au cluster Kubernetes"
    exit 1
fi

log_success "Prérequis validés"

# Créer le namespace si nécessaire
log_info "Création du namespace $NAMESPACE..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
log_success "Namespace $NAMESPACE prêt"

# Ajouter les repositories Helm nécessaires
log_info "Ajout des repositories Helm..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
log_success "Repositories Helm mis à jour"

# Mise à jour des dépendances du chart monitoring
log_info "Mise à jour des dépendances du chart monitoring..."
cd "$CHARTS_DIR/monitoring"
helm dependency update
cd - > /dev/null
log_success "Dépendances mises à jour"

# Installation ou mise à jour du chart principal
log_info "Déploiement d'OroCommerce avec monitoring..."

if helm list -n $NAMESPACE | grep -q $HELM_RELEASE; then
    log_warning "Release $HELM_RELEASE existe déjà, mise à jour..."
    helm upgrade $HELM_RELEASE "$CHARTS_DIR/orocommerce" \
        --namespace $NAMESPACE \
        --set monitoring.enabled=true \
        --wait --timeout=10m
else
    log_info "Installation de $HELM_RELEASE..."
    helm install $HELM_RELEASE "$CHARTS_DIR/orocommerce" \
        --namespace $NAMESPACE \
        --set monitoring.enabled=true \
        --create-namespace \
        --wait --timeout=10m
fi

log_success "Déploiement terminé"

# Attendre que tous les pods soient prêts
log_info "Attente que tous les pods soient prêts..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=prometheus -n $NAMESPACE --timeout=300s
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=grafana -n $NAMESPACE --timeout=300s
log_success "Tous les pods sont prêts"

# Vérifications post-déploiement
log_info "Vérifications post-déploiement..."

# Vérifier les ServiceMonitors
SERVICEMONITORS=$(kubectl get servicemonitor -n $NAMESPACE --no-headers | wc -l)
log_info "ServiceMonitors trouvés: $SERVICEMONITORS"

# Vérifier les PrometheusRules
RULES=$(kubectl get prometheusrules -n $NAMESPACE --no-headers | wc -l)
log_info "Règles Prometheus trouvées: $RULES"

# Vérifier les services
log_info "Services de monitoring déployés:"
kubectl get svc -n $NAMESPACE | grep -E "(prometheus|grafana|alertmanager)"

echo ""
log_success "🎉 Monitoring déployé avec succès!"
echo ""

# Instructions d'accès
echo -e "${YELLOW}📊 ACCÈS AUX INTERFACES:${NC}"
echo ""
echo -e "${BLUE}Grafana Dashboard:${NC}"
echo "  kubectl port-forward service/prometheus-grafana 3000:80 -n $NAMESPACE"
echo "  URL: http://localhost:3000"
echo "  Username: admin"
echo "  Password: admin123"
echo ""
echo -e "${BLUE}Prometheus UI:${NC}"
echo "  kubectl port-forward service/prometheus-server 9090:80 -n $NAMESPACE"
echo "  URL: http://localhost:9090"
echo ""
echo -e "${BLUE}AlertManager:${NC}"
echo "  kubectl port-forward service/prometheus-alertmanager 9093:80 -n $NAMESPACE"
echo "  URL: http://localhost:9093"
echo ""

# Test de connectivité
echo -e "${YELLOW}🔧 TESTS DE CONNECTIVITÉ:${NC}"
echo ""

# Test Prometheus
PROMETHEUS_POD=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [[ -n "$PROMETHEUS_POD" ]]; then
    log_success "Prometheus pod: $PROMETHEUS_POD"
else
    log_warning "Prometheus pod non trouvé"
fi

# Test Grafana
GRAFANA_POD=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [[ -n "$GRAFANA_POD" ]]; then
    log_success "Grafana pod: $GRAFANA_POD"
else
    log_warning "Grafana pod non trouvé"
fi

echo ""
echo -e "${GREEN}✨ Monitoring opérationnel ! Consultez la documentation dans docs/monitoring-guide.md${NC}"
echo ""

# Script de nettoyage optionnel
cat << 'EOF' > cleanup-monitoring.sh
#!/bin/bash
# Script de nettoyage du monitoring
echo "🧹 Nettoyage du monitoring..."
helm uninstall orocommerce -n orocommerce
kubectl delete namespace orocommerce
echo "✅ Nettoyage terminé"
EOF

chmod +x cleanup-monitoring.sh
log_info "Script de nettoyage créé: ./cleanup-monitoring.sh"