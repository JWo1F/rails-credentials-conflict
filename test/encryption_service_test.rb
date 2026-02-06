# frozen_string_literal: true

require "test_helper"

class EncryptionServiceTest < Minitest::Test
  def setup
    @key = SecureRandom.hex(16)
    @key_file = Tempfile.new("test_key")
    @key_file.write(@key)
    @key_file.flush
    @service = Rails::Credentials::Conflict::EncryptionService.new(@key_file.path)
  end

  def teardown
    @key_file.close!
  end

  def test_round_trips_content
    original = "secret: value\napi_key: 12345"
    encrypted = @service.encrypt(original)
    assert_equal original, @service.decrypt(encrypted)
  end

  def test_decrypt_empty_string
    assert_equal "", @service.decrypt("")
  end

  def test_decrypt_nil
    assert_equal "", @service.decrypt(nil)
  end

  def test_save_encrypted_writes_file
    output = Tempfile.new("encrypted_output")

    begin
      @service.save_encrypted("test content", output.path)
      encrypted = File.read(output.path)

      refute_equal "test content", encrypted
      assert_equal "test content", @service.decrypt(encrypted)
    ensure
      output.close!
    end
  end

  def test_raises_when_no_key_available
    service = Rails::Credentials::Conflict::EncryptionService.new(
      "/nonexistent/path/key",
      env_key: "NONEXISTENT_TEST_KEY_VAR_#{SecureRandom.hex(4)}"
    )

    error = assert_raises(Rails::Credentials::Conflict::Error) { service.encrypt("test") }
    assert_match(/Encryption key not found/, error.message)
  end

  def test_reads_key_from_env_var
    env_key_name = "TEST_RAILS_KEY_#{SecureRandom.hex(4)}"

    begin
      ENV[env_key_name] = @key
      service = Rails::Credentials::Conflict::EncryptionService.new("/nonexistent/path", env_key: env_key_name)

      encrypted = service.encrypt("secret data")
      assert_equal "secret data", service.decrypt(encrypted)
    ensure
      ENV.delete(env_key_name)
    end
  end

  def test_reads_key_from_rails_master_key_env
    original_env = ENV["RAILS_MASTER_KEY"]

    begin
      ENV["RAILS_MASTER_KEY"] = @key
      service = Rails::Credentials::Conflict::EncryptionService.new("/nonexistent/path")

      encrypted = service.encrypt("secret data")
      assert_equal "secret data", service.decrypt(encrypted)
    ensure
      if original_env
        ENV["RAILS_MASTER_KEY"] = original_env
      else
        ENV.delete("RAILS_MASTER_KEY")
      end
    end
  end
end
