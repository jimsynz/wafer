defmodule WaferInterruptRegistryTest do
  use ExUnit.Case
  alias Wafer.InterruptRegistry, as: IR
  @moduledoc false

  setup do
    Supervisor.terminate_child(Wafer.Supervisor, IR)
    Supervisor.restart_child(Wafer.Supervisor, IR)
    {:ok, []}
  end

  describe "subscribe/3" do
    test "it subscribes the receiver with `nil` metadata" do
      receiver = self()
      assert :ok = IR.subscribe(:key, :rising, :conn)
      assert [{:rising, :conn, nil, ^receiver}] = IR.subscriptions(:key)
    end
  end

  describe "subscribe/4" do
    test "it subscribes the receiver with metadata" do
      receiver = self()
      assert :ok = IR.subscribe(:key, :rising, :conn, :metadata)
      assert [{:rising, :conn, :metadata, ^receiver}] = IR.subscriptions(:key)
    end
  end

  describe "unsubscribe/3" do
    test "unsubscribes the caller" do
      :ok = IR.subscribe(:key, :rising, :conn, :metadata)

      assert :ok = IR.unsubscribe(:key, :rising, :conn)
      assert [] = IR.subscriptions(:key)
    end
  end

  describe "subscriptions/1" do
    test "lists all subscriptions for `key`" do
      receiver = self()
      :ok = IR.subscribe(:key, :rising, :conn, :metadata)
      :ok = IR.subscribe(:key, :falling, :conn, :metadata)
      :ok = IR.subscribe(:key, :both, :conn, :metadata)

      assert [
               {:rising, :conn, :metadata, ^receiver},
               {:falling, :conn, :metadata, ^receiver},
               {:both, :conn, :metadata, ^receiver}
             ] = IR.subscriptions(:key)
    end
  end

  describe "subscriptions/2" do
    test "lists all subscriptions for `key` and `pin_condition`" do
      receiver = self()
      :ok = IR.subscribe(:key, :rising, :conn, :metadata)
      :ok = IR.subscribe(:key, :falling, :conn, :metadata)
      :ok = IR.subscribe(:key, :both, :conn, :metadata)

      assert [{:falling, :conn, :metadata, ^receiver}] = IR.subscriptions(:key, :falling)
    end
  end

  describe "count_subscriptions/1" do
    test "returns the number of subscriptions for `key`" do
      :ok = IR.subscribe(:key, :rising, :conn, :metadata)
      :ok = IR.subscribe(:key, :falling, :conn, :metadata)
      :ok = IR.subscribe(:key, :both, :conn, :metadata)

      assert 3 = IR.count_subscriptions(:key)
    end
  end

  describe "count_subscriptions/2" do
    test "returns the number of subscriptions for `key`" do
      :ok = IR.subscribe(:key, :rising, :conn, :metadata)
      :ok = IR.subscribe(:key, :falling, :conn, :metadata)
      :ok = IR.subscribe(:key, :both, :conn, :metadata)

      assert 1 = IR.count_subscriptions(:key, :falling)
    end
  end

  describe "subscribers?/1" do
    test "returns true if there are any subscribers for `key`" do
      :ok = IR.subscribe(:key, :rising, :conn, :metadata)

      assert IR.subscribers?(:key)
    end

    test "returns false if there are no subscribers for `key`" do
      refute IR.subscribers?(:key)
    end
  end

  describe "subscribers?/2" do
    test "returns true if there are any subscribers for `key` and `pin_condition`" do
      :ok = IR.subscribe(:key, :rising, :conn, :metadata)

      assert IR.subscribers?(:key, :rising)
    end

    test "returns false if there are no subscribers for `key` and `pin_condition`" do
      :ok = IR.subscribe(:key, :rising, :conn, :metadata)

      refute IR.subscribers?(:key, :falling)
    end
  end

  describe "publish/2" do
    test "publishes to subscribers of `key` and `pin_condition`" do
      :ok = IR.subscribe(:key, :rising, :conn, :metadata)
      IR.publish(:key, :rising)

      assert_received {:interrupt, :conn, :rising, :metadata}
    end

    test "publishes to subscribers of `key` and `:both`" do
      :ok = IR.subscribe(:key, :both, :conn, :metadata)
      IR.publish(:key, :rising)

      assert_received {:interrupt, :conn, :rising, :metadata}
    end

    test "returns the number of messages sent" do
      assert {:ok, 0} = IR.publish(:key, :rising)

      :ok = IR.subscribe(:key, :rising, :conn, :metadata)
      :ok = IR.subscribe(:key, :both, :conn, :metadata)

      assert {:ok, 2} = IR.publish(:key, :rising)
    end
  end
end
