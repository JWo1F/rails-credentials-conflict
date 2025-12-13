# frozen_string_literal: true

require_relative "lib/rails/credentials/conflict/version"

Gem::Specification.new do |spec|
  spec.name = "rails-credentials-conflict"
  spec.version = Rails::Credentials::Conflict::VERSION
  spec.authors = ["Rails Credentials Conflict Contributors"]
  spec.email = [""]

  spec.summary = "Resolve Rails encrypted credentials conflicts during git merges"
  spec.description = "A gem that helps resolve git merge conflicts in Rails encrypted credentials by decrypting, merging, and re-encrypting the files."
  spec.homepage = "https://github.com/yourusername/rails-credentials-conflict"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/yourusername/rails-credentials-conflict"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "railties", ">= 6.0"
  spec.add_dependency "activesupport", ">= 6.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
