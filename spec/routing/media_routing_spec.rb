# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Media routes' do
  it 'verify_token' do
    expect(get: '/media/oo000oo0000/filename.mp4/verify_token?stacks_token=asdf&user_ip=192.168.1.100').to route_to(
      'media#verify_token', id: 'oo000oo0000', file_name: 'filename.mp4', stacks_token: 'asdf', user_ip: '192.168.1.100'
    )
  end
end
