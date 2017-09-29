module PeddlerRateLimited
  class SubmitFeedError < StandardError; end;

  class SubmitFeed < AmazonMWSApi

    SUBJECT = 'submit_feed'
    BURST_RATE = 15
    RESTORE_RATE = 120 #2 minutes
    MAX_HOURLY_RATE = 30

    @backoff_strategy = (1..5).map {|i| i*RESTORE_RATE }

    @queue = :amazon_api_submit_feed_queue

    #TODO change this args to hash
    def self.perform(data, feed_type, processor=nil, processor_method=nil, additional_data=nil)
      RateLimitter.new(self, {
        feed_type: feed_type,
        data: data,
        processor: processor,
        processor_method: processor_method,
        additional_data: additional_data
      }).submit
    end

    def self.act(args)
      feed_type = args[:feed_type]
      data = args[:data]
      processor = args[:processor]

      result = AmazonMWS.instance.products.submit_feed(data, feed_type)
      parsed_result = result.parse["FeedSubmissionInfo"]
      feed_submission_id = parsed_result["FeedSubmissionId"]
      feed_processing_status = parsed_result["FeedProcessingStatus"]

      unless feed_submission_id.present?
        error = SubmitFeedError.new("feed_submission_id is missing.")
        log_error('submit_feed', parsed_result, error, args)
        raise error
      else
        log_data(feed_submission_id: feed_submission_id,
                 feed_type: feed_type,
                 feed: data,
                 processor: processor,
                 processor_method: processor_method,
                 feed_processing_statuse: feed_processing_status,
                 additional_data: additional_data)

      end

      Resque.enqueue_in(
        5.minutes,
        GetFeedSubmissionResult,
        {
          feed_submission_id: feed_submission_id,
          email_template: 'amazon/get_feed_submission_result',
          processor: processor,
          processor_method: processor_method,
          additional_data: additional_data
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
