require 'rails_helper'

describe StacksMediaToken do
  test_start_time = Time.zone.now
  let(:id) { 'ab012cd3456' }
  let(:file_name) { 'def' }
  let(:user_ip) { '192.168.1.100' }
  subject { described_class.new(id, file_name, user_ip) }

  describe '#create_from_encrypted_string' do
    it 'should build an object with the right fields' do
      encrypted_token_str = subject.to_encrypted_string
      token_from_encrypted_str = StacksMediaToken.send(:create_from_encrypted_string, encrypted_token_str)

      expect(token_from_encrypted_str.id).to eq id
      expect(token_from_encrypted_str.file_name).to eq file_name
      expect(token_from_encrypted_str.user_ip).to eq user_ip
      expect(token_from_encrypted_str.timestamp).to be >= test_start_time
      expect(token_from_encrypted_str.timestamp).to be <= Time.zone.now
    end
  end

  describe '#token_valid?' do
    it 'returns true for a valid token' do
      expect(subject.send(:token_valid?, id, file_name, user_ip)).to eq true
    end

    it 'returns false if the ids do not match' do
      expect(subject.send(:token_valid?, 'zy098xv7654', file_name, user_ip)).to eq false
    end

    it 'returns false if the file names do not match' do
      expect(subject.send(:token_valid?, id, 'fed', user_ip)).to eq false
    end

    it 'returns false if the IP addresses do not match' do
      expect(subject.send(:token_valid?, id, file_name, '192.168.1.101')).to eq false
    end

    it 'returns true if the last IP address in a comma delimited string matches' do
      expect(subject.send(:token_valid?, id, file_name, "192.168.1.101, #{user_ip}")).to eq true
    end

    it 'returns false if the token is too old' do
      expired_timestamp = (StacksMediaToken.max_token_age + 2.seconds).ago
      allow(subject).to receive(:timestamp).and_return(expired_timestamp)
      expect(subject.send(:token_valid?, id, file_name, user_ip)).to eq false
    end
  end

  describe '#verify_encrypted_token?' do
    let(:enc_token_str) { subject.to_encrypted_string }

    it 'returns true for a valid token that matches the specified values' do
      expect(StacksMediaToken.verify_encrypted_token?(enc_token_str, id, file_name, user_ip)).to eq true
    end

    it 'returns false if the signature is invalid' do
      invalid_sig_err = ActiveSupport::MessageVerifier::InvalidSignature
      allow(StacksMediaToken).to receive(:create_from_encrypted_string).with(enc_token_str).and_raise(invalid_sig_err)
      expect(StacksMediaToken.verify_encrypted_token?(enc_token_str, id, file_name, user_ip)).to eq false
    end

    it 'returns false if the encrypted message is invalid' do
      invalid_msg_err = ActiveSupport::MessageEncryptor::InvalidMessage
      allow(StacksMediaToken).to receive(:create_from_encrypted_string).with(enc_token_str).and_raise(invalid_msg_err)
      expect(StacksMediaToken.verify_encrypted_token?(enc_token_str, id, file_name, user_ip)).to eq false
    end

    it 'returns false on a token that has been tampered with' do
      enc_token_str[0..4] = 'edit' # replace the first 4 characters with something else
      expect(StacksMediaToken.verify_encrypted_token?(enc_token_str, id, file_name, user_ip)).to eq false
    end

    it 'returns false if token_valid? returns false' do
      mock_token = double(StacksMediaToken)
      allow(StacksMediaToken).to receive(:create_from_encrypted_string).with(enc_token_str).and_return(mock_token)
      allow(mock_token).to receive(:token_valid?).with(id, file_name, user_ip).and_return(false)
      expect(StacksMediaToken.verify_encrypted_token?(enc_token_str, id, file_name, user_ip)).to eq false
    end
  end

  describe 'field validation' do
    let(:valid_id1) { 'druid:ab012cd3456' }
    let(:valid_id2) { 'ab012cd3456' }
    let(:valid_filename) { 'filename.mp4' }
    let(:valid_ip) { '192.168.1.100' }

    it 'can create a valid token without raising an error' do
      expect { StacksMediaToken.new(valid_id1, valid_filename, valid_ip) }.not_to raise_error
      expect { StacksMediaToken.new(valid_id2, valid_filename, valid_ip) }.not_to raise_error
    end

    it 'raises an error when creating a token with an empty required field' do
      expect { StacksMediaToken.new('', valid_filename, valid_ip) }
        .to raise_error(ActiveModel::StrictValidationFailed, "Id can't be blank")
      expect { StacksMediaToken.new(valid_id1, '', valid_ip) }
        .to raise_error(ActiveModel::StrictValidationFailed, "File name can't be blank")
      expect { StacksMediaToken.new(valid_id1, valid_filename, '') }
        .to raise_error(ActiveModel::StrictValidationFailed, "User ip can't be blank")
    end

    it 'raises an error when creating a token with a bad id' do
      expect { StacksMediaToken.new('zab012cd34567', valid_filename, valid_ip) }
        .to raise_error(ActiveModel::StrictValidationFailed, 'Id is invalid')
    end

    it 'raises an error when creating a token with a bad IP' do
      expect { StacksMediaToken.new(valid_id1, valid_filename, '127') }
        .to raise_error(ActiveModel::StrictValidationFailed, 'User ip is invalid')
      expect { StacksMediaToken.new(valid_id1, valid_filename, '0') }
        .to raise_error(ActiveModel::StrictValidationFailed, 'User ip is invalid')
      expect { StacksMediaToken.new(valid_id1, valid_filename, '0.0.0.0.0') }
        .to raise_error(ActiveModel::StrictValidationFailed, 'User ip is invalid')
      expect { StacksMediaToken.new(valid_id1, valid_filename, 'localhost') }
        .to raise_error(ActiveModel::StrictValidationFailed, 'User ip is invalid')
    end
  end
end
