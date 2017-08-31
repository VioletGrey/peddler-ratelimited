require 'singleton'
require 'peddler'

module PeddlerRateLimited
  class AmazonMWS
    include Singleton

    def products
      MWS.feeds(
        primary_marketplace_id: ENV["MWS_MARKETPLACE_ID"],
        merchant_id: ENV["MWS_MERCHANT_ID"],
        aws_access_key_id: ENV["MWS_ACCESS_KEY_ID"],
        aws_secret_access_key: ENV["MWS_SECRET_KEY"],
        auth_token: ENV["MWS_AUTH_TOKEN"]
      )
    end

    def orders
      MWS.orders(
        primary_marketplace_id: ENV["MWS_MARKETPLACE_ID"],
        merchant_id: ENV["MWS_MERCHANT_ID"],
        aws_access_key_id: ENV["MWS_ACCESS_KEY_ID"],
        aws_secret_access_key: ENV["MWS_SECRET_KEY"],
        auth_token: ENV["MWS_AUTH_TOKEN"]
      )
    end

    def inbound_fulfillment
      MWS.fulfillment_inbound_shipment(
        primary_marketplace_id: ENV["MWS_MARKETPLACE_ID"],
        merchant_id: ENV["MWS_MERCHANT_ID"],
        aws_access_key_id: ENV["MWS_ACCESS_KEY_ID"],
        aws_secret_access_key: ENV["MWS_SECRET_KEY"],
        auth_token: ENV["MWS_AUTH_TOKEN"]
      )
    end

  end
end
