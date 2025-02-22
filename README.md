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
- Ruby 3.3.5
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
```

## Tests

### Lancer la suite de tests
```bash
# Avec couverture de code
rake test:coverage
```

Les rapports de couverture sont générés dans `coverage/`.
Les captures d'écran des tests échoués sont dans `tmp/screenshots/`.

## API GraphQL

### Authentification
L'API utilise JWT pour l'authentification. Pour obtenir un token :

```graphql
mutation {
  login(input: {
    email: "user@example.com",
    password: "password"
  }) {
    token
    user {
      id
      email
    }
    errors
  }
}
```

### Utilisation
Inclure le token dans le header Authorization :
```bash
Authorization: Bearer <votre_token>
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



