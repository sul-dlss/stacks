# frozen_string_literal: true

# Creates an S3 client instance.
class S3ClientFactory
  # rubocop:disable Naming/MemoizedInstanceVariableName
  def self.create_client
    @client ||= Aws::S3::Client.new(
      region: 'us-east-1',
      endpoint: Settings.s3.endpoint,
      force_path_style: true,
      access_key_id: Settings.s3.access_key_id,
      secret_access_key: Settings.s3.secret_access_key
    )
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName
end
