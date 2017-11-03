module PeddlerRateLimited

  class GetFeedSubmissionList < AmazonMWSApi

    SUBJECT = 'get_feed_submission_list'
    BURST_RATE = 10
    RESTORE_RATE = 45
    MAX_HOURLY_RATE = 80

    @backoff_strategy = (1..5).map {|i| i*RESTORE_RATE }

    @queue = :amazon_api_get_feed_submission_list_queue

    def self.act(args)
      begin
        result = call_feed(args)

        process_feeds_list(result.parse.with_indifferent_access)
      rescue Exception => e
        pp '0'*100
        pp e
        log_error(get_class_name.underscore, result, e, args)
      end
    end

    def self.call_feed(args)
      AmazonMWS.instance.products.
        get_feed_submission_list(args)
    end

    def self.process_feeds_list(result)
      queue_next_batch(result) if result["HasNext"] == "true"
      update_database_list(result)
    end

    def self.queue_next_batch(result)
      Resque.enqueue_in(
        GetFeedSubmissionListByNextToken::RESTORE_RATE.seconds,
        GetFeedSubmissionListByNextToken,
        result["NextToken"]
      )
    end

    def self.update_database_list(result)
      if (data = result["FeedSubmissionInfo"]).present?
        if data.count > 1
          data.each do |info|
            update_record(info)
          end
        else
          pp data
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
