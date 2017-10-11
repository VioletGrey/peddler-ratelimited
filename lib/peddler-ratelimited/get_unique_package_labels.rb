module PeddlerRateLimited
  class GetUniquePackageLabels < AmazonMWSApi

    SUBJECT = 'get_unique_package_labels'
    BURST_RATE = 30
    RESTORE_RATE = 0.5 #half a second
    MAX_HOURLY_RATE = 7200

    @backoff_strategy = (1..5).map {|i| i*RESTORE_RATE }

    @queue = :amazon_api_get_unique_package_labels

    def self.call_feed(args)
      AmazonMWS.instance.
        inbound_fulfillment.
        get_unique_package_labels(args[:shipment_id],
                                  args[:page_type],
                                  args[:package_labels_to_print]) #array of carton ids
    end

    #TODO clean up
    def self.process_feeds_list(args, result)
      if (document = result["TransportDocument"]).present?
        args[:document] = document
        begin
          process(args)
        rescue Exception => e
          log_error(get_class_name.underscore, result, e)
        end
      end
    end
  end
end
