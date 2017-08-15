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
        binding.pry
        result = call_feed(args)

        binding.pry
        process_feeds_list(result)
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
      binding.pry
      AmazonMWS.instance.orders.list_order_items(amazon_order_id)
    end

    def self.process_feeds_list(result)
      parsed = result.parse
      if (next_token = parsed["NextToken"]).present?
        Resque.enqueue_in(
          ListOrderItemsByNextToken::RESTORE_RATE.seconds,
          ListOrderItemsByNextToken,
          next_token
        )
      end

      if (order_items = parsed["OrderItems"]).present?
        #TODO
        do_somthing(order_items)
      end
    end

    def self.do_something(order_items)
      if order_items.count > 1
        order_items.each do |order_item|
          #do_something_with_order(order_item)
        end
      else
        #do_something_with_order(order_items)
      end
    end

    def self.do_something_with_order(order_items)
      #{
      #  "QuantityOrdered"=>"1",
      #  "Title"=>"Dr. Barbara Sturm Sun Drops",
      #  "ShippingTax"=>{
      #    "CurrencyCode"=>"USD",
      #    "Amount"=>"0.00"
      #  },
      #  "PromotionDiscount"=>{
      #    "CurrencyCode"=>"USD", "Amount"=>"0.00"
      #  },
      #  "ConditionId"=>"New",
      #  "ASIN"=>"B074HHLJVF",
      #  "SellerSKU"=>"DBS-E-07-500-01",
      #  "OrderItemId"=>"28315844070274",
      #  "GiftWrapTax"=>{
      #    "CurrencyCode"=>"USD",
      #    "Amount"=>"0.00"
      #  },
      #  "QuantityShipped"=>"0",
      #  "ShippingPrice"=>{
      #    "CurrencyCode"=>"USD",
      #    "Amount"=>"4.49"
      #  },
      #  "GiftWrapPrice"=>{
      #    "CurrencyCode"=>"USD",
      #    "Amount"=>"0.00"
      #  },
      #  "ConditionSubtypeId"=>"New",
      #  "ItemPrice"=>{
      #    "CurrencyCode"=>"USD",
      #    "Amount"=>"1.00"
      #  },
      #  "ItemTax"=>{
      #    "CurrencyCode"=>"USD",
      #    "Amount"=>"0.00"
      #  },
      #  "ShippingDiscount"=>{
      #    "CurrencyCode"=>"USD",
      #    "Amount"=>"0.00"
      #  }
      #}
    end
  end
end
