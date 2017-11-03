module PeddlerRateLimited

  class GetFeedSubmissionList < AmazonMWSApi

    SUBJECT = 'get_feed_submission_list'
    BURST_RATE = 10
    RESTORE_RATE = 45
    MAX_HOURLY_RATE = 80

    @backoff_strategy = (1..5).map {|i| i*RESTORE_RATE }

    @queue = :amazon_api_get_feed_submission_list_queue

    def self.call_feed(args)
      AmazonMWS.instance.products.
        get_feed_submission_list(args)
    end

    def self.process_feeds_list(args, result)
      queue_next_batch(result) if result["HasNext"] == "true"
      update_database_list(result)
    end

    def self.queue_next_batch(result)
      Resque.enqueue_in(
        GetFeedSubmissionListByNextToken::RESTORE_RATE.seconds,
        GetFeedSubmissionListByNextToken,
        {next_token: result["NextToken"]}
      )
    end

    def self.update_database_list(result)
      if (data = result["FeedSubmissionInfo"]).present?
        if data.count > 1
          data.each do |info|
            update_record(info)
          end
        else
          update_record(data)
        end
      end
    end

    #TODO
    #this should be optional
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
