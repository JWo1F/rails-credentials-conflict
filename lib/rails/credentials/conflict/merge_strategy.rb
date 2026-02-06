# frozen_string_literal: true

require "open3"
require "tempfile"
require "yaml"

module Rails
  module Credentials
    module Conflict
      # Performs three-way merge of decrypted credentials using git merge-file.
      #
      # Handles creating conflict markers for manual resolution,
      # detecting unresolved markers, validating YAML, and opening
      # an editor for interactive conflict resolution.
      class MergeStrategy
        CONFLICT_MARKER_START = "<<<<<<<"
        CONFLICT_MARKER_END = ">>>>>>>"

        def initialize(encryption_service)
          @encryption_service = encryption_service
        end

        # Runs a three-way merge via +git merge-file+ and returns the result.
        #
        # Returns a Hash with +:content+ (merged text) and +:has_conflicts+
        # (true when conflict markers are present).
        #
        # Raises +Error+ when +git merge-file+ exits with a status greater
        # than 1, which indicates an actual error rather than conflicts.
        def create_conflict_markers(ours_content, base_content, theirs_content, labels:)
          with_temp_files(ours_content, base_content, theirs_content) do |ours_path, base_path, theirs_path|
            merged_content, status = Open3.capture2(
              "git", "merge-file", "-p", "--diff3",
              "-L", labels[:ours],
              "-L", labels[:base],
              "-L", labels[:theirs],
              ours_path, base_path, theirs_path,
              err: File::NULL
            )

            exit_code = status.exitstatus

            raise Error, "git merge-file failed (exit #{exit_code || "unknown"})" if exit_code.nil? || exit_code > 1

            { content: merged_content, has_conflicts: exit_code == 1 }
          end
        end

        # Returns true if the content contains unresolved git conflict markers.
        def has_conflict_markers?(content)
          content.include?(CONFLICT_MARKER_START) || content.include?(CONFLICT_MARKER_END)
        end

        # Parses content as YAML and raises +Error+ if it is invalid.
        def validate_yaml!(content)
          YAML.safe_load(content)
        rescue Psych::SyntaxError => e
          raise Error, "Resolved content is not valid YAML: #{e.message}"
        end

        # Writes +merged_content+ to a temp file, opens it in +$EDITOR+,
        # and returns the edited content after the editor exits.
        def open_editor_for_resolution(merged_content)
          Tempfile.create(["credentials_conflict", ".yml"]) do |tempfile|
            tempfile.write(merged_content)
            tempfile.flush

            editor = ENV.fetch("EDITOR", "vim")
            system(editor, tempfile.path)

            File.read(tempfile.path)
          end
        end

        private

        def with_temp_files(*contents)
          temp_files = contents.map.with_index do |content, index|
            file = Tempfile.new(["temp_#{index}", ".yml"])
            file.write(content)
            file.flush
            file
          end

          yield(*temp_files.map(&:path))
        ensure
          temp_files&.each do |file|
            file.close
            file.unlink
          end
        end
      end
    end
  end
end
