require "test_helper"
require 'peddler-ratelimited/rate_limitter'

class Fake
  def testing(args)
    'test'  
  end
end

class RateLimitterTest < Minitest::Test
  def test_it_raises_error_when_rate_is_exceeded
    args = {
      bucket_expiry: 600,
      burst_rate: 2,
      restore_rate: 5,
      max_hourly_rate: 10,
      subject: 'RateLimitter Test'
    }

    feed = Minitest::Mock.new
    assert_raises PeddlerRateLimited::RateLimitError do
      2.times do 
        feed.expect :act, true, [args]
        feed.expect :feed_parameters, args

        PeddlerRateLimited::RateLimitter.new(feed, args).submit 
      end
    end
  end

  def test_it_raises_no_error_when_rate_is_not_exceeded
    args = {
      bucket_expiry: 600,
      burst_rate: 5,
      restore_rate: 5,
      max_hourly_rate: 10,
      subject: 'RateLimitter Test'
    }

    feed = Minitest::Mock.new
    2.times do 
      feed.expect :act, true, [args]
      feed.expect :feed_parameters, args

      PeddlerRateLimited::RateLimitter.new(feed, args).submit 
    end
  end

  def test_process_raises_error_when_processor_missing
    err = assert_raises RuntimeError do
      PeddlerRateLimited::AmazonMWSApi.process({})
    end

    assert_match(/Expecting a processor method for PeddlerRateLimited::AmazonMWSApi!/, err.message)
  end

  def test_process_raises_error_when_processor_without_process
    err = assert_raises RuntimeError do
      PeddlerRateLimited::AmazonMWSApi.process({processor: 'String'})
    end

    assert_match(/Expecting a processor method for PeddlerRateLimited::AmazonMWSApi!/, err.message)
  end

  def test_process_when_processor_without_process_but_with_method
    assert_equal PeddlerRateLimited::AmazonMWSApi.process({
      processor: 'Fake',
      processor_method: 'testing'
    }), 'test'
  end

end
