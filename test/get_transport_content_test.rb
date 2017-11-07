require "test_helper"
require 'peddler-ratelimited/rate_limitter'

class GetTransportContentTest < Minitest::Test
  def test_process_calles_when_transport_result_exists
    result = Minitest::Mock.new
    result.expect :parse, {"TransportContent": '1'}

    args = {
      :shipment_id => 'shipment_id',
      :content => '1',
      :processor => 'processor',
      :processor_method => 'processor_method'
    }

    mock = Minitest::Mock.new
    mock.expect :call, nil, [args]

    PeddlerRateLimited::GetTransportContent.stub(:call_feed, result) do
      PeddlerRateLimited::GetTransportContent.stub(:process, mock) do
        PeddlerRateLimited::GetTransportContent.perform(args)
        assert_mock result
        mock.verify
      end
    end
  end

  def test_process_is_not_called_when_transport_result_missing
    result = Minitest::Mock.new
    result.expect :parse, {"TransportDocument": nil}

    mock = Minitest::Mock.new
    mock.expect :call, nil, [Hash]

    assert_raises MockExpectationError do
      PeddlerRateLimited::GetTransportContent.stub(:call_feed, result) do
        PeddlerRateLimited::GetTransportContent.stub(:process, mock) do
          PeddlerRateLimited::GetTransportContent.perform({})
          assert_mock result
          mock.verify
        end
      end
    end
  end
end
