# frozen_string_literal: true

RSpec.configure do |config|
  config.after(:each, type: :system) do |example|
    if example.exception
      take_screenshot
    end
  end

  private

  def take_screenshot
    time_now = Time.current.strftime('%Y%m%d%H%M%S')
    screenshot_name = "screenshot-#{time_now}.png"
    page.save_screenshot(Rails.root.join("tmp/screenshots/#{screenshot_name}"))
  end
end 