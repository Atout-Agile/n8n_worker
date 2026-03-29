# frozen_string_literal: true

FactoryBot.define do
  factory :permission do
    sequence(:name) { |n| "resource#{('a'.ord + n % 26).chr}:read" }
    description { "Permission for #{name}" }
    deprecated { false }

    trait :users_read do
      name { "users:read" }
      description { "Read access to users" }
    end

    trait :users_write do
      name { "users:write" }
      description { "Write access to users" }
    end

    trait :tokens_read do
      name { "tokens:read" }
      description { "Read access to API tokens" }
    end

    trait :tokens_write do
      name { "tokens:write" }
      description { "Write access to API tokens" }
    end

    trait :deprecated do
      deprecated { true }
    end
  end
end
