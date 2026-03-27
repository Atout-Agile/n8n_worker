# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# frozen_string_literal: true

# Nettoyer les données existantes
puts "Nettoyage des données existantes..."
ApiToken.destroy_all
User.destroy_all
Role.destroy_all

# Create default roles (only if they don't exist yet)
puts "Setting up default roles..."

# Admin role
unless Role.exists?(name: 'admin')
  Role.create!(
    name: 'admin',
    description: 'Administrator with full access'
  )
  puts "- 'admin' role created"
else
  puts "- 'admin' role already exists"
end

# Standard user role
unless Role.exists?(name: 'user')
  Role.create!(
    name: 'user',
    description: 'Standard user'
  )
  puts "- 'user' role created"
else
  puts "- 'user' role already exists"
end

# Create initial admin account (only if no admin exists)
admin_email = 'admin@example.com'

unless User.exists?(email: admin_email)
  admin_role = Role.find_by(name: 'admin')
  
  if admin_role
    User.create!(
      name: 'Administrator',
      email: admin_email,
      password: 'changeme123', # Should be changed after first login
      role: admin_role
    )
    puts "Initial administrator account created:"
    puts "- Email: #{admin_email}"
    puts "- Password: changeme123"
    puts "IMPORTANT: Please change this password after your first login!"
  else
    puts "ERROR: Could not create admin account because 'admin' role does not exist."
  end
else
  puts "An administrator account already exists with email: #{admin_email}"
end

# Create a seed API token for the admin account
admin = User.find_by(email: admin_email)

if admin
  raw_token = SecureRandom.hex(32)
  token = admin.api_tokens.create!(
    name: 'Seed Token',
    token_digest: Digest::SHA256.hexdigest(raw_token),
    expires_at: 3.days.from_now
  )
  puts "Admin API token created:"
  puts "- Name:    #{token.name}"
  puts "- Token:   #{raw_token}"
  puts "- Expires: #{token.expires_at.strftime('%Y-%m-%d')}"
  puts "IMPORTANT: This token is only shown once — save it now!"
else
  puts "ERROR: Could not create API token — admin account not found."
end

puts "Initial setup completed."
