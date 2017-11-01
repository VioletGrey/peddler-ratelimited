module PeddlerRateLimited
  class CreateInboundShipment < AmazonMWSApi

    SUBJECT = 'create_inbound_shipment'
    BURST_RATE = 30
    RESTORE_RATE = 0.5 #half a second
    MAX_HOURLY_RATE = 7200

    @backoff_strategy = (1..5).map {|i| i*RESTORE_RATE }

    @queue = :amazon_api_create_inbound_shipment

    def self.act(args)
      result = call_feed(args)

      process_feeds_list(args, result.parse)
    rescue Exception => e
      log_error('create_inbound_shipment', result, e, args)
    end

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
          log_error('create_inbound_shipment', result, e)
        end
      end
    end

    def self.process(args)
      processor = args[:processor]
      if processor.is_a?(String)
        processor = processor.safe_constantize.try(:new)
      end

      unless processor.present? && processor.respond_to?(:process)
        raise "Expecting a processor method for CreateInboundShipment!"
      end

      processor.update(args)
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
