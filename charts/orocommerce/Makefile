# Makefile pour OroCommerce Helm Chart
# Usage: make <target>

# Variables
NAMESPACE := orocommerce
RELEASE_NAME := orocommerce
CHART_PATH := .

# Couleurs pour les messages
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

.PHONY: help install upgrade uninstall status logs pods services ingress clean-deps update-deps port-forward

# Afficher l'aide
help:
	@echo "$(GREEN)Commandes disponibles:$(NC)"
	@echo "  $(YELLOW)install$(NC)      - Installer OroCommerce (première fois)"
	@echo "  $(YELLOW)upgrade$(NC)      - Mettre à jour OroCommerce"
	@echo "  $(YELLOW)uninstall$(NC)    - Désinstaller OroCommerce"
	@echo "  $(YELLOW)status$(NC)       - Afficher le statut du release"
	@echo "  $(YELLOW)logs$(NC)         - Afficher les logs des pods"
	@echo "  $(YELLOW)pods$(NC)         - Lister les pods"
	@echo "  $(YELLOW)services$(NC)     - Lister les services"
	@echo "  $(YELLOW)ingress$(NC)      - Lister les ingress"
	@echo "  $(YELLOW)clean-deps$(NC)   - Nettoyer les dépendances"
	@echo "  $(YELLOW)update-deps$(NC)  - Mettre à jour les dépendances"
	@echo "  $(YELLOW)port-forward$(NC) - Faire un port-forward du webserver"
	@echo "  $(YELLOW)context$(NC)      - Définir le contexte avec namespace orocommerce"
	@echo "  $(YELLOW)diagnose$(NC)     - Diagnostiquer les problèmes"
	@echo "  $(YELLOW)logs-pod$(NC)     - Logs d'un pod spécifique (POD=nom-du-pod)"
	@echo "  $(YELLOW)logs-init$(NC)    - Logs du container init (POD=nom-du-pod)"
	@echo "  $(YELLOW)force-restart$(NC) - Forcer le redémarrage des pods"
	@echo "  $(YELLOW)clean-pvc$(NC)    - Nettoyer les PersistentVolumeClaims"
	@echo "  $(YELLOW)create-pvc$(NC)   - Créer les PersistentVolumeClaims manquants"

# Installer OroCommerce (première fois)
install: update-deps
	@echo "$(GREEN)Installation d'OroCommerce...$(NC)"
	helm install $(RELEASE_NAME) $(CHART_PATH) 

# Mettre à jour OroCommerce
upgrade: update-deps
	@echo "$(GREEN)Mise à jour d'OroCommerce...$(NC)"
	helm upgrade $(RELEASE_NAME) $(CHART_PATH) 

# Désinstaller OroCommerce
uninstall:
	@echo "$(RED)Désinstallation d'OroCommerce...$(NC)"
	helm uninstall $(RELEASE_NAME) 
	make clean-pvc

# Afficher le statut du release
status:
	@echo "$(GREEN)Statut du release:$(NC)"
	helm status $(RELEASE_NAME) 

# Afficher les logs des pods
logs:
	@echo "$(GREEN)Logs des pods:$(NC)"
	@echo "$(YELLOW)Note: Certains pods peuvent être en cours d'initialisation$(NC)"
	kubectl logs  -l app.kubernetes.io/instance=$(RELEASE_NAME) --tail=50 --ignore-errors=true || echo "$(RED)Aucun log disponible pour les pods en cours d'initialisation$(NC)"

# Afficher les logs d'un pod spécifique
logs-pod:
	@echo "$(GREEN)Logs d'un pod spécifique:$(NC)"
	@echo "$(YELLOW)Usage: make logs-pod POD=nom-du-pod$(NC)"
	@if [ -z "$(POD)" ]; then \
		echo "$(RED)Spécifiez un pod avec POD=nom-du-pod$(NC)"; \
		echo "$(YELLOW)Exemple: make logs-pod POD=orocommerce-consumer-6b45cd86fb-znl7q$(NC)"; \
	else \
		kubectl logs  $(POD) --tail=50 --ignore-errors=true || echo "$(YELLOW)Pod en cours d'initialisation, pas de logs disponibles$(NC)"; \
	fi

# Afficher les logs du container init d'un pod
logs-init:
	@echo "$(GREEN)Logs du container init:$(NC)"
	@echo "$(YELLOW)Usage: make logs-init POD=nom-du-pod$(NC)"
	@if [ -z "$(POD)" ]; then \
		echo "$(RED)Spécifiez un pod avec POD=nom-du-pod$(NC)"; \
		echo "$(YELLOW)Exemple: make logs-init POD=orocommerce-consumer-6b45cd86fb-znl7q$(NC)"; \
	else \
		kubectl logs $(POD) -c init-container --tail=50 --ignore-errors=true || echo "$(YELLOW)Container init non disponible$(NC)"; \
	fi

