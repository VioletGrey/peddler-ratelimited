require "test_helper"
require 'peddler-ratelimited/rate_limitter'

class EstimateTransportRequestTest < Minitest::Test
  def test_process_calles_when_transport_result_exists
    result = Minitest::Mock.new
    result.expect :parse, {"TransportResult": 'test'}

    args = {
      shipment_id: 'shipment_id',
      transport_status: nil,
      processor: 'processor',
      processor_method: 'processor_method'
    }

    mock = Minitest::Mock.new
    mock.expect :call, nil, [args]

    PeddlerRateLimited::EstimateTransportRequest.stub(:call_feed, result) do
      PeddlerRateLimited::EstimateTransportRequest.stub(:process, mock) do
        PeddlerRateLimited::EstimateTransportRequest.perform(args)
        assert_mock result
        mock.verify
      end
    end
  end

  def test_process_not_calles_when_transport_result_missing
    result = Minitest::Mock.new
    result.expect :parse, {"TransportResult": nil}

    mock = Minitest::Mock.new
    mock.expect :call, nil, [Hash]

    assert_raises MockExpectationError do
      PeddlerRateLimited::EstimateTransportRequest.stub(:call_feed, result) do
        PeddlerRateLimited::EstimateTransportRequest.stub(:process, mock) do
          PeddlerRateLimited::EstimateTransportRequest.perform({})
          assert_mock result
          mock.verify
        end
      end
    end
  end
end
