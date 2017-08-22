module PeddlerRateLimited
  class ListOrders < AmazonMWSApi

    SUBJECT = 'list_orders'
    BURST_RATE = 6
    RESTORE_RATE = 60
    MAX_HOURLY_RATE = 60

    @backoff_strategy = (1..5).map {|i| i*RESTORE_RATE }

    @queue = :amazon_api_list_orders_queue

    def self.perform(args = {})
      RateLimitter.new(self, args).submit
    end

    def self.act(args)
      begin
        result = call_feed(args)

        process_feeds_list(result, args[:order_processor], args[:order_item_processor])
      rescue Exception => e
        log_error('list_orders', result, e)
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

    def self.call_feed(args)
      AmazonMWS.instance.orders.list_orders(args)
    end

    def self.process_feeds_list(result, order_processor, order_item_processor)
      parsed = result.parse

      last_run_time = parsed["CreatedBefore"] || parsed["LastUpdatedBefore"]
      $redis.set('amazon_order_sync_last_run_time', last_run_time) if last_run_time.present?

      if parsed["HasNext"] == "true"
        Resque.enqueue_in(
          ListOrdersByNextToken::RESTORE_RATE.seconds,
          ListOrdersByNextToken,
          parsed["NextToken"],
          order_processor
        )
      end

      if (orders = parsed["Orders"]).present?
        begin
          process_orders(orders, order_processor, order_item_processor)
        rescue Exception => e
          log_error('list_orders', orders, e)
        end
      end
    end

    def self.process_orders(parsed, order_processor, order_item_processor)
      unless order_processor.present? && order_processor.respond_to?(:process)
        raise "Expecting a processor method for orders!"
      end
      unless order_item_processor.present? && order_item_processor.respond_to?(:process)
        raise "Expecting a processor method for order_items!"
      end
      orders = parsed["Order"]
      if orders.count > 1
        orders.each do |order|
          get_items(order, order_processor, order_item_processor)
        end
      else
        get_items(orders, order_processor, order_item_processor)
      end
    end

    def self.get_items(order, order_processor, order_item_processor)
      order_processor.process(order)
      Resque.enqueue_in(
        ListOrderItems::RESTORE_RATE.seconds,
        ListOrderItems,
        {
          amazon_order_id: order["AmazonOrderId"],
          processor: order_item_processor
        }
      )
    end
  end
end
