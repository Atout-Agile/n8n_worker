# Todo

## Tests d'intégration GraphQL existants [✓ Created in n8n_worker project]

### Test d'intégration Login [✓ Created in n8n_worker project]
Sachant que la mutation Login est déjà implémentée
Afin de garantir son bon fonctionnement de bout en bout
En tant que Quality Assurance
Je veux créer un test système qui vérifie :
- Le formulaire de login avec email/password
- L'affichage des erreurs de validation
- La redirection après connexion réussie
- Le stockage du token dans le localStorage

### Test d'intégration Authentification [✓ Created in n8n_worker project]
Sachant que l'authentification JWT est implémentée
Afin de garantir la sécurité de l'application
En tant que Quality Assurance
Je veux créer un test système qui vérifie :
- L'accès aux routes protégées avec un token valide
- Le refus d'accès avec un token invalide
- La gestion de l'expiration des tokens
- La déconnexion et la suppression du token

### Test d'intégration ApiToken [✓ Created in n8n_worker project]
Sachant que la gestion des tokens API est implémentée
Afin de garantir la gestion des accès API
En tant que Quality Assurance
Je veux créer un test système qui vérifie :
- La création d'un nouveau token
- L'affichage de la liste des tokens
- La révocation d'un token
- L'expiration automatique des tokens

## GraphQL Queries [✓ Created in n8n_worker project]

### User Query [✓ Created in n8n_worker project]
Sachant que l'application stocke les informations des utilisateurs
Afin de pouvoir afficher les détails d'un utilisateur spécifique
En tant que développeur de l'application
Je veux créer une query GraphQL qui retourne les informations d'un utilisateur par son ID ou email

### User Tokens Query [✓ Created in n8n_worker project]
Sachant que chaque utilisateur peut avoir plusieurs tokens API
Afin de permettre la gestion des accès API
En tant que développeur de l'application
Je veux créer une query GraphQL qui liste tous les tokens actifs d'un utilisateur

### Token Verification Query [✓ Created in n8n_worker project]
Sachant que les tokens API doivent être validés avant utilisation
Afin de sécuriser l'accès à l'API
En tant que développeur de l'application
Je veux créer une query GraphQL qui vérifie la validité d'un token et retourne ses informations

## GraphQL Mutations

### Create API Token [✓ Created in n8n_worker project]
Sachant que les utilisateurs ont besoin de tokens pour accéder à l'API
Afin de permettre la génération sécurisée de nouveaux tokens
En tant que développeur de l'application
Je veux créer une mutation GraphQL qui génère un nouveau token API avec une date d'expiration

### Revoke API Token [✓ Created in n8n_worker project]
Sachant que les tokens compromis doivent pouvoir être révoqués
Afin de maintenir la sécurité de l'API
En tant que développeur de l'application
Je veux créer une mutation GraphQL qui révoque immédiatement un token API existant

### Update User [✓ Created in n8n_worker project]
Sachant que les informations des utilisateurs peuvent changer
Afin de maintenir les données à jour
En tant que développeur de l'application
Je veux créer une mutation GraphQL qui permet de mettre à jour les informations d'un utilisateur

## Tests d'intégration

### Authentication Flow [✓ Created in n8n_worker project]
Sachant que l'authentification est critique pour la sécurité
Afin de garantir le bon fonctionnement du processus d'authentification
En tant que Quality Assurance
Je veux créer des tests qui vérifient le flow complet : login, génération de token, utilisation, expiration

### API Token Lifecycle [✓ Created in n8n_worker project]
Sachant que les tokens API ont un cycle de vie complet
Afin de garantir leur bon fonctionnement
En tant que Quality Assurance
Je veux créer des tests qui vérifient la création, l'utilisation, la révocation et l'expiration des tokens

### Permission Errors [✓ Created in n8n_worker project]
Sachant que l'accès aux ressources doit être contrôlé
Afin de garantir la sécurité de l'application
En tant que Quality Assurance
Je veux créer des tests qui vérifient que les erreurs de permission sont correctement gérées

### Mutation: Mise à jour utilisateur [✓ Created in project n8n_worker]
Sachant que les informations des utilisateurs peuvent changer
Afin de maintenir les données à jour
En tant que développeur de l'application
Je veux créer une mutation GraphQL qui permet de mettre à jour les informations d'un utilisateur

### Additional Helpers [✓ Created in n8n_worker project]
Sachant que le formatage des données est important pour l'interface utilisateur
Afin d'améliorer l'expérience utilisateur
En tant que développeur de l'application
Je veux créer des helpers supplémentaires pour le formatage des dates, statuts et autres données

