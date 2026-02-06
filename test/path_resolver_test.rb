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

  def test_rejects_path_traversal
    error = assert_raises(Rails::Credentials::Conflict::Error) do
      Rails::Credentials::Conflict::PathResolver.new("../../etc/passwd")
    end
    assert_match(/Invalid environment name/, error.message)
  end

  def test_rejects_uppercase_environment
    error = assert_raises(Rails::Credentials::Conflict::Error) do
      Rails::Credentials::Conflict::PathResolver.new("Production")
    end
    assert_match(/Invalid environment name/, error.message)
  end

  def test_rejects_environment_with_spaces
    error = assert_raises(Rails::Credentials::Conflict::Error) do
      Rails::Credentials::Conflict::PathResolver.new("my env")
    end
    assert_match(/Invalid environment name/, error.message)
  end

  def test_accepts_environment_with_underscores_and_digits
    resolver = Rails::Credentials::Conflict::PathResolver.new("staging_2")

    assert_equal "staging_2", resolver.environment
  end
end
