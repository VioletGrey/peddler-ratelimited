module PeddlerRateLimited
  class EstimateTransportRequest < AmazonMWSApi

    SUBJECT = 'estimate_transport_request'
    BURST_RATE = 30
    RESTORE_RATE = 0.5 #half a second
    MAX_HOURLY_RATE = 7200

    @backoff_strategy = (1..5).map {|i| i*RESTORE_RATE }

    @queue = :amazon_api_estimate_transport_request

    def self.call_feed(args)
      AmazonMWS.instance.
        inbound_fulfillment.
        estimate_transport_request(args[:shipment_id])
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
          log_error(get_class_name.underscore, result, e)
        end
      end
    end
  end
end
