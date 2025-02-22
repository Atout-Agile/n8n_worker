# Changelog

## [2025-02-22--0001]

### Création du projet

- Création d'une nouvelle application Rails 8

```bash
rails new n8n_worker
```

### Configuration de la base de données

- Initialisation de la base de données

```bash
rails db:create
rails db:prepare
```

### Configuration de la base de données

```bash
rails db:migrate
```

### Installation des dépendances

- Ajout de Kamal pour le déploiement
- Ajout de GraphQL pour la communication avec n8n (et autres services)

```bash
bundle add kamal
bundle add graphql
```

### Configuration de GraphQL

- Création du schéma GraphQL

```bash
rails g graphql:install
```

### Configuration de l'environnement de développement

- Installation de RSpec pour les tests
- Configuration de GraphiQL pour tester l'API

```bash
bundle add rspec-rails --group "development, test"
bundle add graphiql-rails
rails generate rspec:install
```

### Création des types GraphQL

- Création du type Job pour gérer les tâches
- Création de la mutation CreateJob

```bash
rails g graphql:object Job id:ID! status:String! data:String created_at:DateTime! updated_at:DateTime!
rails g graphql:mutation CreateJob
```

### Configuration des variables d'environnement

- Installation de dotenv pour la gestion des secrets
- Création des fichiers de configuration des variables d'environnement
  - Création du fichier `.env.example` avec les variables par défaut
  - Création du fichier `.env` pour l'environnement local

```bash
bundle add dotenv-rails
```

### Configuration de l'authentification

- Installation de JWT pour l'authentification des requêtes API
- Choix de JWT pour :
  - La standardisation (RFC 7519)
  - La compatibilité native avec n8n
  - La flexibilité des tokens (expiration, claims)
  - La sécurité intégrée (signature cryptographique)

```bash
bundle add jwt
```

- Configuration des variables d'environnement pour JWT
  - Ajout de JWT_SECRET_KEY
  - Ajout de JWT_EXPIRATION

```bash
rails secret
```

- Création de la structure pour l'authentification JWT

```bash
mkdir -p app/lib/jwt
```

- Création du service JWT pour l'encodage/décodage des tokens

```bash
touch app/lib/jwt/json_web_token.rb
```

- Suppression du middleware d'authentification au profit d'une intégration dans le contrôleur GraphQL
  - Meilleure intégration avec GraphQL
  - Plus simple à maintenir
  - Meilleur accès au contexte GraphQL
  - Plus cohérent avec l'architecture Rails

```bash
rm app/lib/jwt/authenticate_graphql_request.rb
```

- Création du contrôleur pour la génération des tokens

```bash
rails g controller api/v1/tokens create
```

- Création du modèle pour gérer les tokens API

```bash
rails g model ApiToken name:string token_digest:string last_used_at:datetime expires_at:datetime
```

- Application de la migration pour la table api_tokens

```bash
rails db:migrate
```

- Implémentation du service JWT dans le fichier `app/lib/jwt/json_web_token.rb`
  - Utilisation d'une classe singleton pour les méthodes d'encodage/décodage
  - Gestion automatique de l'expiration des tokens via JWT_EXPIRATION
  - Support du format '24h' pour la configuration de l'expiration
  - Gestion des erreurs spécifiques JWT (token invalide, expiré)
  - Utilisation de HashWithIndifferentAccess pour un accès simplifié aux données du payload

- Implémentation de l'authentification dans le contrôleur GraphQL
  - Intégration de la vérification du token dans le contexte GraphQL
  - Gestion de l'authentification au niveau du contrôleur
  - Support de GraphiQL en développement
  - Transmission du payload JWT au contexte GraphQL

### Configuration des utilisateurs

- Création du modèle Role pour la gestion des permissions
  - Champ name pour identifier le rôle
  - Champ description pour décrire les permissions

```bash
rails g model Role name:string description:string
```

- Création du modèle User avec relation au Role
  - Champ name pour le nom de l'utilisateur
  - Champ email unique pour l'identification
  - Relation belongs_to avec Role

```bash
rails g model User name:string email:string:uniq role:references
```

