module PeddlerRateLimited
  class GetFeedSubmissionResult < AmazonMWSApi

    SUBJECT = 'get_feed_submission_results'
    BURST_RATE = 15
    RESTORE_RATE = 60 #1 minute
    MAX_HOURLY_RATE = 60

    @backoff_strategy = (1..5).map {|i| i*RESTORE_RATE }

    @queue = :amazon_api_get_feed_submission_result_queue

    def self.perform(args)
      args.symbolize_keys!
      RateLimitter.new(self, {
        feed_submission_id: args[:feed_submission_id],
        email_template: args[:email_template],
        processor: args[:processor],
        processor_method: args[:processor_method],
        additional_data: args[:additional_data]
      }).submit
    end

    #TODO clean up
    def self.act(args)
      feed_submission_id = args[:feed_submission_id]
      email_template = args[:email_template]

      result = AmazonMWS.instance.products.
        get_feed_submission_result(feed_submission_id)
      parsed_report = result.parse["ProcessingReport"]
      if (report_code = parsed_report["StatusCode"]) == 'Complete'
        if email_template.present?
          message = ApplicationController.render(
            :template => email_template,
            :layout => nil,
            :assigns => { parsed_report: parsed_report }
          )
        end

        error = parsed_report['ProcessingSummary']['MessagesWithError']
        args['error'] = error if error != '0' 
        if args[:processor].present?
          args[:feed_processing_status] = report_code
          process(args)
        end
      else
        log_error('get_feed_submission_result', parsed_report, nil, args)

        message = "DocumentTransactionID: #{feed_submission_id}\n"
        message += "Status Code: #{report_code}\n"
      end

      email(message: message) if email_template.present?
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
  end
end