# Lister les pods
pods:
	@echo "$(GREEN)Pods dans le namespace $(NAMESPACE):$(NC)"
	kubectl get pods

# Lister les services
services:
	@echo "$(GREEN)Services dans le namespace $(NAMESPACE):$(NC)"
	kubectl get services

# Lister les ingress
ingress:
	@echo "$(GREEN)Ingress dans le namespace $(NAMESPACE):$(NC)"
	kubectl get ingress

# Nettoyer les dépendances
clean-deps:
	@echo "$(YELLOW)Nettoyage des dépendances...$(NC)"
	rm -rf charts/
	helm dependency build

# Mettre à jour les dépendances
update-deps:
	@echo "$(YELLOW)Mise à jour des dépendances...$(NC)"
	helm dependency update

# Faire un port-forward du webserver
port-forward:
	@echo "$(GREEN)Port-forward du webserver sur localhost:8080...$(NC)"
	@echo "$(YELLOW)Appuyez sur Ctrl+C pour arrêter$(NC)"
	kubectl port-forward svc/webserver-$(RELEASE_NAME) 8080:80

# Définir le contexte avec namespace orocommerce
context:
	@echo "$(GREEN)Définition du contexte avec namespace $(NAMESPACE)...$(NC)"
	kubectl config set-context --current --namespace=$(NAMESPACE)
	@echo "$(GREEN)Contexte défini sur le namespace $(NAMESPACE)$(NC)"

# Afficher les informations du cluster
info:
	@echo "$(GREEN)Informations du cluster:$(NC)"
	@echo "$(YELLOW)Namespace actuel:$(NC)"
	kubectl config view --minify --output 'jsonpath={..namespace}'
	@echo ""
	@echo "$(YELLOW)Contexte actuel:$(NC)"
	kubectl config current-context
	@echo ""
	@echo "$(YELLOW)Nodes du cluster:$(NC)"
	kubectl get nodes


# Redémarrer tous les pods
restart:
	@echo "$(YELLOW)Redémarrage des pods...$(NC)"
	kubectl rollout restart deployment

# Forcer le redémarrage des pods (suppression et recréation)
force-restart:
	@echo "$(RED)Forçage du redémarrage des pods...$(NC)"
	@echo "$(YELLOW)Attention: Cette opération supprime et recrée les pods$(NC)"
	kubectl delete pods --all --grace-period=0 --force

# Nettoyer les PVC et recréer
clean-pvc:
	@echo "$(RED)Nettoyage des PersistentVolumeClaims...$(NC)"
	@echo "$(YELLOW)Attention: Cette opération supprime toutes les données$(NC)"
	kubectl delete pvc --all
	@echo "$(GREEN)PersistentVolumeClaims supprimés$(NC)"

