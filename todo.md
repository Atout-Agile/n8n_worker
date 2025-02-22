# Todo

## Tests d'intégration GraphQL existants

### Test d'intégration Login
Sachant que la mutation Login est déjà implémentée
Afin de garantir son bon fonctionnement de bout en bout
En tant que Quality Assurance
Je veux créer un test système qui vérifie :
- Le formulaire de login avec email/password
- L'affichage des erreurs de validation
- La redirection après connexion réussie
- Le stockage du token dans le localStorage

### Test d'intégration Authentification
Sachant que l'authentification JWT est implémentée
Afin de garantir la sécurité de l'application
En tant que Quality Assurance
Je veux créer un test système qui vérifie :
- L'accès aux routes protégées avec un token valide
- Le refus d'accès avec un token invalide
- La gestion de l'expiration des tokens
- La déconnexion et la suppression du token

### Test d'intégration ApiToken
Sachant que la gestion des tokens API est implémentée
Afin de garantir la gestion des accès API
En tant que Quality Assurance
Je veux créer un test système qui vérifie :
- La création d'un nouveau token
- L'affichage de la liste des tokens
- La révocation d'un token
- L'expiration automatique des tokens

## GraphQL Queries

### User Query
Sachant que l'application stocke les informations des utilisateurs
Afin de pouvoir afficher les détails d'un utilisateur spécifique
En tant que développeur de l'application
Je veux créer une query GraphQL qui retourne les informations d'un utilisateur par son ID ou email

### User Tokens Query
Sachant que chaque utilisateur peut avoir plusieurs tokens API
Afin de permettre la gestion des accès API
En tant que développeur de l'application
Je veux créer une query GraphQL qui liste tous les tokens actifs d'un utilisateur

### Token Verification Query
Sachant que les tokens API doivent être validés avant utilisation
Afin de sécuriser l'accès à l'API
En tant que développeur de l'application
Je veux créer une query GraphQL qui vérifie la validité d'un token et retourne ses informations

## GraphQL Mutations

### Create API Token
Sachant que les utilisateurs ont besoin de tokens pour accéder à l'API
Afin de permettre la génération sécurisée de nouveaux tokens
En tant que développeur de l'application
Je veux créer une mutation GraphQL qui génère un nouveau token API avec une date d'expiration

### Revoke API Token
Sachant que les tokens compromis doivent pouvoir être révoqués
Afin de maintenir la sécurité de l'API
En tant que développeur de l'application
Je veux créer une mutation GraphQL qui révoque immédiatement un token API existant

### Update User
Sachant que les informations des utilisateurs peuvent changer
Afin de maintenir les données à jour
En tant que développeur de l'application
Je veux créer une mutation GraphQL qui permet de mettre à jour les informations d'un utilisateur

## Tests d'intégration

### Authentication Flow
Sachant que l'authentification est critique pour la sécurité
Afin de garantir le bon fonctionnement du processus d'authentification
En tant que Quality Assurance
Je veux créer des tests qui vérifient le flow complet : login, génération de token, utilisation, expiration

### API Token Lifecycle
Sachant que les tokens API ont un cycle de vie complet
Afin de garantir leur bon fonctionnement
En tant que Quality Assurance
Je veux créer des tests qui vérifient la création, l'utilisation, la révocation et l'expiration des tokens

### Permission Errors
Sachant que l'accès aux ressources doit être contrôlé
Afin de garantir la sécurité de l'application
En tant que Quality Assurance
Je veux créer des tests qui vérifient que les erreurs de permission sont correctement gérées

## Helpers et Vues

### Additional Helpers
Sachant que le formatage des données est important pour l'interface utilisateur
Afin d'améliorer l'expérience utilisateur
En tant que développeur de l'application
Je veux créer des helpers supplémentaires pour le formatage des dates, statuts et autres données

### View Testing
Sachant que les vues doivent fonctionner dans différents scénarios
Afin de garantir une expérience utilisateur cohérente
En tant que développeur de l'application
Je veux créer des tests qui vérifient le rendu des vues dans différentes situations (succès, erreur, données manquantes) 