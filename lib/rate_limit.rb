require 'ratelimit'

class Ratelimit
  class << self
    def instances
      @instances ||= {}
    end

    def initiate(bucket_name, bucket_expiry)
      binding.pry
      if instances[bucket_name].blank?
        instances[bucket_name] = self.new(bucket_name,
                                          {bucket_span: bucket_expiry,
                                           bucket_expiry: bucket_expiry,
                                           redis: $redis_ratelimitter})

      end

      instances[bucket_name]
    end
  end
end