# Recréer les PVC manquants
create-pvc:
	@echo "$(GREEN)Création des PersistentVolumeClaims manquants...$(NC)"
	@echo "apiVersion: v1" > /tmp/oro-pvc.yaml
	@echo "kind: PersistentVolumeClaim" >> /tmp/oro-pvc.yaml
	@echo "metadata:" >> /tmp/oro-pvc.yaml
	@echo "  name: oro-app-orocommerce" >> /tmp/oro-pvc.yaml
	@echo "  namespace: $(NAMESPACE)" >> /tmp/oro-pvc.yaml
	@echo "spec:" >> /tmp/oro-pvc.yaml
	@echo "  accessModes:" >> /tmp/oro-pvc.yaml
	@echo "    - ReadWriteOnce" >> /tmp/oro-pvc.yaml
	@echo "  resources:" >> /tmp/oro-pvc.yaml
	@echo "    requests:" >> /tmp/oro-pvc.yaml
	@echo "      storage: 10Gi" >> /tmp/oro-pvc.yaml
	@echo "---" >> /tmp/oro-pvc.yaml
	@echo "apiVersion: v1" >> /tmp/oro-pvc.yaml
	@echo "kind: PersistentVolumeClaim" >> /tmp/oro-pvc.yaml
	@echo "metadata:" >> /tmp/oro-pvc.yaml
	@echo "  name: cache-orocommerce" >> /tmp/oro-pvc.yaml
	@echo "  namespace: $(NAMESPACE)" >> /tmp/oro-pvc.yaml
	@echo "spec:" >> /tmp/oro-pvc.yaml
	@echo "  accessModes:" >> /tmp/oro-pvc.yaml
	@echo "    - ReadWriteOnce" >> /tmp/oro-pvc.yaml
	@echo "  resources:" >> /tmp/oro-pvc.yaml
	@echo "    requests:" >> /tmp/oro-pvc.yaml
	@echo "      storage: 5Gi" >> /tmp/oro-pvc.yaml
	@echo "---" >> /tmp/oro-pvc.yaml
	@echo "apiVersion: v1" >> /tmp/oro-pvc.yaml
	@echo "kind: PersistentVolumeClaim" >> /tmp/oro-pvc.yaml
	@echo "metadata:" >> /tmp/oro-pvc.yaml
	@echo "  name: maintenance-orocommerce" >> /tmp/oro-pvc.yaml
	@echo "  namespace: $(NAMESPACE)" >> /tmp/oro-pvc.yaml
	@echo "spec:" >> /tmp/oro-pvc.yaml
	@echo "  accessModes:" >> /tmp/oro-pvc.yaml
	@echo "    - ReadWriteOnce" >> /tmp/oro-pvc.yaml
	@echo "  resources:" >> /tmp/oro-pvc.yaml
	@echo "    requests:" >> /tmp/oro-pvc.yaml
	@echo "      storage: 1Gi" >> /tmp/oro-pvc.yaml
	@echo "---" >> /tmp/oro-pvc.yaml
	@echo "apiVersion: v1" >> /tmp/oro-pvc.yaml
	@echo "kind: PersistentVolumeClaim" >> /tmp/oro-pvc.yaml
	@echo "metadata:" >> /tmp/oro-pvc.yaml
	@echo "  name: public-storage-orocommerce" >> /tmp/oro-pvc.yaml
	@echo "  namespace: $(NAMESPACE)" >> /tmp/oro-pvc.yaml
	@echo "spec:" >> /tmp/oro-pvc.yaml
	@echo "  accessModes:" >> /tmp/oro-pvc.yaml
	@echo "    - ReadWriteOnce" >> /tmp/oro-pvc.yaml
	@echo "  resources:" >> /tmp/oro-pvc.yaml
	@echo "    requests:" >> /tmp/oro-pvc.yaml
	@echo "      storage: 20Gi" >> /tmp/oro-pvc.yaml
	@echo "---" >> /tmp/oro-pvc.yaml
	@echo "apiVersion: v1" >> /tmp/oro-pvc.yaml
	@echo "kind: PersistentVolumeClaim" >> /tmp/oro-pvc.yaml
	@echo "metadata:" >> /tmp/oro-pvc.yaml
	@echo "  name: private-storage-orocommerce" >> /tmp/oro-pvc.yaml
	@echo "  namespace: $(NAMESPACE)" >> /tmp/oro-pvc.yaml
	@echo "spec:" >> /tmp/oro-pvc.yaml
	@echo "  accessModes:" >> /tmp/oro-pvc.yaml
	@echo "    - ReadWriteOnce" >> /tmp/oro-pvc.yaml
	@echo "  resources:" >> /tmp/oro-pvc.yaml
	@echo "    requests:" >> /tmp/oro-pvc.yaml
	@echo "      storage: 10Gi" >> /tmp/oro-pvc.yaml
	kubectl apply -f /tmp/oro-pvc.yaml
	@rm /tmp/oro-pvc.yaml
	@echo "$(GREEN)PersistentVolumeClaims créés$(NC)"

# Vérifier la santé des pods
health:
	@echo "$(GREEN)Vérification de la santé des pods...$(NC)"
	kubectl get pods -o wide
	@echo ""
	@echo "$(YELLOW)Événements récents:$(NC)"
	kubectl get events --sort-by='.lastTimestamp'
	@echo ""
	@echo "$(YELLOW)Pods avec problèmes:$(NC)"
	kubectl get pods --field-selector=status.phase!=Running

# Diagnostiquer les problèmes
diagnose:
	@echo "$(GREEN)Diagnostic des problèmes...$(NC)"
	@echo "$(YELLOW)1. Vérification des images:$(NC)"
	kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[*].image}{"\n"}{end}'
	@echo ""
	@echo "$(YELLOW)2. Événements d'erreur:$(NC)"
	kubectl get events --field-selector=type=Warning --sort-by='.lastTimestamp' | head -10
	@echo ""
	@echo "$(YELLOW)3. Pods avec problèmes:$(NC)"
	kubectl get pods | grep -v "Running\|Completed"
	@echo ""
	@echo "$(YELLOW)4. Événements des pods en erreur:$(NC)"
	for pod in $$(kubectl get pods --no-headers | grep -v "Running\|Completed" | awk '{print $$1}'); do \
		echo "$(GREEN)Pod: $$pod$(NC)"; \
		kubectl describe pod $$pod | grep -A 10 "Events:" || true; \
		echo ""; \
	done 