module PeddlerRateLimited
  class ListOrdersByNextToken < ListOrders

    SUBJECT = 'list_orders_by_next_token'
    BURST_RATE = 6
    RESTORE_RATE = 60
    MAX_HOURLY_RATE = 60

    @backoff_strategy = (1..5).map {|i| i*RESTORE_RATE }

    @queue = :amazon_api_list_orders_by_next_token_queue

    def self.perform(next_token, processor)
      RateLimitter.new(self, {
        next_token: next_token,
        processor: processor
      }).submit
    end

    def self.act(args)
      begin
        next_token = args[:next_token]
        result = call_feed(args)
        process_feeds_list(result, args[:processor])
      rescue Exception => e
        log_error('list_orders_by_next_token', result, e, args)
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
      next_token = args[:next_token]
      AmazonMWS.instance.orders.
        list_orders_by_next_token(next_token)
    end
  end
end
