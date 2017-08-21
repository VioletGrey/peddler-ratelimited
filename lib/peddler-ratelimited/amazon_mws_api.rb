require 'peddler-ratelimited/amazon_mws'

module PeddlerRateLimited
  class AmazonMWSApi
    extend Resque::Plugins::ExponentialBackoff

    MAX_EXPIRY_RATE = 3600

    @retry_delay_multiplicand_min = 1
    @retry_delay_multiplicand_max = 1.5

    def self.perform(feed, data, feet_type)
      raise "Implement me!"
    end

    def self.act(args)
      raise "Implement me!"
    end

    def self.log_error(feed_name, result, error=nil)
      amazon_details = result.try(:to_xml).try(:to_s)
      Honeybadger.notify(error, {
        error_class: 'Amazon Feed Error',
        context: {
          feed: feed_name,
          amazon_details: amazon_details
        }
      })
      Rails.logger.error(amazon_details)
    end

    def self.feed_parameters
      {}
    end

    def self.email(args)
      @simple_spark ||= SimpleSpark::Client.new
      @simple_spark.transmissions.create({
        recipients:  [
          {
            address: {
              email: 'dev-alerts@violetgrey.com'
            }
          }
        ],
        content: {
          from: {
            name: 'VIOLET GREY',
            email: 'violetgrey@violetgrey.com'
          },
          subject: 'AmazonMWSApi Exception',
          html: args[:message]
        }
      })
    end

    def self.log_data(args)
      if args[:processor].present?
        (arg[:processor]).process(args)
      else
        AMWSFeedLog.create(feed_submission_id: args[:feed_submission_id],
                           feed_type: args[:feed_type],
                           data: args[:data])
      end
    end
  end
end
