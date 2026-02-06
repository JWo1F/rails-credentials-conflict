# frozen_string_literal: true

require "test_helper"

class MergeDriverTest < Minitest::Test
  def setup
    @key = SecureRandom.hex(16)
    @tmpdir = Dir.mktmpdir
    Rails.root = Pathname.new(@tmpdir)

    FileUtils.mkdir_p(File.join(@tmpdir, "config"))
    File.write(File.join(@tmpdir, "config", "master.key"), @key)

    @service = Rails::Credentials::Conflict::EncryptionService.new(
      File.join(@tmpdir, "config", "master.key")
    )
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
    Rails.root = nil
  end

  # --- extract_environment ---

  def test_extract_environment_returns_nil_for_default_credentials
    assert_nil Rails::Credentials::Conflict::MergeDriver.extract_environment(
      "config/credentials.yml.enc"
    )
  end

  def test_extract_environment_returns_staging
    assert_equal "staging", Rails::Credentials::Conflict::MergeDriver.extract_environment(
      "config/credentials/staging.yml.enc"
    )
  end

  def test_extract_environment_returns_production
    assert_equal "production", Rails::Credentials::Conflict::MergeDriver.extract_environment(
      "config/credentials/production.yml.enc"
    )
  end

  def test_extract_environment_returns_nil_for_unrelated_path
    assert_nil Rails::Credentials::Conflict::MergeDriver.extract_environment(
      "some/other/file.yml.enc"
    )
  end

  # --- call: auto-merge non-overlapping changes ---

  def test_auto_merges_non_overlapping_changes
    base_yaml    = "line1: base\nline2: base\nline3: base\nline4: base\nline5: base"
    ours_yaml    = "line1: ours_changed\nline2: base\nline3: base\nline4: base\nline5: base"
    theirs_yaml  = "line1: base\nline2: base\nline3: base\nline4: base\nline5: theirs_changed"

    base_file   = write_temp_encrypted(base_yaml)
    ours_file   = write_temp_encrypted(ours_yaml)
    theirs_file = write_temp_encrypted(theirs_yaml)

    result = Rails::Credentials::Conflict::MergeDriver.call(
      base_file, ours_file, theirs_file, "config/credentials.yml.enc"
    )

    assert_equal 0, result

    merged = @service.decrypt(File.binread(ours_file))
    assert_includes merged, "line1: ours_changed"
    assert_includes merged, "line5: theirs_changed"
  end

  # --- call: conflict returns 1 ---

  def test_returns_1_on_real_conflict
    base_yaml   = "key: base_value"
    ours_yaml   = "key: ours_value"
    theirs_yaml = "key: theirs_value"

    base_file   = write_temp_encrypted(base_yaml)
    ours_file   = write_temp_encrypted(ours_yaml)
    theirs_file = write_temp_encrypted(theirs_yaml)

    result = Rails::Credentials::Conflict::MergeDriver.call(
      base_file, ours_file, theirs_file, "config/credentials.yml.enc"
    )

    assert_equal 1, result
  end

  # --- call: identical content ---

  def test_returns_0_for_identical_content
    yaml = "key: same_value"

    base_file   = write_temp_encrypted(yaml)
    ours_file   = write_temp_encrypted(yaml)
    theirs_file = write_temp_encrypted(yaml)

    result = Rails::Credentials::Conflict::MergeDriver.call(
      base_file, ours_file, theirs_file, "config/credentials.yml.enc"
    )

    assert_equal 0, result
  end

  # --- call: environment-specific credentials ---

  def test_works_with_environment_specific_credentials
    FileUtils.mkdir_p(File.join(@tmpdir, "config", "credentials"))
    File.write(File.join(@tmpdir, "config", "credentials", "staging.key"), @key)

    staging_service = Rails::Credentials::Conflict::EncryptionService.new(
      File.join(@tmpdir, "config", "credentials", "staging.key")
    )

    base_yaml   = "line1: base\nline2: base\nline3: base\nline4: base\nline5: base"
    ours_yaml   = "line1: ours\nline2: base\nline3: base\nline4: base\nline5: base"
    theirs_yaml = "line1: base\nline2: base\nline3: base\nline4: base\nline5: theirs"

    base_file   = write_temp_encrypted(base_yaml, staging_service)
    ours_file   = write_temp_encrypted(ours_yaml, staging_service)
    theirs_file = write_temp_encrypted(theirs_yaml, staging_service)

    result = Rails::Credentials::Conflict::MergeDriver.call(
      base_file, ours_file, theirs_file, "config/credentials/staging.yml.enc"
    )

    assert_equal 0, result
  end

  private

  def write_temp_encrypted(yaml_content, service = @service)
    file = Tempfile.new(["merge_driver_test", ".yml.enc"])
    file.binmode
    file.write(service.encrypt(yaml_content))
    file.flush
    file.close
    file.path
  end
end
