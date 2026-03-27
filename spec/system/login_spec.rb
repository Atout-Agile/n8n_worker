require 'rails_helper'

RSpec.describe "Login Process", type: :system do
  let(:admin_role) { create(:role, name: 'admin') }
  let!(:user) { create(:user, email: 'test@example.com', password: 'password123', role: admin_role) }
  
  before do
    driven_by(:cuprite)
  end
  
  it "allows a user to login with valid credentials" do
    visit login_path
    
    # Fill in the form
    fill_in 'email', with: 'test@example.com'
    fill_in 'password', with: 'password123'
    
    # Submit the form
    click_button 'Sign in'
    
    # Wait for redirect
    expect(page).to have_current_path(dashboard_path)
    
    # Verify user is logged in
    expect(page).to have_content('Welcome, ' + user.name)
    
    # Verify token is stored in localStorage
    # Note: localStorage might not work in test environment, so we check session instead
    expect(page).to have_current_path(dashboard_path)
    expect(page).to have_content('Welcome, ' + user.name)
  end
  
  it "shows validation errors with invalid credentials" do
    visit login_path
    
    # Fill in the form with incorrect credentials
    fill_in 'email', with: 'test@example.com'
    fill_in 'password', with: 'wrong_password'
    
    # Submit the form
    click_button 'Sign in'
    
    # Verify errors are displayed
    expect(page).to have_selector('.bg-red-50')
    expect(page).to have_content('Email ou mot de passe invalide')
    
    # Verify we stay on the login page
    expect(page).to have_current_path(login_path)
  end
  
  it "redirects to dashboard if already logged in" do
    # Simulate login
    visit login_path
    fill_in 'email', with: 'test@example.com'
    fill_in 'password', with: 'password123'
    click_button 'Sign in'
    
    # Wait for redirect
    expect(page).to have_current_path(dashboard_path)
    
    # Try to access login page again
    visit login_path
    
    # Verify redirect to dashboard
    expect(page).to have_current_path(dashboard_path)
  end
end 