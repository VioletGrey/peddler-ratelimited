module PeddlerRateLimited
  class SubmitFeedError < StandardError; end;

  class SubmitFeed < AmazonMWSApi

    SUBJECT = 'submit_feed'
    BURST_RATE = 15
    RESTORE_RATE = 120 #2 minutes
    MAX_HOURLY_RATE = 30

    @backoff_strategy = (1..5).map {|i| i*RESTORE_RATE }

    @queue = :amazon_api_submit_feed_queue

    def self.perform(data, feed_type, processor=nil)
      rateLimitter = RateLimitter.new(self, {
        feed_type: feed_type,
        data: data,
        processor: processor
      }).submit
    end

    def self.act(args)
      feed_type = args[:feed_type]
      data = args[:data]
      processor = args[:processor]

      result = AmazonMWS.instance.products.submit_feed(data, feed_type)
      parsed_result = result.parse["FeedSubmissionInfo"]
      feed_submission_id = parsed_result["FeedSubmissionId"]

      unless feed_submission_id.present?
        error = SubmitFeedError.new("feed_submission_id is missing.")
        log_error('submit_feed', parsed_result, error)
        raise error
      else
        log_data(feed_submission_id: feed_submission_id,
                 feed_type: feed_type,
                 feed: data,
                 processor: processor)

      end

      Resque.enqueue_in(
        5.minutes,
        GetFeedSubmissionResult,
        {
          feed_submission_id: feed_submission_id,
          email_template: 'amazon/get_feed_submission_result'
        }
      )
    end

    def self.feed_parameters
      {
        bucket_expiry: MAX_EXPIRY_RATE,
        burst_rate: BURST_RATE,
        restore_rate: RESTORE_RATE,
        max_hourly_rate: MAX_HOURLY_RATE,
        subject: SUBJECT
      }
    end

  end
end
