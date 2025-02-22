# frozen_string_literal: true

require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the Api::V1::TokensHelper. For example:
#
# describe Api::V1::TokensHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe Api::V1::TokensHelper, type: :helper do
  describe '#format_token_expiration' do
    it 'formats expiration date' do
      date = Time.zone.parse('2024-02-22 14:30:00')
      expect(helper.format_token_expiration(date)).to eq('22/02/2024 14:30')
    end

    it 'handles nil date' do
      expect(helper.format_token_expiration(nil)).to eq('-')
    end
  end
end
