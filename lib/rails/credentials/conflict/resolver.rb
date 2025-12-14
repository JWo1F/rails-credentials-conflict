# frozen_string_literal: true

module Rails
  module Credentials
    module Conflict
      class Resolver
        attr_reader :environment

        def initialize(environment = nil)
          @environment = environment
          @path_resolver = PathResolver.new(environment)
          @encryption_service = EncryptionService.new(@path_resolver.key_path)
          @git_handler = GitConflictHandler.new(
            @path_resolver.credentials_path,
            @path_resolver.relative_credentials_path
          )
          @merge_strategy = MergeStrategy.new(@encryption_service)
        end

        def resolve
          @git_handler.validate_conflict!

          ours_content = decrypt_version(:ours)
          theirs_content = decrypt_version(:theirs)

          if ours_content == theirs_content
            puts "No conflicts detected. Both versions are identical."
            save_and_cleanup(ours_content)
            return
          end

          base_content = get_base_version
          merged_content = @merge_strategy.create_conflict_markers(
            ours_content,
            base_content,
            theirs_content
          )

          resolved_content = @merge_strategy.open_editor_for_resolution(merged_content)

          if @merge_strategy.has_conflict_markers?(resolved_content)
            puts "Warning: Conflict markers still present. Please resolve all conflicts."
            exit 1
          end

          save_and_cleanup(resolved_content)
          puts "Credentials successfully resolved and encrypted."
        end

        def yours
          resolve_with_version(:ours, "your")
        end

        def theirs
          resolve_with_version(:theirs, "their")
        end

        def base
          resolve_with_version(:base, "base")
        end

        private

        def resolve_with_version(version, label)
          @git_handler.validate_conflict!

          encrypted_content = @git_handler.get_version(version)
          if encrypted_content.empty?
            raise Error, "No #{label} version found."
          end

          content = @encryption_service.decrypt(encrypted_content)
          save_and_cleanup(content)
          puts "Kept #{label} version of credentials."
        end

        def decrypt_version(version)
          encrypted_content = @git_handler.get_version(version)
          @encryption_service.decrypt(encrypted_content)
        end

        def get_base_version
          base_encrypted = @git_handler.get_version(:base)
          return "" if base_encrypted.empty?

          @encryption_service.decrypt(base_encrypted)
        rescue
          ""
        end

        def save_and_cleanup(content)
          @encryption_service.save_encrypted(content, @path_resolver.credentials_path)
          @git_handler.cleanup
        end
      end
    end
  end
end
