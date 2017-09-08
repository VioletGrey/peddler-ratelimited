module PeddlerRateLimited
  class PutTransportContent < AmazonMWSApi

    SUBJECT = 'put_transport_content'
    BURST_RATE = 30
    RESTORE_RATE = 0.5 #half a second
    MAX_HOURLY_RATE = 7200

    @backoff_strategy = (1..5).map {|i| i*RESTORE_RATE }

    @queue = :amazon_api_put_transport_content

    def self.perform(args = {})
      args.deep_symbolize_keys!
      RateLimitter.new(self, args).submit
    end

    def self.act(args)
      result = call_feed(args)

      process_feeds_list(args, result.parse)
    rescue Exception => e
      log_error('put_transport_content', result, e, args)
    end

    def self.call_feed(args)
      AmazonMWS.instance.
        inbound_fulfillment.
        put_transport_content(args[:shipment_id],
                              args[:is_partnered],
                              args[:shipment_type],
                              args[:transport_details])
    end

    #TODO clean up
    def self.process_feeds_list(args, result)
      if (status = result["TransportResult"]).present?
        begin
          process(shipment_id: args[:shipment_id],
                  transport_status: status["TransportStatus"],
                  processor: args[:processor],
                  processor_method: args[:processor_method])
        rescue Exception => e
          log_error('put_transport_content', e)
        end
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
  end
end
