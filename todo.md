# Todo

## Ordre d'implémentation

1. **User Query** [✓ Created in project n8n_worker]
Sachant que l'application stocke les informations des utilisateurs
Afin de pouvoir afficher les détails d'un utilisateur spécifique
En tant que développeur de l'application
Je veux créer une query GraphQL qui retourne les informations d'un utilisateur par son ID ou email

2. **Test système: Login** [✓ Created in project n8n_worker]
Sachant que la mutation Login est déjà implémentée
Afin de garantir son bon fonctionnement de bout en bout
En tant que Quality Assurance
Je veux créer un test système qui vérifie :
- Le formulaire de login avec email/password
- L'affichage des erreurs de validation
- La redirection après connexion réussie
- Le stockage du token dans le localStorage

3. **Test système: Authentification JWT** [✓ Created in project n8n_worker]
Sachant que l'authentification JWT est implémentée
Afin de garantir la sécurité de l'application
En tant que Quality Assurance
Je veux créer un test système qui vérifie :
- L'accès aux routes protégées avec un token valide
- Le refus d'accès avec un token invalide
- La gestion de l'expiration des tokens
- La déconnexion et la suppression du token

4. **Mutation: Création de token API** [✓ Created in project n8n_worker]
Sachant que les utilisateurs ont besoin de tokens pour accéder à l'API
Afin de permettre la génération sécurisée de nouveaux tokens
En tant que développeur de l'application
Je veux créer une mutation GraphQL qui génère un nouveau token API avec une date d'expiration

5. **Token Verification Query** [✓ Created in project n8n_worker]
Sachant que les tokens API doivent être validés avant utilisation
Afin de sécuriser l'accès à l'API
En tant que développeur de l'application
Je veux créer une query GraphQL qui vérifie la validité d'un token et retourne ses informations

6. **User Tokens Query** [✓ Created in project n8n_worker]
Sachant que chaque utilisateur peut avoir plusieurs tokens API
Afin de permettre la gestion des accès API
En tant que développeur de l'application
Je veux créer une query GraphQL qui liste tous les tokens actifs d'un utilisateur

7. **Mutation: Révocation de token API** [✓ Created in project n8n_worker]
Sachant que les tokens compromis doivent pouvoir être révoqués
Afin de maintenir la sécurité de l'API
En tant que développeur de l'application
Je veux créer une mutation GraphQL qui révoque immédiatement un token API existant

8. **Test d'intégration: Cycle de vie des tokens API** [✓ Created in project n8n_worker]
Sachant que les tokens API ont un cycle de vie complet
Afin de garantir leur bon fonctionnement
En tant que Quality Assurance
Je veux créer des tests qui vérifient la création, l'utilisation, la révocation et l'expiration des tokens

9. **Test d'intégration: Flow d'authentification** [✓ Created in project n8n_worker]
Sachant que l'authentification est critique pour la sécurité
Afin de garantir le bon fonctionnement du processus d'authentification
En tant que Quality Assurance
Je veux créer des tests qui vérifient le flow complet : login, génération de token, utilisation, expiration

10. **Test d'intégration: Gestion des erreurs de permission** [✓ Created in project n8n_worker]
Sachant que l'accès aux ressources doit être contrôlé
Afin de garantir la sécurité de l'application
En tant que Quality Assurance
Je veux créer des tests qui vérifient que les erreurs de permission sont correctement gérées

11. **Mutation: Mise à jour utilisateur** [✓ Created in project n8n_worker]
Sachant que les informations des utilisateurs peuvent changer
Afin de maintenir les données à jour
En tant que développeur de l'application
Je veux créer une mutation GraphQL qui permet de mettre à jour les informations d'un utilisateur

12. **Helpers: Formatage des données** [✓ Created in project n8n_worker]
Sachant que le formatage des données est important pour l'interface utilisateur
Afin d'améliorer l'expérience utilisateur
En tant que développeur de l'application
Je veux créer des helpers supplémentaires pour le formatage des dates, statuts et autres données

13. **Tests: Vues et rendu** [✓ Created in project n8n_worker]
Sachant que les vues doivent fonctionner dans différents scénarios
Afin de garantir une expérience utilisateur cohérente
En tant que développeur de l'application
Je veux créer des tests qui vérifient le rendu des vues dans différentes situations (succès, erreur, données manquantes) 