require "test_helper"
require 'peddler-ratelimited/rate_limitter'

class GetPalletLabelsTest < Minitest::Test
  def test_process_calles_when_transport_result_exists
    result = Minitest::Mock.new
    result.expect :parse, {"TransportDocument": '1'}

    args = {
      'shipment_id' => 'shipment_id',
      'document' => '1'
    }

    mock = Minitest::Mock.new
    mock.expect :call, nil, [args]

    PeddlerRateLimited::GetPalletLabels.stub(:call_feed, result) do
      PeddlerRateLimited::GetPalletLabels.stub(:process, mock) do
        PeddlerRateLimited::GetPalletLabels.perform(args)
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
      PeddlerRateLimited::GetPalletLabels.stub(:call_feed, result) do
        PeddlerRateLimited::GetPalletLabels.stub(:process, mock) do
          PeddlerRateLimited::GetPalletLabels.perform({})
          assert_mock result
          mock.verify
        end
      end
    end
  end
end
