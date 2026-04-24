# N8N Worker

N8N Worker est une application Rails qui sert d'interface entre n8n (un outil d'automatisation de workflow) et d'autres services. Elle fournit une API GraphQL sécurisée pour la gestion des tâches et l'authentification.

## Documentation

La documentation complète est disponible en plusieurs formats :

### Pour démarrer
```bash
# Générer la documentation
rake docs:generate

# Lancer les serveurs de documentation
rake docs:serve
```

Puis accédez à :
- Documentation Ruby : http://localhost:8808
- Documentation GraphQL : http://localhost:8809

### Structure de la documentation
- `/documentation/yard/` : Documentation Ruby détaillée
- `/documentation/graphql/` : Documentation de l'API GraphQL
- `changelog.md` : Historique détaillé des versions

## Configuration requise

### Versions
- Ruby 3.4.8
- Rails 8.0.1
- SQLite3 (base de données par défaut)

### Dépendances système
- Ruby avec Bundler
- SQLite3
- Chrome/Chromium (pour les tests système)

## Installation

1. Cloner le repository
```bash
git clone [URL_DU_REPO]
cd n8n_worker
```

2. Installer les dépendances
```bash
bundle install
```

3. Configurer l'environnement
```bash
# Copier le fichier d'exemple
cp .env.example .env

# Éditer les variables d'environnement
# Particulièrement important :
# - JWT_SECRET_KEY
# - JWT_EXPIRATION
```

4. Préparer la base de données
```bash
rails db:create
rails db:migrate
rails db:seed          # creates admin account and syncs permissions
```

The seed creates:
- Account: `admin@example.com` / `changeme123` (change after first login)
- Roles: `admin`, `user`
- All permissions declared in the codebase (via `rails permissions:sync`)

## Tests

### Prérequis
Avant de lancer les tests, assurez-vous que l'environnement de test est correctement configuré :

```bash
# Préparer la base de données de test
RAILS_ENV=test rails db:create db:migrate

# Vérifier que l'environnement est correctement défini
RAILS_ENV=test rails db:environment:set RAILS_ENV=test
```

### Lancer la suite de tests

#### Option 1 : Avec couverture de code (recommandé)
```bash
RAILS_ENV=test rake test:coverage
```

#### Option 2 : Tests simples
```bash
# Tous les tests
RAILS_ENV=test bundle exec rspec

# Tests spécifiques
RAILS_ENV=test bundle exec rspec spec/models/
RAILS_ENV=test bundle exec rspec spec/graphql/
RAILS_ENV=test bundle exec rspec spec/system/
```

#### Option 3 : Tests avec format détaillé
```bash
RAILS_ENV=test bundle exec rspec --format documentation
```

### Résultats et rapports

- **Couverture de code** : Généré dans `coverage/` (format HTML)
- **Captures d'écran** : Stockées dans `tmp/screenshots/` en cas d'échec des tests système
- **Logs d'erreurs** : Affichés dans la console avec détails

### Types de tests disponibles

1. **Tests de modèles** (`spec/models/`)
   - Validations et associations
   - Factories et scopes

2. **Tests GraphQL** (`spec/graphql/`)
   - Mutations (Login, etc.)
   - Queries (User, etc.)

3. **Tests système** (`spec/system/`)
   - Interface utilisateur
   - Processus de login

4. **Tests de services** (`spec/lib/`)
   - Service JWT
   - Helpers

### Dépannage

Si vous rencontrez des erreurs :

1. **Migrations en attente** :
   ```bash
   RAILS_ENV=test rails db:migrate
   ```

2. **Base de données corrompue** :
   ```bash
   RAILS_ENV=test rails db:drop db:create db:migrate
   ```

3. **Problème d'environnement** :
   ```bash
   RAILS_ENV=test rails db:environment:set RAILS_ENV=test
   ```

## GraphQL API

All requests go to `POST /graphql`.

### Authentication

#### Step 1 — Obtain a JWT via the login mutation (public, no token required)

```graphql
mutation {
  login(email: "user@example.com", password: "password") {
    token
    user { id email username }
    errors
  }
}
```

#### Step 2 — Include the token in every subsequent request

```bash
Authorization: Bearer <token>
```

### Permissions

Protected operations require a permission. The table below lists all operations and their required permission.

| Operation | Type | Required permission |
|---|---|---|
| `login` | mutation | _(public)_ |
| `user` | query | `users:read` |
| `users` | query | `users:read` |
| `updateUser` | mutation | `users:write` |
| `apiTokens` | query | `tokens:read` |
| `verifyToken` | query | `tokens:read` |
| `createApiToken(name, expiresInDays?, permissionIds?)` | mutation | `tokens:write` |
| `revokeApiToken` | mutation | `tokens:write` |
| `updateApiTokenPermissions(id, permissionIds)` | mutation | `tokens:write` |
| `roles` | query | `roles:read` |
| `permissions` | query | `roles:read` |
| `updateRolePermissions(roleId, permissionIds)` | mutation | `roles:write` |
| `assistantConfig` | query | `assistant_config:read` |
| `assistantEvents` | query | `assistant_config:read` |
| `assistantReminders` | query | `assistant_config:read` |
| `assistantAlerts` | query | `assistant_alerts:read` |
| `sharedNotificationChannels` | query | `assistant_shared_channels:read` |
| `updateAssistantConfig(...)` | mutation | `assistant_config:write` |
| `setCalendarSource(url)` | mutation | `assistant_config:write` |
| `upsertNotificationChannel(...)` | mutation | `assistant_config:write` |
| `deleteNotificationChannel(id)` | mutation | `assistant_config:write` |
| `acknowledgeSharedChannelConsent(id)` | mutation | `assistant_config:write` |
| `addSharedChannelToMyChannels(sharedChannelId)` | mutation | `assistant_config:write` |
| `removeSharedChannelFromMyChannels(id)` | mutation | `assistant_config:write` |
| `purgeMyAlerts` | mutation | `assistant_alerts:write` |
| `createSharedNotificationChannel(...)` | mutation | `assistant_shared_channels:write` |
| `updateSharedNotificationChannel(...)` | mutation | `assistant_shared_channels:write` |
| `deleteSharedNotificationChannel(id)` | mutation | `assistant_shared_channels:write` |

