# frozen_string_literal: true

module Rails
  module Credentials
    module Conflict
      class GitConflictHandler
        STAGE_BASE = 1
        STAGE_OURS = 2
        STAGE_THEIRS = 3

        def initialize(credentials_path, relative_path)
          @credentials_path = credentials_path
          @relative_path = relative_path
        end

        def validate_conflict!
          unless File.exist?(@credentials_path)
            raise Error, "Credentials file not found: #{@credentials_path}"
          end

          git_status = `git status --porcelain #{@credentials_path}`.strip
          unless git_status.start_with?("UU") || git_status.start_with?("AA")
            raise Error, "No git conflict detected for #{@credentials_path}"
          end
        end

        def get_version(version)
          stage_number = stage_for_version(version)
          `git show :#{stage_number}:#{@relative_path} 2>/dev/null`.strip
        end

        def cleanup
          system("git add #{@credentials_path}")
        end

        private

        def stage_for_version(version)
          case version
          when :base then STAGE_BASE
          when :ours then STAGE_OURS
          when :theirs then STAGE_THEIRS
          else raise Error, "Unknown version: #{version}"
          end
        end
      end
    end
  end
end
