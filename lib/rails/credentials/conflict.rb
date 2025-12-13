# frozen_string_literal: true

require_relative "conflict/version"
require_relative "conflict/resolver"
require_relative "conflict/railtie" if defined?(Rails::Railtie)

module Rails
  module Credentials
    module Conflict
      class Error < StandardError; end
    end
  end
end
