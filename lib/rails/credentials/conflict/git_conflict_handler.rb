# frozen_string_literal: true

require "open3"

module Rails
  module Credentials
    module Conflict
      class GitConflictHandler
        STAGE_BASE = 1
        STAGE_OURS = 2
        STAGE_THEIRS = 3

        def initialize(credentials_path, relative_path)
          @credentials_path = credentials_path.to_s
          @relative_path = relative_path.to_s
        end

        def validate_conflict!
          unless File.exist?(@credentials_path)
            raise Error, "Credentials file not found: #{@credentials_path}"
          end

          git_status, status = Open3.capture2("git", "status", "--porcelain", @credentials_path)
          git_status = git_status.strip

          unless status.success? && (git_status.start_with?("UU") || git_status.start_with?("AA"))
            raise Error, "No git conflict detected for #{@credentials_path}"
          end
        end

        def get_version(version)
          stage_number = stage_for_version(version)
          content, status = Open3.capture2("git", "show", ":#{stage_number}:#{@relative_path}")
          status.success? ? content.strip : ""
        end

        def stage_resolved_file!
          _, status = Open3.capture2("git", "add", @credentials_path)

          unless status.success?
            raise Error, "Failed to stage resolved file: #{@credentials_path}"
          end
        end

        def get_merge_labels
          head_ref = detect_head_ref

          {
            ours: build_label(get_current_branch, get_short_sha("HEAD")),
            base: build_label("ancestor", get_merge_base_sha(head_ref)),
            theirs: build_label(get_incoming_branch(head_ref), get_short_sha(head_ref))
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

        def detect_head_ref
          %w[MERGE_HEAD CHERRY_PICK_HEAD REBASE_HEAD].each do |ref|
            _, status = Open3.capture2("git", "rev-parse", "--verify", ref)
            return ref if status.success?
          end

          "MERGE_HEAD"
        end

        def build_label(branch_name, commit_sha)
          "#{branch_name} (#{commit_sha})"
        end

        def get_current_branch
          branch, status = Open3.capture2("git", "rev-parse", "--abbrev-ref", "HEAD")
          branch = branch.strip
          status.success? && !branch.empty? ? branch : "HEAD"
        end

        def get_incoming_branch(head_ref)
          branch, status = Open3.capture2("git", "name-rev", "--name-only", head_ref)
          branch = branch.strip
          status.success? && !branch.empty? ? branch : head_ref
        end

        def get_short_sha(ref)
          sha, status = Open3.capture2("git", "rev-parse", "--short=8", ref)
          status.success? ? sha.strip : "unknown"
        end

        def get_merge_base_sha(head_ref)
          ours_sha, s1 = Open3.capture2("git", "rev-parse", "HEAD")
          theirs_sha, s2 = Open3.capture2("git", "rev-parse", head_ref)

          return "unknown" unless s1.success? && s2.success?

          base_sha, s3 = Open3.capture2("git", "merge-base", ours_sha.strip, theirs_sha.strip)
          s3.success? ? base_sha.strip[0..7] : "unknown"
        end
      end
    end
  end
end
