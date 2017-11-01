require 'rate_limit'


module PeddlerRateLimited
  class RateLimitError < StandardError; end;

  class RateLimitter
    def initialize(feed, args)
      @feed = feed
      @args = args
      @params = feed.feed_parameters

      @bucket_expiry = @params[:bucket_expiry]
      @burst_rate = @params[:burst_rate]
      @restore_rate = @params[:restore_rate]
      @max_hourly_rate = @params[:max_hourly_rate] || @burst_rate*@restore_rate
      @subject = @params[:subject]
      @hour_duration = @params[:hour_duration] || 3600

      @bucket_name = 'amazon'
      @ratelimit = Ratelimit.initiate(@bucket_name, @bucket_expiry)

      @threshold = (@burst_rate*0.8).to_i
      @count = @ratelimit.count(@subject, @threshold) || 0
      @hr_max_exceeded = false
    end

    def submit
      feed_name = "#{@bucket_name}:#{@subject}"
      rate_info =  "Burst Rate: #{@burst_rate}, Restore Rate: #{@restore_rate}, Count: #{@count}, Threshold: #{@threshold}, Max Hourly Rate: #{@max_hourly_rate}, Hourly Rate Exceeded: #{@hr_max_exceeded}"

      if @count >= @threshold || @hr_max_exceeded 
        raise RateLimitError, "#{feed_name} rate limit exceeded - #{rate_info}."
      end

      begin
        @feed.act(@args)
        #TODO
        #incorporate API rate limit info returned by aws
        #to enhance enforcement of rate limits
        @ratelimit.add(@subject)

        @count = @ratelimit.count(@subject, @threshold)
        @hr_max_exceeded = @ratelimit.exceeded?(@subject, threshold: @max_hourly_rate, interval: @hour_duration)
        #TODO
        #look for QuotaExceeded error
      rescue Exception => e
        Rails.logger.error e.backtrace.join("\n")
        Honeybadger.notify(e, {
          error_class: 'Amazon Feed Error',
          context: {
            feed: feed_name,
            parameters: @params,
            arguments: @args
          #TODO
          #amazon_details: order_details.try(:to_xml).try(:to_s)
          }
        })
      end
    end 
  end
end
