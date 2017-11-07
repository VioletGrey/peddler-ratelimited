$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "peddler-ratelimited"

require "minitest/autorun"
require 'pp'

$redis_ratelimitter = Redis.connect :url => ENV["RATE_LIMITTER_REDIS_URL"]
