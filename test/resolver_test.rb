# frozen_string_literal: true

require "test_helper"

class ResolverTest < Minitest::Test
  def setup
    @output = StringIO.new
    @key = SecureRandom.hex(16)
    @key_file = Tempfile.new("test_key")
    @key_file.write(@key)
    @key_file.flush

    @tmpdir = Dir.mktmpdir
    Rails.root = Pathname.new(@tmpdir)
    FileUtils.mkdir_p(File.join(@tmpdir, "config"))

    # Copy the key file to the expected location
    FileUtils.cp(@key_file.path, File.join(@tmpdir, "config", "master.key"))

    @service = Rails::Credentials::Conflict::EncryptionService.new(
      File.join(@tmpdir, "config", "master.key")
    )
  end

  def teardown
    @key_file.close!
    FileUtils.rm_rf(@tmpdir)
    Rails.root = nil
  end

  def test_yours_keeps_ours_version
    # Create encrypted credentials file to pass File.exist? check
    creds_path = File.join(@tmpdir, "config", "credentials.yml.enc")
    @service.save_encrypted("key: ours_value", creds_path)

    resolver = Rails::Credentials::Conflict::Resolver.new(nil, output: @output)

    # Stub git operations
    stub_validate_conflict!(resolver) do
      stub_get_version(resolver, :ours, @service.encrypt("key: ours_value")) do
        stub_stage(resolver) do
          resolver.yours
        end
      end
    end

    assert_includes @output.string, "your"
  end

  def test_yours_raises_when_empty
    creds_path = File.join(@tmpdir, "config", "credentials.yml.enc")
    @service.save_encrypted("placeholder", creds_path)

    resolver = Rails::Credentials::Conflict::Resolver.new(nil, output: @output)

    stub_validate_conflict!(resolver) do
      stub_get_version(resolver, :ours, "") do
        assert_raises(Rails::Credentials::Conflict::Error) { resolver.yours }
      end
    end
  end

  def test_theirs_keeps_theirs_version
    creds_path = File.join(@tmpdir, "config", "credentials.yml.enc")
    @service.save_encrypted("key: theirs_value", creds_path)

    resolver = Rails::Credentials::Conflict::Resolver.new(nil, output: @output)

    stub_validate_conflict!(resolver) do
      stub_get_version(resolver, :theirs, @service.encrypt("key: theirs_value")) do
        stub_stage(resolver) do
          resolver.theirs
        end
      end
    end

    assert_includes @output.string, "their"
  end

  def test_base_keeps_base_version
    creds_path = File.join(@tmpdir, "config", "credentials.yml.enc")
    @service.save_encrypted("key: base_value", creds_path)

    resolver = Rails::Credentials::Conflict::Resolver.new(nil, output: @output)

    stub_validate_conflict!(resolver) do
      stub_get_version(resolver, :base, @service.encrypt("key: base_value")) do
        stub_stage(resolver) do
          resolver.base
        end
      end
    end

    assert_includes @output.string, "base"
  end

  def test_resolve_auto_merges_identical_versions
    creds_path = File.join(@tmpdir, "config", "credentials.yml.enc")
    encrypted = @service.encrypt("key: same_value")
    @service.save_encrypted("key: same_value", creds_path)

    resolver = Rails::Credentials::Conflict::Resolver.new(nil, output: @output)

    stub_validate_conflict!(resolver) do
      git_handler = resolver.instance_variable_get(:@git_handler)
      git_handler.stub(:get_version, encrypted) do
        stub_stage(resolver) do
          resolver.resolve
        end
      end
    end

    assert_includes @output.string, "identical"
  end

  private

  def stub_validate_conflict!(resolver, &block)
    git_handler = resolver.instance_variable_get(:@git_handler)
    git_handler.stub(:validate_conflict!, nil, &block)
  end

  def stub_get_version(resolver, version, return_value, &block)
    git_handler = resolver.instance_variable_get(:@git_handler)
    git_handler.stub(:get_version, ->(_v) { return_value }) do
      yield
    end
  end

  def stub_stage(resolver, &block)
    git_handler = resolver.instance_variable_get(:@git_handler)
    git_handler.stub(:stage_resolved_file!, nil, &block)
  end
end
