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

          merged_content = create_git_conflict_markers(ours_content, theirs_content)

          Tempfile.create(["credentials_conflict", ".yml"]) do |tempfile|
            tempfile.write(merged_content)
            tempfile.flush

            editor = ENV["EDITOR"] || "vim"
            system("#{editor} #{tempfile.path}")

            # Read from disk after editor saves changes
            resolved_content = File.read(tempfile.path)

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

          ours_encrypted = get_git_version(:ours)
          if ours_encrypted.empty?
            raise Error, "No yours version found."
          end

          ours_content = decrypt_content(ours_encrypted)
          save_encrypted_content(ours_content)
          cleanup_git_conflict
          puts "Kept your version of credentials."
        end

        def theirs
          validate_git_conflict!

          theirs_encrypted = get_git_version(:theirs)
          if theirs_encrypted.empty?
            raise Error, "No theirs version found."
          end

          theirs_content = decrypt_content(theirs_encrypted)
          save_encrypted_content(theirs_content)
          cleanup_git_conflict
          puts "Kept their version of credentials."
        end

        def base
          validate_git_conflict!

          base_encrypted = get_git_version(:base)
          if base_encrypted.empty?
            raise Error, "No base version found."
          end

          base_content = decrypt_content(base_encrypted)
          save_encrypted_content(base_content)
          cleanup_git_conflict
          puts "Kept base version of credentials."
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
          # Stage 1 = base (merge-base), Stage 2 = ours, Stage 3 = theirs
          stage_number = case version
                         when :base then 1
                         when :ours then 2
                         when :theirs then 3
                         else raise Error, "Unknown version: #{version}"
                         end

          `git show :#{stage_number}:#{credentials_path.relative_path_from(::Rails.root)} 2>/dev/null`.strip
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

        def create_git_conflict_markers(ours_content, theirs_content)
          base_content = get_base_version

          with_temp_files(ours_content, base_content, theirs_content) do |ours_path, base_path, theirs_path|
            # Create output tempfile for merged result
            output = Tempfile.new(["merged", ".yml"])

            begin
              # Use git merge-file to create proper conflict markers
              # Exit code 1 means conflicts exist, which is expected
              system(
                "git", "merge-file", "-p", "--diff3",
                "-L", "HEAD (yours)",
                "-L", "base",
                "-L", "MERGE_HEAD (theirs)",
                ours_path, base_path, theirs_path,
                out: output.path,
                err: File::NULL
              )

              output.rewind
              output.read
            ensure
              output.close
              output.unlink
            end
          end
        end

        def get_base_version
          # Try to get the base/merge-base version (stage 1)
          base_encrypted = `git show :1:#{credentials_path.relative_path_from(::Rails.root)} 2>/dev/null`.strip
          return "" if base_encrypted.empty?

          decrypt_content(base_encrypted)
        rescue
          # If base version doesn't exist or can't be decrypted, return empty
          ""
        end

        def with_temp_files(ours, base, theirs)
          ours_file = Tempfile.new(["ours", ".yml"])
          base_file = Tempfile.new(["base", ".yml"])
          theirs_file = Tempfile.new(["theirs", ".yml"])

          begin
            ours_file.write(ours)
            ours_file.flush

            base_file.write(base)
            base_file.flush

            theirs_file.write(theirs)
            theirs_file.flush

            yield ours_file.path, base_file.path, theirs_file.path
          ensure
            ours_file.close
            ours_file.unlink
            base_file.close
            base_file.unlink
            theirs_file.close
            theirs_file.unlink
          end
        end

        def cleanup_git_conflict
          # Add the resolved file to staging
          system("git add #{credentials_path}")
        end
      end
    end
  end
end
