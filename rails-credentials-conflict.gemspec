# frozen_string_literal: true

require_relative "lib/rails/credentials/conflict/version"

Gem::Specification.new do |spec|
  spec.name = "rails-credentials-conflict"
  spec.version = Rails::Credentials::Conflict::VERSION
  spec.authors = ["jwo1f"]
  spec.email = [""]

  spec.summary = "Resolve git merge conflicts in Rails encrypted credentials"
  spec.description = "Resolve git merge conflicts in Rails encrypted credentials by decrypting, merging, " \
                     "and re-encrypting them. Works with merge, rebase, and cherry-pick."
  spec.homepage = "https://github.com/jwo1f/rails-credentials-conflict"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/jwo1f/rails-credentials-conflict"
  spec.metadata["changelog_uri"] = "https://github.com/jwo1f/rails-credentials-conflict/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ Gemfile .gitignore .idea/ .rubocop])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 6.0"
  spec.add_dependency "railties", ">= 6.0"
end
