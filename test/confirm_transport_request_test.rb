require "test_helper"
require 'peddler-ratelimited/rate_limitter'

class ConfirmTransportRequestTest < Minitest::Test
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

    PeddlerRateLimited::ConfirmTransportRequest.stub(:call_feed, result) do
      PeddlerRateLimited::ConfirmTransportRequest.stub(:process, mock) do
        PeddlerRateLimited::ConfirmTransportRequest.perform(args)
        assert_mock result
        mock.verify
      end
    end
  end

  def test_raises_exception_when_shipiment_id_missing
    result = Minitest::Mock.new
    result.expect :parse, {"TransportResult": 'test'}

    args = {
      transport_status: nil,
      processor: 'processor',
      processor_method: 'processor_method'
    }

    mock = Minitest::Mock.new
    mock.expect :call, nil, [args]

    assert_raises Exception do
      PeddlerRateLimited::ConfirmTransportRequest.stub(:call_feed, result) do
        PeddlerRateLimited::ConfirmTransportRequest.stub(:process, mock) do
          PeddlerRateLimited::ConfirmTransportRequest.perform(args)
          assert_mock result
          mock.verify
        end
      end
    end
  end

  def test_process_is_not_called_when_transport_result_missing
    result = Minitest::Mock.new
    result.expect :parse, {"TransportResult": nil}

    mock = Minitest::Mock.new
    mock.expect :call, nil, [Hash]

    assert_raises MockExpectationError do
      PeddlerRateLimited::ConfirmTransportRequest.stub(:call_feed, result) do
        PeddlerRateLimited::ConfirmTransportRequest.stub(:process, mock) do
          PeddlerRateLimited::ConfirmTransportRequest.perform({})
          assert_mock result
          mock.verify
        end
      end
    end
  end

  #TODO
  def test_enqueue_get_transport_content_on_exception
    #flunk "Not implemented yet."
    pp "Not implemented yet"
  end
end
