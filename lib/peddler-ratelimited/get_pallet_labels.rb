module PeddlerRateLimited
  class GetPalletLabels < AmazonMWSApi

    SUBJECT = 'get_pallet_labels'
    BURST_RATE = 30
    RESTORE_RATE = 0.5 #half a second
    MAX_HOURLY_RATE = 7200

    @backoff_strategy = (1..5).map {|i| i*RESTORE_RATE }

    @queue = :amazon_api_get_pallet_labels

    def self.call_feed(args)
      binding.pry
      AmazonMWS.instance.
        inbound_fulfillment.
        get_pallet_labels(args[:shipment_id],
                          args[:page_type],
                          args[:number_of_pallets])
    end

    #TODO clean up
    def self.process_feeds_list(args, result)
      if (document = result["TransportDocument"]).present?
        args[:document] = document
        begin
          process(args)
        rescue Exception => e
          log_error(get_class_name.underscore, e)
        end
      end
    end
  end
end
