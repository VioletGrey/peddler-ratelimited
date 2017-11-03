require "test_helper"
require 'peddler-ratelimited/rate_limitter'

class GetFeedSubmissionListTest < Minitest::Test
  def test_updates_database_when_info_exists
    result = Minitest::Mock.new
    result.expect :parse, {"FeedSubmissionInfo": [{"test" => "test"}]}

    args = {
      'feed_submission_id' => '1'
    }

    mock = Minitest::Mock.new
    mock.expect :call, nil, [[{"test" => "test"}]]

    PeddlerRateLimited::GetFeedSubmissionList.stub(:call_feed, result) do
      PeddlerRateLimited::GetFeedSubmissionList.stub(:update_record, mock) do
        PeddlerRateLimited::GetFeedSubmissionList.perform(args)
        assert_mock result
        mock.verify
      end
    end
  end

  def test_doesnot_update_database_when_info_is_null
    result = Minitest::Mock.new
    result.expect :parse, {"FeedSubmissionInfo": nil}

    mock = Minitest::Mock.new
    mock.expect :call, nil, [Hash]

    assert_raises MockExpectationError do
      PeddlerRateLimited::GetFeedSubmissionList.stub(:call_feed, result) do
        PeddlerRateLimited::GetFeedSubmissionList.stub(:update_record, mock) do
          PeddlerRateLimited::GetFeedSubmissionList.perform({})
          assert_mock result
          mock.verify
        end
      end
    end
  end

  def test_enqueue_if_has_next_exists
    result = Minitest::Mock.new
    result.expect :parse, {"HasNext" => "true"}

    args = {
      'feed_submission_id' => '1'
    }

    mock = Minitest::Mock.new
    mock.expect :call, nil, [{"HasNext" => "true"}]

    PeddlerRateLimited::GetFeedSubmissionList.stub(:call_feed, result) do
      PeddlerRateLimited::GetFeedSubmissionList.stub(:queue_next_batch, mock) do
        PeddlerRateLimited::GetFeedSubmissionList.perform(args)
        assert_mock result
        mock.verify
      end
    end

  end
end
