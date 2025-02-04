defmodule Payment.PaymentGatewaysTest do
  use Payment.DataCase

  alias Payment.PaymentGateways

  describe "payment_gateways" do
    alias Payment.PaymentGateways.PaymentGateway

    import Payment.PaymentGatewaysFixtures

    @invalid_attrs %{}

    test "list_payment_gateways/0 returns all payment_gateways" do
      payment_gateway = payment_gateway_fixture()
      assert PaymentGateways.list_payment_gateways() == [payment_gateway]
    end

    test "get_payment_gateway!/1 returns the payment_gateway with given id" do
      payment_gateway = payment_gateway_fixture()
      assert PaymentGateways.get_payment_gateway!(payment_gateway.id) == payment_gateway
    end

    test "create_payment_gateway/1 with valid data creates a payment_gateway" do
      valid_attrs = %{}

      assert {:ok, %PaymentGateway{} = payment_gateway} = PaymentGateways.create_payment_gateway(valid_attrs)
    end

    test "create_payment_gateway/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = PaymentGateways.create_payment_gateway(@invalid_attrs)
    end

    test "update_payment_gateway/2 with valid data updates the payment_gateway" do
      payment_gateway = payment_gateway_fixture()
      update_attrs = %{}

      assert {:ok, %PaymentGateway{} = payment_gateway} = PaymentGateways.update_payment_gateway(payment_gateway, update_attrs)
    end

    test "update_payment_gateway/2 with invalid data returns error changeset" do
      payment_gateway = payment_gateway_fixture()
      assert {:error, %Ecto.Changeset{}} = PaymentGateways.update_payment_gateway(payment_gateway, @invalid_attrs)
      assert payment_gateway == PaymentGateways.get_payment_gateway!(payment_gateway.id)
    end

    test "delete_payment_gateway/1 deletes the payment_gateway" do
      payment_gateway = payment_gateway_fixture()
      assert {:ok, %PaymentGateway{}} = PaymentGateways.delete_payment_gateway(payment_gateway)
      assert_raise Ecto.NoResultsError, fn -> PaymentGateways.get_payment_gateway!(payment_gateway.id) end
    end

    test "change_payment_gateway/1 returns a payment_gateway changeset" do
      payment_gateway = payment_gateway_fixture()
      assert %Ecto.Changeset{} = PaymentGateways.change_payment_gateway(payment_gateway)
    end
  end
end
