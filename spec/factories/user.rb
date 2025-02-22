# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { 'password123' }
    association :role, factory: %i[role user]

    trait :admin do
      association :role, factory: %i[role admin]
    end

    trait :with_api_token do
      after(:create) do |user|
        create(:api_token, user: user)
      end
    end
  end
end 