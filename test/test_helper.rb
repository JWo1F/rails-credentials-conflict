# frozen_string_literal: true

require "minitest/autorun"
require "securerandom"
require "tempfile"
require "open3"
require "rails/credentials/conflict"

# Stub Rails.root for testing
module Rails
  def self.root
    @test_root || Pathname.new("/app")
  end

  def self.root=(val)
    @test_root = val
  end
end
