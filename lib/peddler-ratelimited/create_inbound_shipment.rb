module PeddlerRateLimited
  class CreateInboundShipment < AmazonMWSApi

    SUBJECT = 'create_inbound_shipment'
    BURST_RATE = 30
    RESTORE_RATE = 0.5 #half a second
    MAX_HOURLY_RATE = 7200

    @backoff_strategy = (1..5).map {|i| i*RESTORE_RATE }

    @queue = :amazon_api_create_inbound_shipment

    def self.call_feed(args)
      items = args[:inbound_shipment_items]
      AmazonMWS.instance.
        inbound_fulfillment.
        create_inbound_shipment(args[:shipment_id],
                                args[:inbound_shipment_header],
                                inbound_shipment_items: items) 
    end

    def self.process_feeds_list(args, result)
      if result["ShipmentId"].present?
        begin
          process(args)
        rescue Exception => e
          log_error(get_class_name.underscore, result, e)
        end
      end
    end

  end
end
