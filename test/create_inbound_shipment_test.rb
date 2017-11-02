require "test_helper"
require 'peddler-ratelimited/rate_limitter'

class CreateInboundShipmentTest < Minitest::Test
  def test_process_calles_when_transport_result_exists
    result = Minitest::Mock.new
    result.expect :parse, {"ShipmentId": '1'}

    args = {
      'shipment_id' => 'shipment_id',
      'inbound_shipment_header' => nil,
      'inbound_shipment_items' => nil,
      'processor' => 'processor',
      'processor_method' => 'update'
    }

    mock = Minitest::Mock.new
    mock.expect :call, nil, [args]

    PeddlerRateLimited::CreateInboundShipment.stub(:call_feed, result) do
      PeddlerRateLimited::CreateInboundShipment.stub(:process, mock) do
        PeddlerRateLimited::CreateInboundShipment.perform(args)
        assert_mock result
        mock.verify
      end
    end
  end

  def test_process_is_not_called_when_transport_result_missing
    result = Minitest::Mock.new
    result.expect :parse, {"ShipmentId": nil}

    mock = Minitest::Mock.new
    mock.expect :call, nil, [Hash]

    assert_raises MockExpectationError do
      PeddlerRateLimited::CreateInboundShipment.stub(:call_feed, result) do
        PeddlerRateLimited::CreateInboundShipment.stub(:process, mock) do
          PeddlerRateLimited::CreateInboundShipment.perform({})
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
