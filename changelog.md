# Changelog

## [2024-02-22--0001]

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

## [2024-02-22--0002]

### Configuration du framework de test

- À venir :
  - Configuration complète de RSpec
  - Mise en place des factories avec FactoryBot
  - Tests des modèles
  - Tests des mutations GraphQL
  - Tests d'intégration
