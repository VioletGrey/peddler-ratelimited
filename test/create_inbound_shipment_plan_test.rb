require "test_helper"
require 'peddler-ratelimited/rate_limitter'

class CreateInboundShipmentPlanTest < Minitest::Test
  def test_process_calles_when_transport_result_exists
    result = Minitest::Mock.new
    result.expect :parse, {"InboundShipmentPlans": '1'}

    args = {
      'ship_from_address' => 'address',
      'inbound_shipment_plan_request_items' => nil
    }

    mock = Minitest::Mock.new
    mock.expect :call, nil, ["1", nil, 'address']

    PeddlerRateLimited::CreateInboundShipmentPlan.stub(:call_feed, result) do
      PeddlerRateLimited::CreateInboundShipmentPlan.stub(:process_plans, mock) do
        PeddlerRateLimited::CreateInboundShipmentPlan.perform(args)
        assert_mock result
        mock.verify
      end
    end
  end

  def test_process_is_not_called_when_transport_result_missing
    result = Minitest::Mock.new
    result.expect :parse, {"InboundShipmentPlans": nil}

    mock = Minitest::Mock.new
    mock.expect :call, nil, ["1", nil, 'address']

    assert_raises MockExpectationError do
      PeddlerRateLimited::CreateInboundShipmentPlan.stub(:call_feed, result) do
        PeddlerRateLimited::CreateInboundShipmentPlan.stub(:process_plans, mock) do
          PeddlerRateLimited::CreateInboundShipmentPlan.perform({})
          assert_mock result
          mock.verify
        end
      end
    end
  end

end