- Ajout de la gestion sécurisée des mots de passe
  - Installation de bcrypt pour le hachage des mots de passe
  - Ajout du champ password_digest pour les users
  - Configuration de has_secure_password

```bash
bundle add bcrypt
rails g migration AddPasswordDigestToUsers password_digest:string
```

### Configuration de l'authentification des utilisateurs

- Création de la mutation Login pour l'authentification GraphQL
  - Accepte email et password
  - Retourne un token JWT si les credentials sont valides
  - Gère les erreurs d'authentification

```bash
rails g graphql:mutation Login
```

- Documentation du processus d'authentification :

1. Authentification initiale via GraphQL :
```graphql
mutation {
  login(input: {
    email: "user@example.com",
    password: "secret123"
  }) {
    token
    user {
      id
      email
      name
    }
    errors
  }
}
```

2. Réponse en cas de succès :
```json
{
  "data": {
    "login": {
      "token": "eyJhbGciOiJIUzI1NiJ9...",
      "user": {
        "id": "1",
        "email": "user@example.com",
        "name": "John Doe"
      },
      "errors": []
    }
  }
}
```

3. Utilisation du token pour les requêtes suivantes :
```bash
curl -X POST http://localhost:3000/graphql \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..." \
  -H "Content-Type: application/json" \
  -d '{"query": "mutation { createJob(...) { id } }"}'
```

4. Structure du token JWT :
```json
{
  "user_id": 1,
  "email": "user@example.com",
  "role": "admin",
  "exp": 1708722489
}
```

Notes :
- Le token expire après la durée définie dans JWT_EXPIRATION
- Le header Authorization doit suivre le format "Bearer <token>"
- En développement, GraphiQL reste accessible sans authentification
- Les erreurs d'authentification retournent un statut 401

### Initialisation du repository Git

- Création du repository sur GitHub
- Configuration du .gitignore
- Premier commit et push du projet

```bash
git init
git add .
git commit -m "Initial commit - Version [2024-02-22--0001]"
git remote add origin git@github.com:votre-username/n8n_worker.git
git push -u origin main
```

## [2025-02-22--0002]

### Configuration du framework de test

- Installation des gems de test
  - factory_bot_rails : création de données de test
  - faker : génération de données aléatoires réalistes
  - shoulda-matchers : matchers RSpec additionnels
  - rspec-graphql_matchers : matchers spécifiques GraphQL
  - simplecov : couverture de code
  - database_cleaner : nettoyage de la BD entre les tests
  Fichiers modifiés :
  - Gemfile

- Configuration de FactoryBot pour utiliser les méthodes de factory directement dans les tests
  Fichiers modifiés :
  - spec/support/factory_bot.rb

- Configuration de Shoulda Matchers pour les tests de modèles
  Fichiers modifiés :
  - spec/support/shoulda_matchers.rb

- Configuration de SimpleCov pour analyser la couverture de code
  - Exclusion des fichiers de config et des tests
  - Groupement des fichiers par type pour le rapport
  - Configuration spécifique pour les fichiers GraphQL
  Fichiers modifiés :
  - spec/support/simplecov.rb

- Configuration de DatabaseCleaner pour nettoyer la base de données entre les tests
  - Stratégie de transaction par défaut (plus rapide)
  - Basculement automatique vers la troncature pour les tests JS
  - Nettoyage complet de la base avant la suite de tests
  - Nettoyage après chaque test pour isoler les données
  Fichiers modifiés :
  - spec/support/database_cleaner.rb

- Configuration des matchers GraphQL pour tester l'API
  - Support des tests de types GraphQL
  - Validation des champs et arguments
  - Vérification des mutations et queries
  Fichiers modifiés :
  - spec/support/graphql_matchers.rb

- Création des factories pour les tests
  - Factory Role avec des rôles prédéfinis
  - Factory User avec génération de données aléatoires via Faker
  - Factory ApiToken pour les tests d'authentification
  Fichiers modifiés :
  - spec/factories/role.rb
  - spec/factories/user.rb
  - spec/factories/api_token.rb

