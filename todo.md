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

### Token Verification Query 
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

## Gestion des Tokens API [⌛ To create in n8n_worker project]

### Modèle de Permissions API [⌛ To create in n8n_worker project]
Sachant que les tokens API doivent avoir des permissions spécifiques
Afin de contrôler finement l'accès aux endpoints GraphQL
En tant qu'administrateur système
Je veux :
- Un modèle Permission avec un nom et une description
- Une table de liaison api_token_permissions
- Une liste des permissions disponibles dans l'application
- Des validations pour s'assurer que les permissions sont valides

### Enrichissement du modèle ApiToken [⌛ To create in n8n_worker project]
Sachant que les tokens API existants doivent supporter les permissions
Afin de gérer les droits d'accès à l'API
En tant qu'administrateur système
Je veux :
- Ajouter la relation avec les permissions
- Ajouter la génération de JWT avec les permissions
- Ajouter la validation des permissions lors de la création
- Stocker la date de dernière utilisation du token

### Interface d'Administration des Tokens API [⌛ To create in n8n_worker project]
Sachant que les tokens API doivent être gérés par les administrateurs
Afin de permettre la création et gestion des tokens
En tant qu'administrateur
Je veux :
- Une interface pour créer des tokens API
- La possibilité de sélectionner les permissions
- La possibilité de révoquer un token
- La visualisation des tokens existants et leur utilisation

### Middleware de Vérification des Permissions API [⌛ To create in n8n_worker project]
Sachant que les requêtes GraphQL doivent respecter les permissions des tokens
Afin de sécuriser l'accès à l'API
En tant que développeur
Je veux :
- Un middleware qui vérifie les permissions du token
- Une gestion des erreurs claire pour les permissions invalides
- Une mise à jour de la date de dernière utilisation
- Des logs détaillés des accès et refus

### Documentation des Tokens API [⌛ To create in n8n_worker project]
Sachant que les développeurs externes utiliseront l'API
Afin de faciliter l'intégration
En tant que développeur
Je veux :
- Une documentation claire des permissions disponibles
- Des exemples d'utilisation des tokens
- Une explication du format des JWT
- Un guide de bonnes pratiques pour la gestion des tokens 