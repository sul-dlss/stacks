require 'rails_helper'

RSpec.describe StacksController do
  describe 'GET /' do
    it 'is successful' do
      get :index
      expect(response).to be_successful
    end
  end
end
