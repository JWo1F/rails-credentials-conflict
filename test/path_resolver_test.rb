# frozen_string_literal: true

require "test_helper"

class PathResolverTest < Minitest::Test
  def test_main_credentials_path
    resolver = Rails::Credentials::Conflict::PathResolver.new
    assert_equal Pathname.new("/app/config/credentials.yml.enc"), resolver.credentials_path
  end

  def test_main_key_path
    resolver = Rails::Credentials::Conflict::PathResolver.new
    assert_equal Pathname.new("/app/config/master.key"), resolver.key_path
  end

  def test_main_relative_credentials_path
    resolver = Rails::Credentials::Conflict::PathResolver.new
    assert_equal Pathname.new("config/credentials.yml.enc"), resolver.relative_credentials_path
  end

  def test_env_credentials_path
    resolver = Rails::Credentials::Conflict::PathResolver.new("staging")
    assert_equal Pathname.new("/app/config/credentials/staging.yml.enc"), resolver.credentials_path
  end

  def test_env_key_path
    resolver = Rails::Credentials::Conflict::PathResolver.new("staging")
    assert_equal Pathname.new("/app/config/credentials/staging.key"), resolver.key_path
  end

  def test_env_relative_credentials_path
    resolver = Rails::Credentials::Conflict::PathResolver.new("staging")
    assert_equal Pathname.new("config/credentials/staging.yml.enc"), resolver.relative_credentials_path
  end
end
