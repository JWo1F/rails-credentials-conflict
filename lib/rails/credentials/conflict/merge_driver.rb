# frozen_string_literal: true

module Rails
  module Credentials
    module Conflict
      # Git merge driver entry point for encrypted credentials files.
      #
      # Invoked by git during merge/rebase/cherry-pick when a custom
      # merge driver is configured via +.gitattributes+.
      #
      # Git calls the driver with four paths:
      # - +base_path+ (+%O+) — common ancestor version
      # - +ours_path+ (+%A+) — current branch version (result is written here)
      # - +theirs_path+ (+%B+) — other branch version
      # - +file_path+ (+%P+) — pathname of the file being merged
      module MergeDriver
        # Extracts the environment name from a credentials file path.
        #
        # "config/credentials.yml.enc"          → nil
        # "config/credentials/staging.yml.enc"  → "staging"
        def self.extract_environment(file_path)
          if file_path =~ %r{config/credentials/([^/]+)\.yml\.enc\z}
            $1
          end
        end

        # Runs the merge driver. Decrypts the three versions, performs a
        # three-way merge, and writes the encrypted result back to +ours_path+.
        #
        # Returns +0+ on successful auto-merge, +1+ when conflicts remain.
        def self.call(base_path, ours_path, theirs_path, file_path)
          environment = extract_environment(file_path)
          path_resolver = PathResolver.new(environment)
          encryption_service = EncryptionService.new(path_resolver.key_path)
          merge_strategy = MergeStrategy.new(encryption_service)

          base_content = encryption_service.decrypt(File.binread(base_path))
          ours_content = encryption_service.decrypt(File.binread(ours_path))
          theirs_content = encryption_service.decrypt(File.binread(theirs_path))

          return 0 if ours_content == theirs_content

          result = merge_strategy.create_conflict_markers(
            ours_content,
            base_content,
            theirs_content,
            labels: { ours: "ours", base: "base", theirs: "theirs" }
          )

          return 1 if result[:has_conflicts]

          encryption_service.save_encrypted(result[:content], ours_path)
          0
        rescue StandardError
          1
        end
      end
    end
  end
end
