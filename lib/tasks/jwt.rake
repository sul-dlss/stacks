# frozen_string_literal: true

desc 'Generate a JWT token for authentication'
task generate_token: :environment do
  abort 'Settings.service_token.hmac_secret is not set' if Settings.service_token.hmac_secret.blank?

  print 'Account name: '
  name = $stdin.gets.chomp
  print 'Allow downloading every file, regardless of its rights? (y/N): '
  download_all = $stdin.gets.chomp.casecmp?('y')
  payload = { sub: name }
  payload[:download_all] = true if download_all
  puts "Your token:\n#{JWT.encode(payload, Settings.service_token.hmac_secret, 'HS256')}"
end
