# frozen_string_literal: true

require "test_helper"

class MergeStrategyTest < Minitest::Test
  def setup
    @encryption_service = Object.new
    @strategy = Rails::Credentials::Conflict::MergeStrategy.new(@encryption_service)
    @labels = {
      ours: "main (abc12345)",
      base: "ancestor (00000000)",
      theirs: "feature (def67890)"
    }
  end

  def test_detects_start_conflict_markers
    content = "<<<<<<< HEAD\nfoo\n=======\nbar\n>>>>>>> branch"
    assert @strategy.has_conflict_markers?(content)
  end

  def test_detects_end_conflict_markers
    assert @strategy.has_conflict_markers?("some content >>>>>>> branch")
  end

  def test_no_conflict_markers_in_clean_content
    refute @strategy.has_conflict_markers?("clean: content\n")
  end

  def test_validate_yaml_accepts_valid
    @strategy.validate_yaml!("key: value\nnested:\n  foo: bar")
  end

  def test_validate_yaml_raises_for_invalid
    error = assert_raises(Rails::Credentials::Conflict::Error) do
      @strategy.validate_yaml!("key: [invalid")
    end
    assert_match(/not valid YAML/, error.message)
  end

  def test_validate_yaml_accepts_empty
    @strategy.validate_yaml!("")
  end

  def test_create_conflict_markers_with_conflicts
    base = "key: base_value"
    ours = "key: ours_value"
    theirs = "key: theirs_value"

    result = @strategy.create_conflict_markers(ours, base, theirs, labels: @labels)
    assert result[:has_conflicts]
    assert_includes result[:content], "<<<<<<<"
    assert_includes result[:content], ">>>>>>>"
  end

  def test_create_conflict_markers_clean_merge
    base = "line1: base\nline2: base\nline3: base\nline4: base\nline5: base"
    ours = "line1: ours_changed\nline2: base\nline3: base\nline4: base\nline5: base"
    theirs = "line1: base\nline2: base\nline3: base\nline4: base\nline5: theirs_changed"

    result = @strategy.create_conflict_markers(ours, base, theirs, labels: @labels)
    refute result[:has_conflicts]
    assert_includes result[:content], "line1: ours_changed"
    assert_includes result[:content], "line5: theirs_changed"
  end
end
