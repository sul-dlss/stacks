# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StacksMediaStream do
  it 'has a format accessor' do
    expect(StacksMediaStream.new(format: 'abc').format).to eq 'abc'
  end
end