### View Testing [✓ Created in n8n_worker project]
Sachant que les vues doivent fonctionner dans différents scénarios
Afin de garantir une expérience utilisateur cohérente
En tant que développeur de l'application
Je veux créer des tests qui vérifient le rendu des vues dans différentes situations (succès, erreur, données manquantes)

## Système de Permissions [⌛ To create in n8n_worker project]

### Décisions d'architecture

**Librairie** : Action Policy + `action_policy-graphql`
- Les policies vivent dans `app/policies/`
- Chaque ressource a sa policy (`UserPolicy`, `ApiTokenPolicy`, etc.)
- L'intégration GraphQL est native via `action_policy-graphql`

**Modèle de données** :
```
Role ──< RolePermission >── Permission
                                 ▲
                                 │ (sous-ensemble validé)
ApiToken ──< ApiTokenPermission >┘
```
- `Permission` : enregistrement en base (name, description). Ex : `users:read`
- `role_permissions` : table de liaison Role ↔ Permission
- `api_token_permissions` : table de liaison ApiToken ↔ Permission
- Contrainte : les permissions d'un token doivent être un sous-ensemble des permissions de son rôle — validé au niveau modèle

**Format des permissions** : `resource:action`
- `users:read`, `users:write`
- `tokens:read`, `tokens:write`
- Extensible à de futures ressources (ex : `jobs:read`, `jobs:write`)

**Déclaration des permissions dans le code (Option A — explicite)**

Chaque mutation/query déclare sa permission requise via un DSL sur la classe :
```ruby
class Mutations::UpdateUser < BaseMutation
  permission_required "users:write"
  # ...
end

class Queries::Users < BaseQuery
  permission_required "users:read"
  # ...
end
```
La mutation `Login` ne déclare pas de `permission_required` → elle est publique.

La liste canonique des permissions est donc dérivée du code lui-même (scan de toutes les classes mutations/queries). Une tâche Rake synchronise cette liste en base. L'interface admin affiche les permissions depuis la base, toujours en phase avec le code.

**Synchronisation code → base** : `rails permissions:sync`
- Parcourt toutes les classes dans `app/graphql/mutations/` et `app/graphql/queries/`
- Pour chaque classe ayant `permission_required`, upsert la `Permission` en base (name + description dérivée du nom de classe)
- Les permissions en base qui n'existent plus dans le code sont marquées `deprecated: true` (pas supprimées pour préserver l'historique)
- Idempotente : peut être lancée plusieurs fois sans effet de bord
- Lancée uniquement via `db:seed` ou explicitement — jamais au boot (comme `db:migrate`)
- Tout ajout de `permission_required` dans le code doit être suivi de `rails permissions:sync`

**Mapping GraphQL → permission** :
| Opération GraphQL | Permission requise |
|---|---|
| `query { users }` | `users:read` |
| `query { user }` | `users:read` |
| `mutation { updateUser }` | `users:write` |
| `query { apiTokens }` | `tokens:read` |
| `query { verifyToken }` | `tokens:read` |
| `mutation { createApiToken }` | `tokens:write` |
| `mutation { revokeApiToken }` | `tokens:write` |
| `mutation { login }` | public (pas de permission) |

**Auth JWT vs token API** :
- Session web (JWT) → Action Policy utilise les permissions du **rôle** de l'utilisateur
- Token API → Action Policy utilise les permissions du **token** (sous-ensemble du rôle)
- Dans les deux cas, le GraphQL controller injecte `current_user` et `current_token` dans le contexte

**Questions ouvertes** :
- Token créé sans aucune permission sélectionnée → accès refusé à tout (permissions vides = aucun droit)
- Erreur GraphQL en cas de permission manquante → erreur explicite `NOT_AUTHORIZED` (pas de masquage silencieux)

---

### Story 1 — Modèle de données Permission [⌛ To create in n8n_worker project]
Sachant que les accès GraphQL doivent être contrôlés par des permissions associées aux rôles
Afin d'établir les fondations du système d'autorisation
En tant que développeur
Je veux :
- Migration : table `permissions` (name:string unique, description:string, deprecated:boolean default false)
- Migration : table `role_permissions` (role_id, permission_id — index unique sur la paire)
- Migration : table `api_token_permissions` (api_token_id, permission_id — index unique sur la paire)
- Modèle `Permission` avec validations (name présent, unique, format `resource:action`)
- Modèle `RolePermission` et `ApiTokenPermission` (join models)
- Relation `Role has_many :permissions, through: :role_permissions`
- Relation `ApiToken has_many :permissions, through: :api_token_permissions`
- Validation dans `ApiToken` : `permissions ⊆ user.role.permissions`

