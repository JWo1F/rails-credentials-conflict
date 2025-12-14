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

        def get_merge_labels
          {
            ours: build_label(get_current_branch, get_commit_sha("HEAD")),
            base: build_label("ancestor", get_merge_base_sha),
            theirs: build_label(get_merge_branch, get_commit_sha("MERGE_HEAD"))
          }
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

        def build_label(branch_name, commit_sha)
          "#{branch_name} (#{commit_sha})"
        end

        def get_current_branch
          branch = `git rev-parse --abbrev-ref HEAD 2>/dev/null`.strip
          branch.empty? ? "HEAD" : branch
        end

        def get_merge_branch
          # Try to get the branch name from MERGE_HEAD
          branch = `git name-rev --name-only MERGE_HEAD 2>/dev/null`.strip
          return branch unless branch.empty?

          # Fallback to MERGE_HEAD if name-rev fails
          "MERGE_HEAD"
        end

        def get_commit_sha(ref)
          sha = `git rev-parse --short=8 #{ref} 2>/dev/null`.strip
          sha.empty? ? "unknown" : sha
        end

        def get_merge_base_sha
          ours_sha = `git rev-parse HEAD 2>/dev/null`.strip
          theirs_sha = `git rev-parse MERGE_HEAD 2>/dev/null`.strip

          return "unknown" if ours_sha.empty? || theirs_sha.empty?

          base_sha = `git merge-base #{ours_sha} #{theirs_sha} 2>/dev/null`.strip
          base_sha.empty? ? "unknown" : base_sha[0..7]
        end
      end
    end
  end
end