- Création des tests de modèles
  - Tests des validations et associations
  - Tests des méthodes personnalisées
  - Tests des scopes et callbacks
  Fichiers modifiés :
  - spec/models/role_spec.rb
  - spec/models/user_spec.rb
  - spec/models/api_token_spec.rb

- Création des tests GraphQL
  - Tests de la mutation Login
  - Tests d'authentification
  - Tests des erreurs de validation
  Fichiers modifiés :
  - spec/graphql/mutations/login_spec.rb

- Création des tests du service JWT
  - Tests d'encodage des tokens
  - Tests de décodage des tokens
  - Tests de gestion des erreurs
  Fichiers modifiés :
  - spec/lib/jwt/json_web_token_spec.rb

- Remplacement du script bash par une tâche Rake
  - Création d'une tâche test:coverage
  - Configuration de SimpleCov intégrée
  - Gestion de la base de test via Rake
  - Ouverture automatique du rapport de couverture
  Fichiers modifiés :
  - lib/tasks/test.rake

### Création des types GraphQL pour l'authentification

- Type User avec champs de base et relation Role
- Type Role avec champs de base
- Support des dates au format ISO8601
Fichiers modifiés :
- app/graphql/types/user_type.rb
- app/graphql/types/role_type.rb

### Amélioration du service JWT

- Support de la configuration via variables d'environnement
- Gestion flexible de l'expiration (format '24h')
- Fallback sur secret_key_base si JWT_SECRET_KEY non défini
- Meilleure gestion des erreurs
Fichiers modifiés :
- app/lib/jwt/json_web_token.rb

### Implémentation de l'authentification

- Service JWT pour l'authentification avec gestion des tokens
  - Encodage/décodage des tokens avec expiration configurable
  - Gestion des erreurs spécifiques JWT
- Mutation GraphQL pour le login
  - Retourne token et informations utilisateur
  - Gestion des erreurs d'authentification
- Modèle ApiToken avec validation et scope `active`
  - Validation d'unicité du nom
  - Scope pour filtrer les tokens non expirés
- Helper pour le formatage des dates d'expiration des tokens
  - Format français : DD/MM/YYYY HH:MM
- Vue pour afficher les détails d'un token après création
  - Affichage du nom et de la date d'expiration

### Améliorations et corrections

- Amélioration de la gestion des erreurs JWT
  - Distinction entre token expiré et token invalide
- Optimisation des factories pour éviter les doublons
  - Utilisation de sequences pour les noms uniques
- Correction des problèmes de validation d'unicité des tokens
- Correction des tests de validation d'email case-insensitive

### Documentation

- Ajout d'un fichier todo.md avec les user stories pour les fonctionnalités manquantes
  - Queries GraphQL à implémenter
  - Mutations GraphQL à implémenter
  - Tests d'intégration à créer
  - Helpers et vues à tester

### Configuration des tests système

- Installation de Capybara et Cuprite pour les tests d'interface
  - Capybara pour l'abstraction des tests système
  - Cuprite comme driver utilisant Chrome DevTools Protocol
  Fichiers modifiés :
  - Gemfile

- Configuration de Capybara avec Cuprite
  - Configuration des timeouts et taille de fenêtre
  - Support du debugging avec pause et inspection
  - Helpers pour le debugging
  Fichiers modifiés :
  - spec/support/capybara.rb

- Ajout du support des screenshots automatiques
  - Capture d'écran en cas d'échec des tests
  - Stockage dans tmp/screenshots
  - Format de nom incluant timestamp
  Fichiers modifiés :
  - spec/support/system_test_helpers.rb
  - spec/rails_helper.rb

## [2025-02-22--0003]

### Objectif : Documentation

L'objectif de cette version est de mettre en place une documentation automatique et maintenable qui :
- Se synchronise automatiquement avec le code
- Couvre à la fois les modèles Ruby et l'API GraphQL
- Fournit des exemples d'utilisation à jour

### Configuration de la documentation

