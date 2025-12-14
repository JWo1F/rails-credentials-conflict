# frozen_string_literal: true

require "active_support/message_encryptor"

module Rails
  module Credentials
    module Conflict
      class EncryptionService
        CIPHER = "aes-128-gcm"

        def initialize(key_path)
          @key_path = key_path
        end

        def decrypt(encrypted_content)
          return "" if encrypted_content.empty?

          encryptor.decrypt_and_verify(encrypted_content)
        end

        def encrypt(content)
          encryptor.encrypt_and_sign(content)
        end

        def save_encrypted(content, destination_path)
          encrypted = encrypt(content)
          File.write(destination_path, encrypted)
        end

        private

        def encryptor
          @encryptor ||= ActiveSupport::MessageEncryptor.new(
            [read_key].pack("H*"),
            cipher: CIPHER
          )
        end

        def read_key
          unless File.exist?(@key_path)
            raise Error, "Key file not found: #{@key_path}"
          end

          File.read(@key_path).strip
        end
      end
    end
  end
end
