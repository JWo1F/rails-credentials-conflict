# frozen_string_literal: true

module Rails
  module Credentials
    module Conflict
      # Resolves file system paths for Rails encrypted credentials
      # and their corresponding key files.
      #
      # Supports both the default credentials (+config/credentials.yml.enc+)
      # and environment-specific ones (+config/credentials/<env>.yml.enc+).
      class PathResolver
        VALID_ENVIRONMENT = /\A[a-z0-9_]+\z/

        attr_reader :environment

        def initialize(environment = nil)
          if environment && !VALID_ENVIRONMENT.match?(environment.to_s)
            raise Error,
                  "Invalid environment name: #{environment.inspect}. " \
                  "Must contain only lowercase letters, digits, and underscores."
          end

          @environment = environment
        end

        # Returns the absolute Pathname to the encrypted credentials file.
        def credentials_path
          if environment
            ::Rails.root.join("config", "credentials", "#{environment}.yml.enc")
          else
            ::Rails.root.join("config", "credentials.yml.enc")
          end
        end

        # Returns the absolute Pathname to the encryption key file.
        def key_path
          if environment
            ::Rails.root.join("config", "credentials", "#{environment}.key")
          else
            ::Rails.root.join("config", "master.key")
          end
        end

        # Returns the credentials path relative to +Rails.root+.
        def relative_credentials_path
          credentials_path.relative_path_from(::Rails.root)
        end
      end
    end
  end
end
