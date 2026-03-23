# Mutations GraphQL

Liste des mutations disponibles pour modifier les données.

## Authentication
- Login : permet de s'authentifier et récupérer un token

## API Tokens
- CreateApiToken : crée un nouveau token d'API avec une date d'expiration
- RevokeApiToken : révoque immédiatement un token existant (expire_at = now)
