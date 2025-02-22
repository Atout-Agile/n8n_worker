# frozen_string_literal: true

require 'capybara/rspec'
require 'capybara/cuprite'

Capybara.javascript_driver = :cuprite
Capybara.default_driver = :cuprite

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [1200, 800],
    # Augmente les timeouts pour les environnements CI plus lents
    timeout: 10,
    process_timeout: 10,
    # Active le debugging si nécessaire
    inspector: ENV['INSPECTOR'],
    # Configurations additionnelles de Chrome
    browser_options: { 'no-sandbox': nil }
  )
end

# Helper methods pour le debugging
module CupriteHelpers
  def pause
    page.driver.pause
  end

  def debug(*args)
    page.driver.debug(*args)
  end
end

RSpec.configure do |config|
  config.include CupriteHelpers, type: :system
end 