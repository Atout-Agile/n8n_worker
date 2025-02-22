# frozen_string_literal: true

FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "role_#{n}" }
    description { "Description pour #{name}" }

    trait :admin do
      name { 'admin' }
      description { 'Administrateur système' }
    end

    trait :user do
      name { 'user' }
      description { 'Utilisateur standard' }
    end
  end
end 