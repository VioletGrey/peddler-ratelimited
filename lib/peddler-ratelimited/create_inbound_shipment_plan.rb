module PeddlerRateLimited
  class CreateInboundShipmentPlan < AmazonMWSApi

    SUBJECT = 'create_inbound_shipment_plan'
    BURST_RATE = 30
    RESTORE_RATE = 0.5 #half a second
    MAX_HOURLY_RATE = 7200

    @backoff_strategy = (1..5).map {|i| i*RESTORE_RATE }

    @queue = :amazon_api_create_inbound_shipment_plan

    def self.perform(args = {})
      args.deep_symbolize_keys!
      RateLimitter.new(self, args).submit
    end

    def self.act(args)
      result = call_feed(args)

      process_feeds_list(result, args[:processor])
    rescue Exception => e
      log_error('create_inbound_shipment_plan', result, e, args)
    end

    def self.call_feed(args)
      AmazonMWS.instance.
        inbound_fulfillment.
        create_inbound_shipment_plan(args[:ship_from_address],
                                     args[:inbound_shipment_plan_request_items])
    end

    def self.process_feeds_list(result, processor)
      parsed = result.parse
      if (plans = parsed["InboundShipmentPlans"]).present?
        begin
          process_plans(plans, processor)
        rescue Exception => e
          log_error('create_inbound_shipment_plan', plans, e)
        end
      end
    end

    def self.process_plans(plans, processor)
      if processor.is_a?(String)
        processor = processor.safe_constantize.try(:new)
      end

      unless processor.present? && processor.respond_to?(:process)
        raise "Expecting a processor method for InboundShipmentPlans!"
      end

      Array(plans["member"]).each do |plan|
        processor.process(plan)
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
