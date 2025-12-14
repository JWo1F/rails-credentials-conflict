# frozen_string_literal: true

require_relative "conflict/version"
require_relative "conflict/path_resolver"
require_relative "conflict/encryption_service"
require_relative "conflict/git_conflict_handler"
require_relative "conflict/merge_strategy"
require_relative "conflict/resolver"
require_relative "conflict/railtie" if defined?(Rails::Railtie)

module Rails
  module Credentials
    module Conflict
      class Error < StandardError; end
    end
  end
end
