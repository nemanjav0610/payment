defmodule PaymentWeb.Api.PaymentGatewayControllerTest do
  use PaymentWeb.ConnCase

  import Payment.PaymentGatewaysFixtures

  alias Payment.PaymentGateways.PaymentGateway

  @create_attrs %{

  }
  @update_attrs %{

  }
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all payment_gateways", %{conn: conn} do
      conn = get(conn, Routes.api_payment_gateway_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create payment_gateway" do
    test "renders payment_gateway when data is valid", %{conn: conn} do
      conn = post(conn, Routes.api_payment_gateway_path(conn, :create), payment_gateway: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.api_payment_gateway_path(conn, :show, id))

      assert %{
               "id" => ^id
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.api_payment_gateway_path(conn, :create), payment_gateway: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update payment_gateway" do
    setup [:create_payment_gateway]

    test "renders payment_gateway when data is valid", %{conn: conn, payment_gateway: %PaymentGateway{id: id} = payment_gateway} do
      conn = put(conn, Routes.api_payment_gateway_path(conn, :update, payment_gateway), payment_gateway: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.api_payment_gateway_path(conn, :show, id))

      assert %{
               "id" => ^id
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, payment_gateway: payment_gateway} do
      conn = put(conn, Routes.api_payment_gateway_path(conn, :update, payment_gateway), payment_gateway: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete payment_gateway" do
    setup [:create_payment_gateway]

    test "deletes chosen payment_gateway", %{conn: conn, payment_gateway: payment_gateway} do
      conn = delete(conn, Routes.api_payment_gateway_path(conn, :delete, payment_gateway))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.api_payment_gateway_path(conn, :show, payment_gateway))
      end
    end
  end

  defp create_payment_gateway(_) do
    payment_gateway = payment_gateway_fixture()
    %{payment_gateway: payment_gateway}
  end
end
