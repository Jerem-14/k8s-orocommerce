# OroCommerce Kubernetes Charts

## Configuration des Variables d'Environnement

### ConfigMap Global

Toutes les variables d'environnement communes sont maintenant centralisées dans un ConfigMap global : `{{ include "orocommerce.fullname" . }}-global-config`

### Structure des Variables

#### Variables Globales (ConfigMap)
- **Variables d'image** : `ORO_IMAGE_TAG`, `ORO_IMAGE`, `ORO_IMAGE_INIT`, etc.
- **Variables d'utilisateur** : `ORO_USER_RUNTIME`, `ORO_ENV`
- **Variables d'installation** : `ORO_USER_NAME`, `ORO_USER_PASSWORD`, etc.
- **Variables de base de données** : `ORO_DB_HOST`, `ORO_DB_PORT`, etc.
- **Variables de services** : `ORO_MQ_DSN`, `ORO_SESSION_DSN`, etc.
- **Variables WebSocket** : `ORO_WEBSOCKET_BACKEND_HOST`, etc.
- **Variables d'application** : `ORO_APP_URL`, `ORO_SITES`, etc.

#### Variables Spécifiques par Déploiement
Chaque déploiement peut surcharger ou ajouter des variables spécifiques via la section `env` :

```yaml
envFrom:
  - configMapRef:
      name: {{ include "orocommerce.fullname" $ }}-global-config
env:
  # Variables spécifiques au déploiement
  - name: VARIABLE_SPECIFIQUE
    value: "valeur"
```

### Déploiements Modifiés

#### Webserver
- Utilise `envFrom` pour le ConfigMap global
- Variables spécifiques : surcharges pour la configuration nginx

#### PHP-FPM
- Utilise `envFrom` pour le ConfigMap global
- Variables spécifiques : configuration PHP-FPM

#### WebSocket
- Utilise `envFrom` pour le ConfigMap global
- Variables spécifiques : configuration WebSocket

#### Consumer
- Utilise `envFrom` pour le ConfigMap global
- Variables spécifiques : configuration consumer

#### Cron
- Utilise `envFrom` pour le ConfigMap global
- Variables spécifiques : configuration cron

#### Jobs d'Installation
- Utilise `envFrom` pour le ConfigMap global
- Variables spécifiques :
  - `ORO_DB_HOST`: "database-orocommerce"
  - `ORO_DB_DSN`: URL de base de données spécifique
  - `DATABASE_URL`: URL de base de données spécifique
  - `ORO_MAILER_DSN`: "smtp://orocommerce-mail:1025"
  - `ORO_INSTALL_OPTIONS`: "--drop-database"

### Avantages

1. **Centralisation** : Toutes les variables communes dans un seul ConfigMap
2. **Maintenance** : Modification d'une variable = mise à jour d'un seul endroit
3. **Cohérence** : Évite les incohérences entre déploiements
4. **Flexibilité** : Possibilité de surcharger des variables par déploiement
5. **Lisibilité** : Structure claire et documentée

### Utilisation

Pour ajouter une nouvelle variable globale :
1. Ajouter la variable dans `charts/orocommerce/templates/configmap.yaml`
2. Tous les déploiements l'auront automatiquement

Pour surcharger une variable dans un déploiement spécifique :
1. Ajouter la variable dans la section `env` du déploiement
2. La valeur locale aura la priorité sur celle du ConfigMap global 