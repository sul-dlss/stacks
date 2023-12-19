# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StacksMediaStream do
  let(:instance) { StacksMediaStream.new(id: 'bc123gg2323') }

  describe '#id' do
    subject { instance.id }

    it { is_expected.to eq 'bc123gg2323' }
  end
end
