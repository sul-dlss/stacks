# frozen_string_literal: true

# need resolv for the IP address regex
require 'resolv'

# this class is used for representing a time-limited grant of authorization to
# view a streaming resource.  the token object has fields representing the resource
# (id, file_name) and the request origin (user_ip). additionally,
# it has a timestamp indicating when it was created.
#
# the object can be serialized as a signed/encrypted string representation of
# itself.  the class can also create an instance of itself from such a representation.
#
# the class can also take an arbitrary string and a list of expected values for the
# token's fields.  if the string can be decrypted successfully (proving stacks
# minted it), the recovered hash can be checked against the provided list of values
# and the current time.  if the expected values match the decrypted values and the
# token is younger than the max age, it's good, otherwise, it's not.
#
# thus, stacks can mint a token string and give it to a user, who can give it
# to a service that stacks trusts, to allow that service to fulfil a request
# to stream a resource.
#
# the order of operations might be something like the following example:
# * a user makes a request to a stacks URL for a streaming resource.
# * stacks creates a StacksMediaToken and serializes it to its encrypted string form.
# * the encrypted string form of the token is included as part of a redirect to wowza.
# * wowza receives the request for the resource stream, with the encrypted string.
# * wowza calls back to stacks, and passes along: encrypted token string, IP from which
#   it received the request, id, and file name.
# * stacks uses StacksMediaToken#verify_encrypted_token? to determine whether
#   the encrypted string represents a still-valid token for the given resource.
# * if it does, it returns 200 OK to wowza, if it doesn't then it returns 403 Forbidden.
# * wowza serves the stream or not based on the response it gets from stacks.
# * this checking in wowza can be implemented via a wowza request processing plugin.
#
# notes:
# * there's no check for whether a token's been used (there's no record of the token having been
#   created in memory or DB, and so nothing to mark).  but that might be a good additional check.
# * encrypted token verfication assumes that an attacker cannot create a valid encrypted token string
#   without having compromised the stacks server, since the secret_key_base is needed to create a valid
#   encrypted token string.  also, the usual caveats about trusting the math, and Rails' implementation
#   of it, and our use of their implementation.
class StacksMediaToken
  include ActiveModel::Validations

  validates! :id, presence: true, format: /\A(druid:)?([a-z]{2})(\d{3})([a-z]{2})(\d{4})\z/i
  validates! :file_name, presence: true
  validates! :user_ip, presence: true, format: Resolv::AddressRegex

  attr_reader :id, :file_name, :user_ip, :timestamp

  def self.max_token_age
    Settings.stream.max_token_age.to_i.seconds
  end

  def initialize(id, file_name, user_ip)
    @id = id
    @file_name = file_name
    @user_ip = user_ip
    @timestamp = Time.zone.now
    validate
  end

  def to_hash
    {
      id: id,
      file_name: file_name,
      user_ip: user_ip,
      timestamp: timestamp
    }
  end

  # though the object is instantiated by the constructor, the string returned by this
  # method is what "mints" the token for the purposes of checks from other services
  def to_encrypted_string
    self.class.send(:encryptor).encrypt_and_sign to_hash
  end

  # this is how a string is checked to confirm whether it represents a still-valid token minted by stacks
  # NOTE: since this method does an expiry check at the time it's run, its result can
  # become stale, and should not be cached.
  def self.verify_encrypted_token?(encrypted_string, expected_id, expected_file_name, expected_user_ip)
    # if it can be decrypted, we assume we minted it.  if we minted it, we then check to see that
    # the information it contained still authorizes access for the resource it's expected to correspond to.
    unverified_token = StacksMediaToken.send(:create_from_encrypted_string, encrypted_string)
    unverified_token.send(:token_valid?, expected_id, expected_file_name, expected_user_ip)
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveSupport::MessageEncryptor::InvalidMessage
    false
  end

  def self.create_from_hash(token_hash)
    new token_hash[:id], token_hash[:file_name], token_hash[:user_ip]
  end
  private_class_method :create_from_hash

  # this method can throw ActiveSupport::MessageVerifier::InvalidSignature or
  # ActiveSupport::MessageEncryptor::InvalidMessage (the former can come from calling
  # MessageVerifier#verify, the latter from MessageEncryptor#_decrypt, both called by
  # MessageEncryptor#decrypt_and_verify).
  def self.create_from_encrypted_string(encrypted_string)
    token_hash = encryptor.decrypt_and_verify encrypted_string
    create_from_hash token_hash
  end
  private_class_method :create_from_encrypted_string

  def self.encryptor
    salt = 'media'
    key = ActiveSupport::KeyGenerator.new(Rails.application.secrets.secret_key_base).generate_key(salt, 32)
    ActiveSupport::MessageEncryptor.new(key)
  end
  private_class_method :encryptor

  private

  # the token is valid if
  #  * it has the values specified by the `expected_` params
  #  * it hasn't yet expired
  # NOTE: since this method does an expiry check at the time it's run, its result can
  # become stale, and should not be cached.
  def token_valid?(expected_id, expected_file_name, expected_user_ip)
    # max_token_age returns a duration.  calling `.ago` on it returns a date which we can check against for expiry.
    id == expected_id && file_name == expected_file_name && user_ip == expected_user_ip &&
      (timestamp >= self.class.max_token_age.ago)
  end
end
