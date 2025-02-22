# frozen_string_literal: true

module Api::V1::TokensHelper
  def format_token_expiration(date)
    return '-' if date.nil?
    date.strftime('%d/%m/%Y %H:%M')
  end
end
