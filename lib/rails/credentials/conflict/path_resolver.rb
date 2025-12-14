# frozen_string_literal: true

module Rails
  module Credentials
    module Conflict
      class PathResolver
        attr_reader :environment

        def initialize(environment = nil)
          @environment = environment
        end

        def credentials_path
          if environment
            ::Rails.root.join("config", "credentials", "#{environment}.yml.enc")
          else
            ::Rails.root.join("config", "credentials.yml.enc")
          end
        end

        def key_path
          if environment
            ::Rails.root.join("config", "credentials", "#{environment}.key")
          else
            ::Rails.root.join("config", "master.key")
          end
        end

        def relative_credentials_path
          credentials_path.relative_path_from(::Rails.root)
        end
      end
    end
  end
end
