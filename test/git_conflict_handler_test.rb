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

  def test_get_merge_labels_returns_all_three_labels
    # Call order for get_merge_labels:
    # 1. detect_head_ref: git rev-parse --verify MERGE_HEAD
    # 2. get_current_branch: git rev-parse --abbrev-ref HEAD
    # 3. get_short_sha("HEAD"): git rev-parse --short=8 HEAD
    # 4. get_merge_base_sha: git rev-parse HEAD
    # 5. get_merge_base_sha: git rev-parse MERGE_HEAD
    # 6. get_merge_base_sha: git merge-base ...
    # 7. get_incoming_branch: git name-rev --name-only MERGE_HEAD
    # 8. get_short_sha(head_ref): git rev-parse --short=8 MERGE_HEAD
    call_count = 0
    fake_capture2 = lambda { |*_args, **_kwargs|
      call_count += 1
      case call_count
      when 1 then ["abc123\n", mock_status(true)]
      when 2 then ["main\n", mock_status(true)]
      when 3 then ["abcd1234\n", mock_status(true)]
      when 4 then ["aaaa\n", mock_status(true)]
      when 5 then ["bbbb\n", mock_status(true)]
      when 6 then ["cccccccc\n", mock_status(true)]
      when 7 then ["feature\n", mock_status(true)]
      when 8 then ["ef567890\n", mock_status(true)]
      else ["", mock_status(false)]
      end
    }

    Open3.stub(:capture2, fake_capture2) do
      labels = @handler.get_merge_labels

      assert_equal "main (abcd1234)", labels[:ours]
      assert_match(/ancestor/, labels[:base])
      assert_equal "feature (ef567890)", labels[:theirs]
    end
  end

  def test_get_merge_labels_handles_failures_gracefully
    # When all git commands fail, detect_head_ref falls through to default "MERGE_HEAD".
    # We need enough mock_status calls for all the git commands.
    statuses = Array.new(10) { mock_status(false) }
    idx = 0
    fake_capture2 = lambda { |*_args, **_kwargs|
      result = ["", statuses[idx]]
      idx += 1
      result
    }

    Open3.stub(:capture2, fake_capture2) do
      labels = @handler.get_merge_labels

      assert_match(/HEAD/, labels[:ours])
      assert_match(/unknown/, labels[:ours])
      assert_match(/ancestor/, labels[:base])
      assert_match(/unknown/, labels[:base])
    end
  end

  private

  def mock_status(success)
    status = Minitest::Mock.new
    status.expect(:success?, success)
    status
  end
end