When a request is denied the API returns:
```json
{ "errors": [{ "message": "NOT_AUTHORIZED", "extensions": { "code": "UNAUTHORIZED" } }] }
```

#### JWT authentication — permissions come from the user's role

Assign permissions to a role via the admin interface at `/admin/roles`, via GraphQL (`updateRolePermissions`), or via the console:
```bash
rails permissions:sync          # populate Permission records from code
# then assign via /admin/roles or updateRolePermissions mutation
```

#### API token authentication — permissions are scoped per token

Select permissions when creating a token (web form at `/api/v1/tokens/new`, or via GraphQL with `createApiToken(permissionIds: [...])`) and update them later with `updateApiTokenPermissions`. A token with no permissions cannot access any protected operation.

To authenticate with an API token use the same `Authorization: Bearer` header.

### Example requests

**List users (requires `users:read`)**
```bash
curl -X POST http://localhost:3000/graphql \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"query":"query { users { id email username } }"}'
```

**Create an API token (requires `tokens:write`)**
```bash
curl -X POST http://localhost:3000/graphql \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"query":"mutation { createApiToken(name: \"CI\") { apiToken { id name } errors } }"}'
```

**Verify an API token (requires `tokens:read`)**
```bash
curl -X POST http://localhost:3000/graphql \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"query":"query { verifyToken(token: \"<raw_token>\") { id name } }"}'
```

## Assistant subsystem (S1)

The assistant subsystem monitors an ICS calendar, schedules reminders, and fans them out across multiple channels.

### How it works

1. `CalendarSyncSchedulerJob` runs periodically and enqueues a `PerUserCalendarSyncJob` for each user who has a calendar source configured.
2. `PerUserCalendarSyncJob` fetches the ICS feed, reconciles events against the database, and creates or invalidates `CalendarReminder` records via `ReminderPlanner`.
3. `FireReminderJob` fires at each reminder's scheduled time and delegates to `AlertEmitter`, which fans out to all of the user's enabled channels (internal, ntfy, email, webhook, shared) with a configurable grace window for retries after an event starts.

### Channel types

| Channel | Description |
|---|---|
| `internal` | Stored in the database as `AlertEmission` records, readable via `assistantAlerts` |
| `ntfy` | Push notification to a self-hosted or public ntfy server |
| `email` | Email via `AssistantMailer` |
| `webhook` | HTTP POST to an arbitrary URL |
| `shared` | Admin-managed shared channel; user must give explicit consent before receiving alerts |

### Permissions

| Permission | Grants |
|---|---|
| `assistant_config:read` | Read own assistant config, events, reminders |
| `assistant_config:write` | Update config, calendar source, own notification channels, shared channel consent |
| `assistant_alerts:read` | Read own alert history |
| `assistant_alerts:write` | Purge own alert history |
| `assistant_shared_channels:read` | List admin-managed shared channels |
| `assistant_shared_channels:write` | Admin CRUD on shared channels |

Both default roles (`user` and `admin`) receive `assistant_config:read/write` and `assistant_alerts:read/write` and `assistant_shared_channels:read` via seeds. Only `admin` gets `assistant_shared_channels:write`.

### Example — configure a calendar source

```bash
curl -X POST http://localhost:3000/graphql \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"query":"mutation { setCalendarSource(url: \"https://example.com/calendar.ics\") { userAssistantConfig { calendarSourceUrl } errors } }"}'
```

### Example — list upcoming reminders

```bash
curl -X POST http://localhost:3000/graphql \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"query":"query { assistantReminders { id scheduledAt status calendarEvent { title } } }"}'
```

## Déploiement

Le déploiement est géré via Kamal :
```bash
kamal deploy
```

## Contribution

1. Créer une branche
2. Ajouter des tests
3. Mettre à jour la documentation
4. Soumettre une Pull Request

## Licence

Ce projet est disponible sous deux licences au choix :

- [GNU GPL v3](https://www.gnu.org/licenses/gpl-3.0.html) : Pour une utilisation dans des projets open source
- [MIT](https://opensource.org/licenses/MIT) : Pour une utilisation plus permissive

### Autrement dit :
Vous êtes libre d'utiliser ce code comme bon vous semble, que ce soit dans un projet open source ou propriétaire. 
La double licence vous donne cette flexibilité. La seule exigence fondamentale est de respecter l'attribution 
de la propriété intellectuelle originale. Utilisez, modifiez, distribuez - et laissez les autres en faire autant paisiblement.

Le code source est disponible sur [github.com/Atout-Agile/n8n_worker](https://github.com/Atout-Agile/n8n_worker).



