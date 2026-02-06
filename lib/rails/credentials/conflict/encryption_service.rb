# frozen_string_literal: true

require "active_support/message_encryptor"

module Rails
  module Credentials
    module Conflict
      # Encrypts and decrypts Rails credentials content using AES-128-GCM.
      #
      # The encryption key is read from either an environment variable
      # (default +RAILS_MASTER_KEY+) or a key file on disk.
      class EncryptionService
        CIPHER = "aes-128-gcm"

        def initialize(key_path, env_key: "RAILS_MASTER_KEY")
          @key_path = key_path
          @env_key = env_key
        end

        # Decrypts and verifies +encrypted_content+.
        # Returns an empty string for nil or empty input.
        def decrypt(encrypted_content)
          return "" if encrypted_content.nil? || encrypted_content.empty?

          encryptor.decrypt_and_verify(encrypted_content)
        end

        # Encrypts and signs +content+, returning the ciphertext.
        def encrypt(content)
          encryptor.encrypt_and_sign(content)
        end

        # Encrypts +content+ and writes it to +destination_path+ in binary mode.
        def save_encrypted(content, destination_path)
          File.binwrite(destination_path, encrypt(content))
        end

        private

        def encryptor
          @encryptor ||= ActiveSupport::MessageEncryptor.new(
            [read_key].pack("H*"),
            cipher: CIPHER
          )
        end

        def read_key
          key_from_env || key_from_file || raise(
            Error, "Encryption key not found. Set #{@env_key} env variable or create #{@key_path}"
          )
        end

        def key_from_env
          value = ENV[@env_key]&.strip
          value unless value.nil? || value.empty?
        end

        def key_from_file
          return nil unless File.exist?(@key_path)

          value = File.read(@key_path).strip
          value.empty? ? nil : value
        end
      end
    end
  end
end
