require 'rails_helper'

describe StacksMediaStream do
  it 'has a format accessor' do
    expect(StacksMediaStream.new(format: 'abc').format).to eq 'abc'
  end
end