- Installation de YARD pour la documentation Ruby
  - Support de Markdown dans les commentaires
  - Génération de documentation HTML
  - Configuration spécifique pour GraphQL
  Fichiers modifiés :
  - Gemfile
  - .yardopts avec les options suivantes :
    * --markup markdown : Utilise la syntaxe Markdown pour les commentaires
    * --markup-provider redcarpet : Utilise Redcarpet comme parser Markdown
    * --protected : Inclut les méthodes protégées dans la documentation
    * --private : Inclut les méthodes privées dans la documentation
    * --embed-mixins : Inclut la documentation des mixins dans les classes
    * --output-dir documentation/yard : Génère la documentation dans ce dossier

- Amélioration du serveur de documentation
  - Serveur YARD en processus séparé pour la doc Ruby
  - Serveur WEBrick personnalisé pour la doc GraphQL
  - Support complet des liens et assets statiques
  - Navigation fonctionnelle dans la documentation GraphQL
  - URLs accessibles depuis WSL et Windows
  - Gestion propre de l'arrêt des serveurs
  Fichiers modifiés :
  - lib/tasks/documentation.rake

- Installation de GraphQL::Docs pour l'API
  - Documentation automatique du schéma
  - Documentation des types et mutations
  - Exemples de requêtes GraphQL
  Fichiers modifiés :
  - Gemfile
  - config/initializers/graphql_docs.rb

- Configuration de la génération de documentation
  - Tâche Rake pour générer la documentation
  - Organisation par type d'objet (ApiToken, User, Role)
  - Mise à jour automatique des exemples
  Fichiers modifiés :
  - lib/tasks/documentation.rake

- Structure de la documentation
  - Création du répertoire /documentation
  - Documentation des modèles
  - Documentation de l'API GraphQL
  - Exemples d'utilisation
  Nouveaux fichiers :
  - documentation/api_token.md
  - documentation/user.md
  - documentation/role.md
  - documentation/index.md

- Mise à jour du README.md
  - Description du projet
  - Instructions d'installation et de configuration
  - Guide d'utilisation de la documentation
  - Exemples d'utilisation de l'API GraphQL
  - Ajout de la licence GPL v3
  Fichiers modifiés :
  - README.md

## [2025-02-22--0004]

### Configuration de la gestion de projet

- Création du projet GitHub "n8n_worker" pour gérer les user stories
  - Utilisation des projets GitHub pour une meilleure visibilité
  - Organisation des tâches en tableau kanban
  - Priorisation des user stories

- Import des user stories depuis le todo.md
  - Création des items dans le projet
  - Organisation logique des dépendances
  - Numérotation des étapes d'implémentation

- Documentation de la gestion de projet
  - Mise à jour du todo.md avec les références au projet
  - Ajout des tags [✓ Created in project n8n_worker]
  - Réorganisation des user stories par ordre d'implémentation

### Objectifs de cette version

L'objectif principal est d'améliorer la gestion du projet en :
- Centralisant les user stories dans un outil dédié
- Facilitant le suivi de l'avancement
- Permettant une meilleure priorisation
- Documentant clairement les dépendances entre tâches

### Notes

La gestion de projet est maintenant configurée pour :
- Suivre l'avancement des développements

## [2025-02-23--0005]

### Ajout de la query User (issue [#16](https://github.com/votre-username/n8n_worker/issues/16) )

- Création de la query GraphQL pour récupérer les informations d'un utilisateur
  - Recherche possible par ID ou email
  - Retourne les champs : id, email, username et role
  - Le champ `name` de la base de données est exposé comme `username` dans l'API

```graphql
# Exemple de query par ID
query {
  user(id: "1") {
    id
    email
    username
    role {
      name
    }
  }
}

# Exemple de query par email
query {
  user(email: "test@example.com") {
    id
    email
    username
    role {
      name
    }
  }
}
```

- Création des fichiers :
  - `app/graphql/queries/base_query.rb` : Classe de base pour les queries
  - `app/graphql/queries/user.rb` : Implémentation de la query user
  - `spec/graphql/queries/user_query_spec.rb` : Tests de la query

- Modification des fichiers :
  - `app/graphql/types/user_type.rb` : Ajout du champ username
  - `app/graphql/types/query_type.rb` : Ajout de la query user
