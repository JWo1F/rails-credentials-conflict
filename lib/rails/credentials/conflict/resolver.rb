# frozen_string_literal: true

require "tempfile"
require "active_support/message_encryptor"

module Rails
  module Credentials
    module Conflict
      class Resolver
        attr_reader :environment

        def initialize(environment = nil)
          @environment = environment
        end

        def resolve
          validate_git_conflict!

          ours_content = decrypt_version(:ours)
          theirs_content = decrypt_version(:theirs)

          if ours_content == theirs_content
            puts "No conflicts detected. Both versions are identical."
            save_encrypted_content(ours_content)
            cleanup_git_conflict
            return
          end

          merged_content = create_conflict_markers(ours_content, theirs_content)

          Tempfile.create(["credentials_conflict", ".yml"]) do |tempfile|
            tempfile.write(merged_content)
            tempfile.flush

            editor = ENV["EDITOR"] || "vim"
            system("#{editor} #{tempfile.path}")

            tempfile.rewind
            resolved_content = tempfile.read

            if resolved_content.include?("<<<<<<<") || resolved_content.include?(">>>>>>>")
              puts "Warning: Conflict markers still present. Please resolve all conflicts."
              exit 1
            end

            save_encrypted_content(resolved_content)
            cleanup_git_conflict
            puts "Credentials successfully resolved and encrypted."
          end
        end

        def yours
          validate_git_conflict!
          checkout_version(:ours)
          cleanup_git_conflict
          puts "Kept your version of credentials."
        end

        def theirs
          validate_git_conflict!
          checkout_version(:theirs)
          cleanup_git_conflict
          puts "Kept their version of credentials."
        end

        private

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

        def validate_git_conflict!
          unless File.exist?(credentials_path)
            raise Error, "Credentials file not found: #{credentials_path}"
          end

          # Check if file is in conflict state
          git_status = `git status --porcelain #{credentials_path}`.strip
          unless git_status.start_with?("UU") || git_status.start_with?("AA")
            raise Error, "No git conflict detected for #{credentials_path}"
          end
        end

        def decrypt_version(version)
          # version is :ours or :theirs
          encrypted_content = get_git_version(version)
          decrypt_content(encrypted_content)
        end

        def get_git_version(version)
          # Get the content from git staging area
          stage_number = version == :ours ? 2 : 3
          `git show :#{stage_number}:#{credentials_path.relative_path_from(::Rails.root)}`.strip
        end

        def checkout_version(version)
          flag = version == :ours ? "--ours" : "--theirs"
          system("git checkout #{flag} #{credentials_path}")
        end

        def decrypt_content(encrypted_content)
          return "" if encrypted_content.empty?

          key = read_key
          encryptor = ActiveSupport::MessageEncryptor.new([key].pack("H*"), cipher: "aes-128-gcm")
          encryptor.decrypt_and_verify(encrypted_content)
        end

        def save_encrypted_content(content)
          key = read_key
          encryptor = ActiveSupport::MessageEncryptor.new([key].pack("H*"), cipher: "aes-128-gcm")
          encrypted = encryptor.encrypt_and_sign(content)

          File.write(credentials_path, encrypted)
        end

        def read_key
          unless File.exist?(key_path)
            raise Error, "Key file not found: #{key_path}"
          end

          File.read(key_path).strip
        end

        def create_conflict_markers(ours, theirs)
          <<~CONFLICT
            <<<<<<< HEAD (yours)
            #{ours}
            =======
            #{theirs}
            >>>>>>> MERGE_HEAD (theirs)
          CONFLICT
        end

        def cleanup_git_conflict
          # Add the resolved file to staging
          system("git add #{credentials_path}")
        end
      end
    end
  end
end
