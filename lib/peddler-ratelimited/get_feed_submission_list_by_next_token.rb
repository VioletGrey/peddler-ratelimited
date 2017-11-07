module PeddlerRateLimited
  class GetFeedSubmissionListByNextToken < GetFeedSubmissionList

    SUBJECT = 'get_feed_submission_list_by_next_token'
    BURST_RATE = 20
    RESTORE_RATE = 2
    MAX_HOURLY_RATE = 1800

    @backoff_strategy = (1..5).map {|i| i*RESTORE_RATE }

    @queue = :amazon_api_get_feed_submission_list_by_next_token_queue

    def self.call_feed(args)
      next_token = args[:next_token]
      AmazonMWS.instance.products.
        get_feed_submission_list_by_next_token(next_token)
    end
  end
end
