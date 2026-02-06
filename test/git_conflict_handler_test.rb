# frozen_string_literal: true

require "test_helper"

class GitConflictHandlerTest < Minitest::Test
  def setup
    @credentials_path = "/app/config/credentials.yml.enc"
    @relative_path = "config/credentials.yml.enc"
    @handler = Rails::Credentials::Conflict::GitConflictHandler.new(@credentials_path, @relative_path)
  end

  def test_validate_conflict_raises_when_file_missing
    File.stub(:exist?, false) do
      error = assert_raises(Rails::Credentials::Conflict::Error) { @handler.validate_conflict! }
      assert_match(/Credentials file not found/, error.message)
    end
  end

  def test_validate_conflict_raises_when_no_conflict
    File.stub(:exist?, true) do
      Open3.stub(:capture2, ["M  #{@credentials_path}\n", mock_status(true)]) do
        error = assert_raises(Rails::Credentials::Conflict::Error) { @handler.validate_conflict! }
        assert_match(/No git conflict detected/, error.message)
      end
    end
  end

  def test_validate_conflict_succeeds_for_uu_status
    File.stub(:exist?, true) do
      Open3.stub(:capture2, ["UU #{@credentials_path}\n", mock_status(true)]) do
        @handler.validate_conflict! # should not raise
      end
    end
  end

  def test_validate_conflict_succeeds_for_aa_status
    File.stub(:exist?, true) do
      Open3.stub(:capture2, ["AA #{@credentials_path}\n", mock_status(true)]) do
        @handler.validate_conflict! # should not raise
      end
    end
  end

  def test_get_version_ours
    Open3.stub(:capture2, ["encrypted_ours", mock_status(true)]) do
      assert_equal "encrypted_ours", @handler.get_version(:ours)
    end
  end

  def test_get_version_theirs
    Open3.stub(:capture2, ["encrypted_theirs", mock_status(true)]) do
      assert_equal "encrypted_theirs", @handler.get_version(:theirs)
    end
  end

  def test_get_version_base
    Open3.stub(:capture2, ["encrypted_base", mock_status(true)]) do
      assert_equal "encrypted_base", @handler.get_version(:base)
    end
  end

  def test_get_version_returns_empty_on_failure
    Open3.stub(:capture2, ["", mock_status(false)]) do
      assert_equal "", @handler.get_version(:base)
    end
  end

  def test_get_version_raises_for_unknown
    error = assert_raises(Rails::Credentials::Conflict::Error) { @handler.get_version(:unknown) }
    assert_match(/Unknown version/, error.message)
  end

  def test_stage_resolved_file_succeeds
    Open3.stub(:capture2, ["", mock_status(true)]) do
      @handler.stage_resolved_file! # should not raise
    end
  end

  def test_stage_resolved_file_raises_on_failure
    Open3.stub(:capture2, ["error", mock_status(false)]) do
      error = assert_raises(Rails::Credentials::Conflict::Error) { @handler.stage_resolved_file! }
      assert_match(/Failed to stage/, error.message)
    end
  end

  private

  def mock_status(success)
    status = Minitest::Mock.new
    status.expect(:success?, success)
    status
  end
end