**Tests à écrire** (`spec/models/`) :
- `Permission` : validations (name présent, unique, format `resource:action`, rejet d'un format invalide)
- `Role` : `has_many :permissions through role_permissions`
- `ApiToken` : `has_many :permissions through api_token_permissions`
- `ApiToken` : validation rejet si une permission choisie n'appartient pas au rôle
- `ApiToken` : validation accepte un sous-ensemble valide
- `ApiToken` : validation accepte zéro permission (token sans droit)
- Factory `permission` avec traits (`users_read`, `users_write`, `tokens_read`, `tokens_write`)

### Story 2 — Rake task `permissions:sync` [⌛ To create in n8n_worker project]
Sachant que les permissions sont déclarées dans le code via `permission_required`
Afin de maintenir la base de données en phase avec le code automatiquement
En tant que développeur
Je veux une tâche Rake `rails permissions:sync` qui :
- Scanne `app/graphql/mutations/**/*.rb` et `app/graphql/queries/**/*.rb`
- Pour chaque classe ayant `permission_required "resource:action"`, upsert la `Permission` en base
- Marque `deprecated: true` les permissions en base absentes du code (sans les supprimer)
- Est idempotente (plusieurs exécutions = même résultat)
- Est appelée par `db:seed` (uniquement)
- N'est jamais lancée automatiquement au boot — c'est une action explicite, comme `db:migrate`
- Affiche un résumé : N créées, N mises à jour, N dépréciées

**Tests à écrire** (`spec/lib/tasks/`) :
- Lance le scan et crée les permissions manquantes en base
- Ne duplique pas une permission déjà existante (idempotence)
- Marque `deprecated: true` une permission en base qui n'est plus dans le code
- Ne modifie pas une permission déjà à jour
- Le résumé affiche les bonnes métriques

### Story 3 — Intégration Action Policy [⌛ To create in n8n_worker project]
Sachant que les permissions sont modélisées et synchronisées
Afin de les appliquer sur chaque opération GraphQL
En tant que développeur
Je veux :
- Ajouter les gems `action_policy` et `action_policy-graphql`
- `ApplicationPolicy` de base avec le contexte (`current_user`, `current_token`)
- `UserPolicy` : règles `read?` (vérifie `users:read`) et `write?` (vérifie `users:write`)
- `ApiTokenPolicy` : règles `read?` (`tokens:read`) et `write?` (`tokens:write`)
- Helper `active_permissions` dans le contexte : retourne `token.permissions` si auth token, sinon `user.role.permissions`
- Chaque query/mutation protégée via `authorized?` dans le type GraphQL
- Erreur `NOT_AUTHORIZED` retournée explicitement si permission manquante

**Tests à écrire** (`spec/graphql/`) :
- Query `users` : succès avec `users:read`, refus sans
- Query `user` : succès avec `users:read`, refus sans
- Mutation `updateUser` : succès avec `users:write`, refus sans
- Query `apiTokens` : succès avec `tokens:read`, refus sans
- Query `verifyToken` : succès avec `tokens:read`, refus sans
- Mutation `createApiToken` : succès avec `tokens:write`, refus sans
- Mutation `revokeApiToken` : succès avec `tokens:write`, refus sans
- Mutation `login` : succès sans aucune permission (public)
- Auth JWT : utilise les permissions du rôle
- Auth token API : utilise les permissions du token
- Token sans permissions : toutes les opérations protégées retournent `NOT_AUTHORIZED`
- Format de l'erreur : `{ "errors": [{ "message": "NOT_AUTHORIZED", "extensions": { "code": "UNAUTHORIZED" } }] }`

### Story 4 — Interface admin des rôles et permissions [⌛ To create in n8n_worker project]
Sachant que les permissions sont gérées dynamiquement depuis le code
Afin de permettre à un administrateur d'assigner des permissions aux rôles
En tant qu'administrateur
Je veux :
- Une interface web (`/admin/roles`) listant les rôles avec leurs permissions assignées
- Pour chaque rôle, une page d'édition affichant toutes les permissions disponibles (non dépréciées) avec des cases à cocher
- La sauvegarde met à jour la table `role_permissions`
- Les permissions dépréciées sont visibles mais grisées (non sélectionnables)
- L'accès à `/admin/*` est réservé aux utilisateurs ayant le rôle `admin`

**Tests à écrire** (`spec/requests/admin/` et `spec/system/`) :
- GET `/admin/roles` : liste les rôles (auth admin requise, redirect sinon)
- GET `/admin/roles/:id/edit` : affiche les permissions disponibles avec état coché/décoché
- PATCH `/admin/roles/:id` : met à jour les permissions du rôle
- Les permissions dépréciées apparaissent grisées
- Un non-admin est redirigé

### Story 5 — Interface de sélection des permissions à la création de token [⌛ To create in n8n_worker project]
Sachant que les tokens ne peuvent disposer que d'un sous-ensemble des permissions du rôle
Afin de permettre à un utilisateur de choisir ce sous-ensemble à la création
En tant qu'utilisateur connecté
Je veux :
- Le formulaire de création de token affiche uniquement les permissions du rôle de l'utilisateur connecté
- Les permissions sont présentées comme des cases à cocher groupées par ressource
- La validation côté serveur rejette toute permission hors du rôle (sécurité)
- La page de détail d'un token (`show`) affiche les permissions assignées

**Tests à écrire** (`spec/requests/` et `spec/views/`) :
- Le formulaire n'affiche que les permissions du rôle de l'utilisateur courant
- La soumission avec une permission hors rôle retourne 422
- La soumission avec un sous-ensemble valide crée le token avec ses permissions
- La vue `show` liste les permissions du token

### Story 6 — Vérification par requête et logging [⌛ To create in n8n_worker project]
Sachant que chaque requête GraphQL authentifiée par token doit être tracée
Afin d'auditer les accès et de maintenir `last_used_at` à jour
En tant que développeur
Je veux :
- Mise à jour de `last_used_at` du token à chaque requête authentifiée par token API (déjà partiellement implémenté)
- Log structuré pour chaque refus d'accès : timestamp, opération GraphQL, user_id, token_id, permission manquante
- Log structuré pour chaque accès autorisé par token : timestamp, opération, token_id

**Tests à écrire** (`spec/requests/`) :
- `last_used_at` est mis à jour après une requête GraphQL authentifiée par token
- Un refus produit une entrée dans les logs avec les bons champs
- Un accès autorisé produit une entrée dans les logs

### Story 7 — Documentation des permissions [⌛ To create in n8n_worker project]
Sachant que des développeurs externes utiliseront l'API avec des tokens
Afin de faciliter l'intégration
En tant que développeur
Je veux mettre à jour `contributing.md` et `README.md` avec :
- La liste des permissions disponibles et leur correspondance GraphQL
- Le workflow d'ajout d'une nouvelle permission (déclarer `permission_required`, lancer `rails permissions:sync`)
- Des exemples de requêtes GraphQL avec les headers d'authentification requis

---

## Backlog — corrections issues de la revue de code

### [SÉCURITÉ — CRITIQUE] Timing attack sur la vérification de token [⌛]
`app/models/api_token.rb` — méthode `find_by_token`
La comparaison du digest SHA256 passe par une requête SQL ordinaire, exposant l'application à une attaque par timing.
- Remplacer par `ActiveSupport::SecurityUtils.secure_compare` pour comparer les digests en temps constant
- Ou migrer vers un stockage bcrypt (plus lourd, trade-off à évaluer)
- Ajouter un test qui vérifie que deux tokens au digest différent ne produisent pas de timing observable

### [SÉCURITÉ — MOYEN] CSRF non protégé sur les mutations GraphQL [⌛]
`app/controllers/graphql_controller.rb` — `protect_from_forgery with: :null_session`
La protection CSRF est désactivée globalement. Un utilisateur connecté via session web est vulnérable.
- Appliquer `protect_from_forgery with: :exception` par défaut
- Passer en `null_session` uniquement quand la requête porte un header `Authorization` (token API)

### [BUG] Cascade incomplète lors de la réaffectation des permissions d'un rôle [⌛]
`app/models/role.rb` — callback `after_remove` sur `has_many :permissions`
Le callback `after_remove` se déclenche pour `role.permissions.delete(perm)` mais **pas** pour `role.permission_ids = [...]` (bulk assignment), ni pour `role.permissions = [...]`.
Or `UpdateRolePermissions` utilise une réaffectation complète.
- Vérifier le comportement exact de la mutation `updateRolePermissions`
- Si la cascade ne se déclenche pas, implémenter une diff manuelle (permissions retirées = cascade)
- Ajouter un test couvrant le cas `role.permissions = [other_perm]`

### [BUG] Permissions dépréciées exposées dans le type GraphQL `RoleType` [⌛]
`app/graphql/types/role_type.rb` — champ `permissions`
Le champ retourne toutes les permissions du rôle y compris les dépréciées, contrairement à la query `permissions` qui les filtre.
- Filtrer `deprecated: false` dans le resolver du champ, ou ajouter un scope par défaut
- Ajouter un test qui vérifie qu'une permission dépréciée n'apparaît pas dans `role { permissions }`

### [QUALITÉ] Filtrage des permissions dupliqué en 4 endroits [⌛]
La logique `user.role.permissions.where(deprecated: false).pluck(:id).to_set` est copiée dans :
- `mutations/create_api_token.rb`
- `mutations/update_api_token_permissions.rb`
- `controllers/api/v1/tokens_controller.rb`
- `controllers/admin/roles_controller.rb`
- Extraire dans une méthode `User#assignable_permissions` (ou scope `Permission.assignable_for(user)`)
- Mettre à jour les 4 appelants

### [QUALITÉ] `test_field` toujours présent dans `QueryType` [⌛]
`app/graphql/types/query_type.rb`
Le champ `test_field` avec son commentaire `# TODO: remove me` est exposé en production.
- Supprimer le champ et son test associé

### [QUALITÉ] `resolve_type` non implémenté dans le schema [⌛]
`app/graphql/n8n_worker_schema.rb`
Le `TODO: Implement this method` lève une `RequiredImplementationMissingError` si une Union ou Interface est ajoutée.
- Soit implémenter, soit supprimer le stub et laisser graphql-ruby gérer le défaut
- Documenter l'intention

### [QUALITÉ] Magic number 30 jours dupliqué [⌛]
La valeur `30` (durée d'expiration par défaut d'un token) est hardcodée dans :
- `app/models/api_token.rb`
- `app/graphql/mutations/create_api_token.rb`
- `app/controllers/api/v1/tokens_controller.rb`
- Extraire en `ApiToken::DEFAULT_EXPIRATION_DAYS = 30` et remplacer les 3 usages

### [QUALITÉ] `define_singleton_method` sur une instance ActiveRecord [⌛]
`app/models/api_token.rb` + `app/graphql/mutations/create_api_token.rb`
Patcher dynamiquement une instance de modèle est fragile (cache, sérialisation, `dup`).
- Remplacer par un objet valeur simple (ex: struct `TokenResult`) ou retourner le raw_token directement comme attribut du résultat de mutation

### [PERFORMANCE] N+1 potentiel dans la vue admin roles [⌛]
`app/views/admin/roles/index.html.erb`
Le template appelle `role.permissions.order(:name)` sur chaque rôle. Même avec `includes(:permissions)`, le `.order` SQL force une requête par rôle.
- Remplacer `role.permissions.order(:name)` par `role.permissions.sort_by(&:name)` dans la vue
- Ou eager-loader les permissions triées depuis le controller

### [TESTS] Cascade non couverte par réaffectation de permissions [⌛]
`spec/models/role_permission_spec.rb`
Seul `role.permissions.delete(perm)` est testé. Aucun test pour `role.permissions = [other_perm]`.
- Ajouter un exemple couvrant la réaffectation complète
- Vérifier que les tokens perdent bien les permissions retirées dans ce cas

### [TESTS] Aucun test d'isolation entre utilisateurs dans le contrôleur REST tokens [⌛]
`spec/requests/api/v1/tokens_spec.rb`
Les actions `revoke`, `renew`, `destroy` ne vérifient pas qu'un utilisateur ne peut pas agir sur les tokens d'un autre.
- Ajouter un test : user A ne peut pas révoquer/renouveler/supprimer le token de user B
- Vérifier que la réponse est 404 (pas une fuite d'information)

### [TESTS] Comportement de `verifyToken` avec un token expiré non spécifié [⌛]
`spec/graphql/queries/verify_token_spec.rb`
Un token expiré — retourne-t-il `null` ou une erreur ? Comportement non testé ni documenté.
- Décider du comportement attendu
- Ajouter un test explicite pour un token expiré

### [MINEUR] Seed token créé sans aucune permission [⌛]
`db/seeds.rb`
Le `Seed Token` créé pour le compte admin n'a aucune permission assignée — il est inutilisable pour tester l'API directement.
- Assigner toutes les permissions du rôle admin au seed token, ou documenter que c'est intentionnel