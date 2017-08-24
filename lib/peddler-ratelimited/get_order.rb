module PeddlerRateLimited
  class GetOrder < AmazonMWSApi
    SUBJECT = 'get_order'
    BURST_RATE = 6
    RESTORE_RATE = 60 #1 minute
    MAX_HOURLY_RATE = 60

    @backoff_strategy = (1..5).map {|i| i*RESTORE_RATE }

    @queue = :amazon_api_get_order_queue

    def self.perform(amazon_order_id)
      rateLimitter = RateLimitter.new(self, {
        amazon_order_id: amazon_order_id
      }).submit
    end

    def self.act(args)
      begin
        result = call_feed(args)
        process_feeds_list(result)
      rescue Exception => e
        log_error('get_order', result, e, args)
      end
    end

    def self.call_feed(args)
      AmazonMWS.instance.orders.get_order(args[:amazon_order_id])
    end

    def self.process_feeds_list(result)
      parsed = result.parse
      if (orders = parsed["Orders"]).present?
        #TODO
        #do_something(orders["Order"])
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
