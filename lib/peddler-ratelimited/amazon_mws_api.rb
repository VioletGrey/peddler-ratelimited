require 'peddler-ratelimited/amazon_mws'

module PeddlerRateLimited
  class AmazonMWSApi
    extend Resque::Plugins::ExponentialBackoff

    MAX_EXPIRY_RATE = 3600

    @retry_delay_multiplicand_min = 1
    @retry_delay_multiplicand_max = 1.5

    def self.perform(args = {})
      args.deep_symbolize_keys!
      RateLimitter.new(self, args).submit
    end

    def self.log_error(feed_name, result, error=nil, args={})
      amazon_details = result.try(:to_xml).try(:to_s)
      Honeybadger.notify(error, {
        error_class: 'Amazon Feed Error',
        context: {
          feed: feed_name,
          amazon_details: amazon_details,
          args: args
        }
      })
      Rails.logger.error(amazon_details)
    end

    def self.feed_parameters
      {
        bucket_expiry: MAX_EXPIRY_RATE,
        burst_rate: self.const_get(:BURST_RATE),
        restore_rate: self.const_get(:RESTORE_RATE),
        max_hourly_rate: self.const_get(:MAX_HOURLY_RATE),
        subject: self.const_get(:SUBJECT)
      }  
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

    def self.act(args)
      result = call_feed(args)

      process_feeds_list(args, result.parse)
    rescue Exception => e
      log_error(get_class_name.underscore, result, e, args)
    end

    def self.log_data(args)
      processor = args[:processor]
      if processor.present?
        if processor.is_a?(String)
          processor = args[:processor].safe_constantize.try(:new)
        end
        process(args)
      else
        AMWSFeedLog.create(feed_submission_id: args[:feed_submission_id],
                           feed_type: args[:feed_type],
                           data: args[:data])
      end
    end

    def self.process(args)
      processor = args[:processor]
      method = args[:processor_method] || ''

      if processor.is_a?(String)
        processor = processor.safe_constantize.try(:new)
      end

      unless processor.present? &&
          (processor.respond_to?(:process) || processor.respond_to?(method))
        raise "Expecting a processor method for #{self.name}!"
      end

      if method.present?
        processor.send(method, args)
      else
        processor.process(args)
      end
    end

    def self.get_class_name
      self.name.split('::').last
    end
  end
end
