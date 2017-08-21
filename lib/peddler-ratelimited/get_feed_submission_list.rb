module PeddlerRateLimited

  class GetFeedSubmissionList < AmazonMWSApi

    SUBJECT = 'get_feed_submission_list'
    BURST_RATE = 10
    RESTORE_RATE = 45
    MAX_HOURLY_RATE = 80

    @backoff_strategy = (1..5).map {|i| i*RESTORE_RATE }

    @queue = :amazon_api_get_feed_submission_list_queue

    def self.perform(args = {})
      PeddlerRateLimited::RateLimitter.new(self, args).submit
    end

    def self.act(args)
      begin
        result = call_feed(args)

        process_feeds_list(result)
      rescue Exception => e
        log_error('get_feed_submission_list', result, e)
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
      AmazonMWS.instance.products.
        get_feed_submission_list(args)
    end

    def self.process_feeds_list(result)
      parsed = result.parse
      if parsed["HasNext"] == "true"
        Resque.enqueue_in(
          GetFeedSubmissionListByNextToken::RESTORE_RATE.seconds,
          GetFeedSubmissionListByNextToken,
          parsed["NextToken"]
        )
      end
      update_database_list(parsed)
    end

    def self.update_database_list(parsed)
      if (data = parsed["FeedSubmissionInfo"]).present?
        if data.count > 1
          data.each do |info|
            update_record(info)
          end
        else
          update_record(data)
        end
      end
    end

    def self.update_record(data)
      feed = AMWSFeedStatusLog.find_or_initialize_by(feed_submission_id: info['FeedSubmissionId'])
      feed.feed_type = info['FeedType']
      feed.feed_status = info['FeedProcessingStatus']
      feed.started_processing_at = info['StartedProcessingDate']
      feed.submitted_at = info['SubmittedDate']
      feed.completed_processing_at = info['CompletedProcessingDate']
      feed.save
    end
  end
end
