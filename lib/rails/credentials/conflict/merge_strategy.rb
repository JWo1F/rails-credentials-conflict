# frozen_string_literal: true

require "tempfile"

module Rails
  module Credentials
    module Conflict
      class MergeStrategy
        CONFLICT_MARKER_START = "<<<<<<<"
        CONFLICT_MARKER_END = ">>>>>>>"

        def initialize(encryption_service)
          @encryption_service = encryption_service
        end

        def create_conflict_markers(ours_content, base_content, theirs_content)
          with_temp_files(ours_content, base_content, theirs_content) do |ours_path, base_path, theirs_path|
            output = Tempfile.new(["merged", ".yml"])

            begin
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

        def has_conflict_markers?(content)
          content.include?(CONFLICT_MARKER_START) || content.include?(CONFLICT_MARKER_END)
        end

        def open_editor_for_resolution(merged_content)
          Tempfile.create(["credentials_conflict", ".yml"]) do |tempfile|
            tempfile.write(merged_content)
            tempfile.flush

            editor = ENV["EDITOR"] || "vim"
            system("#{editor} #{tempfile.path}")

            File.read(tempfile.path)
          end
        end

        private

        def with_temp_files(*contents)
          temp_files = contents.map.with_index do |content, index|
            Tempfile.new(["temp_#{index}", ".yml"])
          end

          begin
            temp_files.each_with_index do |file, index|
              file.write(contents[index])
              file.flush
            end

            yield(*temp_files.map(&:path))
          ensure
            temp_files.each do |file|
              file.close
              file.unlink
            end
          end
        end
      end
    end
  end
end
