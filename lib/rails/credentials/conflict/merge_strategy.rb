# frozen_string_literal: true

require "tempfile"
require "yaml"

module Rails
  module Credentials
    module Conflict
      class MergeStrategy
        CONFLICT_MARKER_START = "<<<<<<<"
        CONFLICT_MARKER_END = ">>>>>>>"

        def initialize(encryption_service)
          @encryption_service = encryption_service
        end

        def create_conflict_markers(ours_content, base_content, theirs_content, labels:)
          with_temp_files(ours_content, base_content, theirs_content) do |ours_path, base_path, theirs_path|
            output = Tempfile.new(["merged", ".yml"])

            begin
              merge_result = system(
                "git", "merge-file", "-p", "--diff3",
                "-L", labels[:ours],
                "-L", labels[:base],
                "-L", labels[:theirs],
                ours_path, base_path, theirs_path,
                out: output.path,
                err: File::NULL
              )

              output.rewind
              merged_content = output.read

              has_conflicts = !merge_result

              { content: merged_content, has_conflicts: has_conflicts }
            ensure
              output.close
              output.unlink
            end
          end
        end

        def has_conflict_markers?(content)
          content.include?(CONFLICT_MARKER_START) || content.include?(CONFLICT_MARKER_END)
        end

        def validate_yaml!(content)
          YAML.safe_load(content)
        rescue Psych::SyntaxError => e
          raise Error, "Resolved content is not valid YAML: #{e.message}"
        end

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
