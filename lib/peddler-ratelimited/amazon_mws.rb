require 'singleton'
#require 'pay_with_amazon'
require 'peddler'

module PeddlerRateLimited
  class AmazonMWS
    include Singleton

    #def payments
    #  PayWithAmazon::Client.new(
    #    ENV["AMWS_MERCHANT_ID"],
    #    ENV["AMWS_ACCESS_KEY_ID"],
    #    ENV["AMWS_SECRET_KEY"],
    #    sandbox: !Rails.env.production?,
    #    region: :us,
    #    currency_code: :usd
    #  )
    #end

    #def login
    #  PayWithAmazon::Login.new(
    #    ENV["AMWS_CLIENT_ID"],
    #    region: :us,
    #    sandbox: !Rails.env.production?
    #  )
    #end

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

    def initialize
    end

  end
end
