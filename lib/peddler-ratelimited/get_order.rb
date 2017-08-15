module PeddlerRateLimited
  class GetOrder < AmazonMWSApi
    SUBJECT = 'get_order'
    BURST_RATE = 6
    RESTORE_RATE = 60 #1 minute
    MAX_HOURLY_RATE = 60

    @backoff_strategy = (1..5).map {|i| i*RESTORE_RATE }

    @queue = :amazon_api_get_order_queue

    def self.perform(amazon_order_id)
      binding.pry
      rateLimitter = RateLimitter.new(self, {
        amazon_order_id: amazon_order_id
      }).submit
    end

    def self.act(args)
      begin
        result = call_feed(args)
        process_feeds_list(result)
      rescue Exception => e
        log_error('get_order', result, e)
      end
    end

    def self.call_feed(args)
      AmazonMWS.instance.orders.get_order(args[:amazon_order_id])
    end

    def self.process_feeds_list(result)
      parsed = result.parse
      if (orders = parsed["Orders"]).present?
        #TODO
        do_something(orders["Order"])
      end
    end

    def self.do_something(order)
      #{
      #  "LatestShipDate"=>"2017-08-12T06:59:59Z",
      #  "OrderType"=>"StandardOrder",
      #  "PurchaseDate"=>"2017-08-09T19:02:33Z",
      #  "AmazonOrderId"=>"111-9995050-3333046",
      #  "BuyerEmail"=>"wcv7dnb8041qgm5@marketplace.amazon.com",
      #  "IsReplacementOrder"=>"false",
      #  "LastUpdateDate"=>"2017-08-09T19:32:48Z",
      #  "NumberOfItemsShipped"=>"0",
      #  "ShipServiceLevel"=>"Std Cont US Street Addr",
      #  "OrderStatus"=>"Unshipped",
      #  "SalesChannel"=>"Amazon.com",
      #  "ShippedByAmazonTFM"=>"false",
      #  "IsBusinessOrder"=>"false",
      #  "LatestDeliveryDate"=>"2017-08-19T06:59:59Z",
      #  "NumberOfItemsUnshipped"=>"1",
      #  "PaymentMethodDetails"=>{"PaymentMethodDetail"=>"Standard"},
      #  "BuyerName"=>"Violet Grey",
      #  "EarliestDeliveryDate"=>"2017-08-15T07:00:00Z",
      #  "OrderTotal"=>{"CurrencyCode"=>"USD", "Amount"=>"5.49"},
      #  "IsPremiumOrder"=>"false",
      #  "EarliestShipDate"=>"2017-08-10T07:00:00Z",
      #  "MarketplaceId"=>"ATVPDKIKX0DER",
      #  "FulfillmentChannel"=>"MFN",
      #  "PaymentMethod"=>"Other",
      #  "ShippingAddress"=> {
      #    "StateOrRegion"=>"CA",
      #    "City"=>"West Hollywood",
      #    "Phone"=>"3236567600",
      #    "CountryCode"=>"US",
      #    "PostalCode"=>"90069",
      #    "Name"=>"Ali Khan",
      #    "AddressLine1"=>"655 N La Peer Dr"
      #  },
      #  "IsPrime"=>"false",
      #  "ShipmentServiceLevelCategory"=>"Standard"
      #}
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
