module PeddlerRateLimited
  class ListOrderItems < AmazonMWSApi

    SUBJECT = 'list_order_items'
    BURST_RATE = 30
    RESTORE_RATE = 2
    #MAX_HOURLY_RATE = 60

    @backoff_strategy = (1..5).map {|i| i*RESTORE_RATE }

    @queue = :amazon_api_list_order_items_queue

    def self.perform(args = {})
      RateLimitter.new(self, args).submit
    end

    def self.act(args)
      begin
        result = call_feed(args)

        process_feeds_list(result, args[:processor])
      rescue Exception => e
        log_error('list_order_items', result, e)
      end
    end

    def self.feed_parameters
      super.merge(
        bucket_expiry: MAX_EXPIRY_RATE,
        burst_rate: BURST_RATE,
        restore_rate: RESTORE_RATE,
        #max_hourly_rate: MAX_HOURLY_RATE,
        subject: SUBJECT
      )
    end

    def self.call_feed(args)
      AmazonMWS.instance.orders.list_order_items(args[:amazon_order_id])
    end

    def self.process_feeds_list(result, processor)
      parsed = result.parse
      if (next_token = parsed["NextToken"]).present?
        Resque.enqueue_in(
          ListOrderItemsByNextToken::RESTORE_RATE.seconds,
          ListOrderItemsByNextToken,
          next_token,
          processor
        )
      end

      if (order_items = parsed["OrderItems"]).present?
        amazon_order_id = parsed["AmazonOrderId"]
        process_orders({
          order_items: order_items,
          amazon_order_id: amazon_order_id,
          processor: processor
        })
      end
    end

    def self.process_orders(args)
      processor = args[:processor]
      if processor.is_a?(String)
        processor = processor.safe_constantize.try(:new)
      end

      unless processor.present? && processor.respond_to?(:process)
        raise "Expecting a processor method!"
      end

      order_items = args[:order_items]
      amazon_order_id = args[:amazon_order_id]

      if order_items.count > 1
        order_items.each do |order_item|
          processor.process(order_item["OrderItem"], amazon_order_id)
        end
      else
        processor.process(order_items["OrderItem"], amazon_order_id)
      end

      processor.publish(amazon_order_id)
    end

  end
end
