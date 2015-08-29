require 'rails_helper'

describe ApplicationController do
  describe 'squash shims' do
    it 'supports flash messages' do
      expect(controller.send(:flash)).to be_a_kind_of Hash
    end

    it 'supports cookies' do
      expect(controller.send(:cookies)).to be_a_kind_of Hash
    end
  end
end
