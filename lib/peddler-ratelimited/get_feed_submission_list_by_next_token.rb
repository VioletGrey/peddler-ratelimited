module PeddlerRateLimited
  class GetFeedSubmissionListByNextToken < GetFeedSubmissionList

    SUBJECT = 'get_feed_submission_list_by_next_token'
    BURST_RATE = 20
    RESTORE_RATE = 2
    MAX_HOURLY_RATE = 1800

    @backoff_strategy = (1..5).map {|i| i*RESTORE_RATE }

    @queue = :amazon_api_get_feed_submission_list_by_next_token_queue

    def self.perform(next_token)
      RateLimitter.new(self, {next_token: next_token}).submit
    end

    def self.act(args)
      begin
        next_token = args[:next_token]
        result = call_feed(args)
        process_feeds_list(result)
      rescue Exception => e
        log_error('get_feed_submission_list_by_next_token', result, e, args)
      end
    end

    def self.feed_parameters
      super.merge(
        bucket_expiry: MAX_EXPIRY_RATE,
        burst_rate: BURST_RATE,
        restore_rate: RESTORE_RATE,
        max_hourly_rate: MAX_HOURLY_RATE,
        subject: SUBJECT
      )
    end

    def self.call_feed(args)
      next_token = args[:next_token]
      AmazonMWS.instance.products.
        get_feed_submission_list_by_next_token(next_token)
    end
  end
end
