# frozen_string_literal: true

desc 'Generate a JWT token for authentication'
task generate_token: :environment do
  abort 'Settings.service_token.hmac_secret is not set' if Settings.service_token.hmac_secret.blank?

  print 'Account name: '
  name = $stdin.gets.chomp
  payload = { sub: name }
  puts "Your token:\n#{JWT.encode(payload, Settings.service_token.hmac_secret, 'HS256')}"
end
