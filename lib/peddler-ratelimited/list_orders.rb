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

        process_feeds_list(result, args[:processor])
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

    def self.process_feeds_list(result, processor)
      parsed = result.parse

      last_run_time = parsed["CreatedBefore"] || parsed["LastUpdatedBefore"]
      $redis.set('amazon_order_sync_last_run_time', last_run_time) if last_run_time.present?

      if parsed["HasNext"] == "true"
        Resque.enqueue_in(
          ListOrdersByNextToken::RESTORE_RATE.seconds,
          ListOrdersByNextToken,
          parsed["NextToken"],
          processor
        )
      end

      if (orders = parsed["Orders"]).present?
        process_orders(orders, processor)
      end
    end

    def self.process_orders(parsed, processor)
      unless processor.present? && processor.respond_to?(:process)
        raise "Expecting a processor method!"
      end

      if parsed.count > 1
        parsed.each do |order|
          get_items(order, processor)
        end
      else
        get_items(parsed, processor)
      end
    end

    def get_items(order, processor)
      processor.process(order["Order"])
      Resque.enqueue_in(
        ListOrderItems::RESTORE_RATE.seconds,
        {
          amazon_order_id: order["Order"]["AmazonOrderId"]
          processor: processor
        }
      )
  end
end
