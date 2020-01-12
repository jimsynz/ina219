defmodule INA219Test do
  use ExUnit.Case, async: true
  use Mimic
  alias Wafer.Driver.Fake
  doctest INA219
  @moduledoc false

  describe "acquire/1" do
    test "returns an error when the upstream conn is not provided" do
      assert {:error, _} = INA219.acquire(current_divisor: 1, power_divisor: 1)
    end

    test "returns an error when the current divisor is not provided" do
      assert {:error, _} = INA219.acquire(conn: driver(), power_divisor: 1)
    end

    test "returns an error when the power divisor is not provided" do
      assert {:error, _} = INA219.acquire(conn: driver(), current_divisor: 1)
    end
  end

  describe "reset/1" do
    test "sets the MSB to 1" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<0x80, 0x00>> = callback.(<<0x00, 0x00>>)
        :ok
      end)

      INA219.reset(conn())
    end
  end

  describe "bus_voltage_range/1" do
    test "when configuration bit 3 is 1 it returns 32" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0x20, 0x00>>} end)

      assert {:ok, 32} = INA219.bus_voltage_range(conn())
    end

    test "when configuration bit 3 is 9 it returns 16" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0x00, 0x00>>} end)

      assert {:ok, 16} = INA219.bus_voltage_range(conn())
    end
  end

  describe "bus_voltage_range/2" do
    test "setting to 16 sets configuration bit 3 to 0" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<0x00, 0x00>> = callback.(<<0x20, 0x00>>)
        :ok
      end)

      assert :ok = INA219.bus_voltage_range(conn(), 16)
    end

    test "setting to 32 sets configuration bit 3 to 1" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<0x20, 0x00>> = callback.(<<0x00, 0x00>>)
        :ok
      end)

      assert :ok = INA219.bus_voltage_range(conn(), 32)
    end
  end

  describe "shunt_voltage_pga/1" do
    test "when configuration bits 4 and 5 are set to 0 it returns 1" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0x00, 0x00>>} end)

      assert {:ok, 1} = INA219.shunt_voltage_pga(conn())
    end

    test "when configuration bits 4 and 5 are set to 1 it returns 2" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0x08, 0x00>>} end)

      assert {:ok, 2} = INA219.shunt_voltage_pga(conn())
    end

    test "when configuration bits 4 and 5 are set to 1 it returns 3" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0x10, 0x00>>} end)

      assert {:ok, 4} = INA219.shunt_voltage_pga(conn())
    end

    test "when configuration bits 4 and 5 are set to 1 it returns 4" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0x18, 0x00>>} end)

      assert {:ok, 8} = INA219.shunt_voltage_pga(conn())
    end
  end

  describe "shunt_voltage_pga/2" do
    test "setting to 1 sets configuration bits 4 and 5 to 0" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(3), 0::size(2), _::size(11)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.shunt_voltage_pga(conn(), 1)
    end

    test "setting to 2 sets configuration bits 4 and 5 to 1" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(3), 1::size(2), _::size(11)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.shunt_voltage_pga(conn(), 2)
    end

    test "setting to 4 sets configuration bits 4 and 5 to 2" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(3), 2::size(2), _::size(11)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.shunt_voltage_pga(conn(), 4)
    end

    test "setting to 8 sets configuration bits 4 and 5 to 2" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(3), 3::size(2), _::size(11)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.shunt_voltage_pga(conn(), 8)
    end
  end

  describe "bus_adc_resolution_and_averaging/1" do
    test "when configuration bits 6 and 7 are set to 0 it returns `{1, 9}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(5), 0::size(4), 0::size(7)>>} end)

      assert {:ok, {1, 9}} = INA219.bus_adc_resolution_and_averaging(conn())
    end

    test "when configuration bits 6 and 7 are set to 1 it returns `{1, 10}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(5), 1::size(4), 0::size(7)>>} end)

      assert {:ok, {1, 10}} = INA219.bus_adc_resolution_and_averaging(conn())
    end

    test "when configuration bits 6 and 7 are set to 2 it returns `{1, 11}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(5), 2::size(4), 0::size(7)>>} end)

      assert {:ok, {1, 11}} = INA219.bus_adc_resolution_and_averaging(conn())
    end

    test "when configuration bits 6 and 7 are set to 3 it returns `{1, 12}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(5), 3::size(4), 0::size(7)>>} end)

      assert {:ok, {1, 12}} = INA219.bus_adc_resolution_and_averaging(conn())
    end

    test "when configuration bits 6 and 7 are set to 4 it returns `{1, 9}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(5), 4::size(4), 0::size(7)>>} end)

      assert {:ok, {1, 9}} = INA219.bus_adc_resolution_and_averaging(conn())
    end

    test "when configuration bits 6 and 7 are set to 5 it returns `{1, 10}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(5), 5::size(4), 0::size(7)>>} end)

      assert {:ok, {1, 10}} = INA219.bus_adc_resolution_and_averaging(conn())
    end

    test "when configuration bits 6 and 7 are set to 6 it returns `{1, 11}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(5), 6::size(4), 0::size(7)>>} end)

      assert {:ok, {1, 11}} = INA219.bus_adc_resolution_and_averaging(conn())
    end

    test "when configuration bits 6 and 7 are set to 7 it returns `{1, 12}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(5), 7::size(4), 0::size(7)>>} end)

      assert {:ok, {1, 12}} = INA219.bus_adc_resolution_and_averaging(conn())
    end

    test "when configuration bits 6 and 7 are set to 8 it returns `{1, 12}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(5), 8::size(4), 0::size(7)>>} end)

      assert {:ok, {1, 12}} = INA219.bus_adc_resolution_and_averaging(conn())
    end

    test "when configuration bits 6 and 7 are set to 9 it returns `{2, 12}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(5), 9::size(4), 0::size(7)>>} end)

      assert {:ok, {2, 12}} = INA219.bus_adc_resolution_and_averaging(conn())
    end

    test "when configuration bits 6 and 7 are set to 10 it returns `{4, 12}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(5), 10::size(4), 0::size(7)>>} end)

      assert {:ok, {4, 12}} = INA219.bus_adc_resolution_and_averaging(conn())
    end

    test "when configuration bits 6 and 7 are set to 11 it returns `{8, 12}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(5), 11::size(4), 0::size(7)>>} end)

      assert {:ok, {8, 12}} = INA219.bus_adc_resolution_and_averaging(conn())
    end

    test "when configuration bits 6 and 7 are set to 12 it returns `{16, 12}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(5), 12::size(4), 0::size(7)>>} end)

      assert {:ok, {16, 12}} = INA219.bus_adc_resolution_and_averaging(conn())
    end

    test "when configuration bits 6 and 7 are set to 13 it returns `{32, 12}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(5), 13::size(4), 0::size(7)>>} end)

      assert {:ok, {32, 12}} = INA219.bus_adc_resolution_and_averaging(conn())
    end

    test "when configuration bits 6 and 7 are set to 14 it returns `{64, 12}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(5), 14::size(4), 0::size(7)>>} end)

      assert {:ok, {64, 12}} = INA219.bus_adc_resolution_and_averaging(conn())
    end

    test "when configuration bits 6 and 7 are set to 15 it returns `{128, 12}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(5), 15::size(4), 0::size(7)>>} end)

      assert {:ok, {128, 12}} = INA219.bus_adc_resolution_and_averaging(conn())
    end
  end

  describe "bus_adc_resolution_and_averaging/2" do
    test "setting to `{1, 9}` sets configuration bits 6 and 7 to 0" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(5), 0::size(4), _::size(7)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.bus_adc_resolution_and_averaging(conn(), {1, 9})
    end

    test "setting to `{1, 10}` sets configuration bits 6 and 7 to 1" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(5), 1::size(4), _::size(7)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.bus_adc_resolution_and_averaging(conn(), {1, 10})
    end

    test "setting to `{1, 11}` sets configuration bits 6 and 7 to 2" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(5), 2::size(4), _::size(7)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.bus_adc_resolution_and_averaging(conn(), {1, 11})
    end

    test "setting to `{1, 12}` sets configuration bits 6 and 7 to 3" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(5), 3::size(4), _::size(7)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.bus_adc_resolution_and_averaging(conn(), {1, 12})
    end

    test "setting to `{2, 12}` sets configuration bits 6 and 7 to 9" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(5), 9::size(4), _::size(7)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.bus_adc_resolution_and_averaging(conn(), {2, 12})
    end

    test "setting to `{4, 12}` sets configuration bits 6 and 7 to 10" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(5), 10::size(4), _::size(7)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.bus_adc_resolution_and_averaging(conn(), {4, 12})
    end

    test "setting to `{8, 12}` sets configuration bits 6 and 7 to 11" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(5), 11::size(4), _::size(7)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.bus_adc_resolution_and_averaging(conn(), {8, 12})
    end

    test "setting to `{16, 12}` sets configuration bits 6 and 7 to 12" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(5), 12::size(4), _::size(7)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.bus_adc_resolution_and_averaging(conn(), {16, 12})
    end

    test "setting to `{32, 12}` sets configuration bits 6 and 7 to 13" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(5), 13::size(4), _::size(7)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.bus_adc_resolution_and_averaging(conn(), {32, 12})
    end

    test "setting to `{64, 12}` sets configuration bits 6 and 7 to 14" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(5), 14::size(4), _::size(7)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.bus_adc_resolution_and_averaging(conn(), {64, 12})
    end

    test "setting to `{128, 12}` sets configuration bits 6 and 7 to 15" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(5), 15::size(4), _::size(7)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.bus_adc_resolution_and_averaging(conn(), {128, 12})
    end
  end

  describe "shunt_adc_resolution_and_averaging/1" do
    test "when bits 9 through 12 are set to 0 it returns `{1, 9}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(9), 0::size(4), 0::size(3)>>} end)

      assert {:ok, {1, 9}} = INA219.shunt_adc_resolution_and_averaging(conn())
    end

    test "when bits 9 through 12 are set to 1 it returns `{1, 10}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(9), 1::size(4), 0::size(3)>>} end)

      assert {:ok, {1, 10}} = INA219.shunt_adc_resolution_and_averaging(conn())
    end

    test "when bits 9 through 12 are set to 2 it returns `{1, 11}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(9), 2::size(4), 0::size(3)>>} end)

      assert {:ok, {1, 11}} = INA219.shunt_adc_resolution_and_averaging(conn())
    end

    test "when bits 9 through 12 are set to 3 it returns `{1, 12}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(9), 3::size(4), 0::size(3)>>} end)

      assert {:ok, {1, 12}} = INA219.shunt_adc_resolution_and_averaging(conn())
    end

    test "when bits 9 through 12 are set to 4 it returns `{1, 9}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(9), 4::size(4), 0::size(3)>>} end)

      assert {:ok, {1, 9}} = INA219.shunt_adc_resolution_and_averaging(conn())
    end

    test "when bits 9 through 12 are set to 5 it returns `{1, 10}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(9), 5::size(4), 0::size(3)>>} end)

      assert {:ok, {1, 10}} = INA219.shunt_adc_resolution_and_averaging(conn())
    end

    test "when bits 9 through 12 are set to 6 it returns `{1, 11}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(9), 6::size(4), 0::size(3)>>} end)

      assert {:ok, {1, 11}} = INA219.shunt_adc_resolution_and_averaging(conn())
    end

    test "when bits 9 through 12 are set to 7 it returns `{1, 12}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(9), 7::size(4), 0::size(3)>>} end)

      assert {:ok, {1, 12}} = INA219.shunt_adc_resolution_and_averaging(conn())
    end

    test "when bits 9 through 12 are set to 8 it returns `{1, 12}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(9), 8::size(4), 0::size(3)>>} end)

      assert {:ok, {1, 12}} = INA219.shunt_adc_resolution_and_averaging(conn())
    end

    test "when bits 9 through 12 are set to 9 it returns `{2, 12}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(9), 9::size(4), 0::size(3)>>} end)

      assert {:ok, {2, 12}} = INA219.shunt_adc_resolution_and_averaging(conn())
    end

    test "when bits 9 through 12 are set to 10 it returns `{4, 12}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(9), 10::size(4), 0::size(3)>>} end)

      assert {:ok, {4, 12}} = INA219.shunt_adc_resolution_and_averaging(conn())
    end

    test "when bits 9 through 12 are set to 11 it returns `{8, 12}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(9), 11::size(4), 0::size(3)>>} end)

      assert {:ok, {8, 12}} = INA219.shunt_adc_resolution_and_averaging(conn())
    end

    test "when bits 9 through 12 are set to 12 it returns `{16, 12}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(9), 12::size(4), 0::size(3)>>} end)

      assert {:ok, {16, 12}} = INA219.shunt_adc_resolution_and_averaging(conn())
    end

    test "when bits 9 through 12 are set to 13 it returns `{32, 12}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(9), 13::size(4), 0::size(3)>>} end)

      assert {:ok, {32, 12}} = INA219.shunt_adc_resolution_and_averaging(conn())
    end

    test "when bits 9 through 12 are set to 14 it returns `{64, 12}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(9), 14::size(4), 0::size(3)>>} end)

      assert {:ok, {64, 12}} = INA219.shunt_adc_resolution_and_averaging(conn())
    end

    test "when bits 9 through 12 are set to 15 it returns `{128, 12}`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(9), 15::size(4), 0::size(3)>>} end)

      assert {:ok, {128, 12}} = INA219.shunt_adc_resolution_and_averaging(conn())
    end
  end

  describe "shunt_adc_resolution_and_averaging/2" do
    test "when set to `{1, 9}` it sets bits 9 through 12 to 0" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(9), 0::size(4), _::size(3)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.shunt_adc_resolution_and_averaging(conn(), {1, 9})
    end

    test "when set to `{1, 10}` it sets bits 9 through 12 to 1" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(9), 1::size(4), _::size(3)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.shunt_adc_resolution_and_averaging(conn(), {1, 10})
    end

    test "when set to `{1, 11}` it sets bits 9 through 12 to 2" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(9), 2::size(4), _::size(3)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.shunt_adc_resolution_and_averaging(conn(), {1, 11})
    end

    test "when set to `{1, 12}` it sets bits 9 through 12 to 3" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(9), 3::size(4), _::size(3)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.shunt_adc_resolution_and_averaging(conn(), {1, 12})
    end

    test "when set to `{2, 12}` it sets bits 9 through 12 to 9" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(9), 9::size(4), _::size(3)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.shunt_adc_resolution_and_averaging(conn(), {2, 12})
    end

    test "when set to `{4, 12}` it sets bits 9 through 12 to 10" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(9), 10::size(4), _::size(3)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.shunt_adc_resolution_and_averaging(conn(), {4, 12})
    end

    test "when set to `{8, 12}` it sets bits 9 through 12 to 11" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(9), 11::size(4), _::size(3)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.shunt_adc_resolution_and_averaging(conn(), {8, 12})
    end

    test "when set to `{16, 12}` it sets bits 9 through 12 to 12" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(9), 12::size(4), _::size(3)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.shunt_adc_resolution_and_averaging(conn(), {16, 12})
    end

    test "when set to `{32, 12}` it sets bits 9 through 12 to 13" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(9), 13::size(4), _::size(3)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.shunt_adc_resolution_and_averaging(conn(), {32, 12})
    end

    test "when set to `{64, 12}` it sets bits 9 through 12 to 14" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(9), 14::size(4), _::size(3)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.shunt_adc_resolution_and_averaging(conn(), {64, 12})
    end

    test "when set to `{128, 12}` it sets bits 9 through 12 to 15" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(9), 15::size(4), _::size(3)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.shunt_adc_resolution_and_averaging(conn(), {128, 12})
    end
  end

  describe "mode/1" do
    test "when bits 13 through 15 are set to 0 it returns `:power_down`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0x00, 0x00>>} end)

      assert {:ok, :power_down} = INA219.mode(conn())
    end

    test "when bits 13 through 15 are set to 1 it returns `:shunt_voltage_triggered`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0x00, 0x01>>} end)

      assert {:ok, :shunt_voltage_triggered} = INA219.mode(conn())
    end

    test "when bits 13 through 15 are set to 2 it returns `:bus_voltage_triggered`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0x00, 0x02>>} end)

      assert {:ok, :bus_voltage_triggered} = INA219.mode(conn())
    end

    test "when bits 13 through 15 are set to 3 it returns `:shunt_and_bus_voltage_triggered`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0x00, 0x03>>} end)

      assert {:ok, :shunt_and_bus_voltage_triggered} = INA219.mode(conn())
    end

    test "when bits 13 through 15 are set to 4 it returns `:adc_off`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0x00, 0x04>>} end)

      assert {:ok, :adc_off} = INA219.mode(conn())
    end

    test "when bits 13 through 15 are set to 5 it returns `:shunt_voltage_continuous`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0x00, 0x05>>} end)

      assert {:ok, :shunt_voltage_continuous} = INA219.mode(conn())
    end

    test "when bits 13 through 15 are set to 6 it returns `:bus_voltage_continuous`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0x00, 0x06>>} end)

      assert {:ok, :bus_voltage_continuous} = INA219.mode(conn())
    end

    test "when bits 13 through 15 are set to 7 it returns `:shunt_and_bus_voltage_continuous`" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0x00, 0x07>>} end)

      assert {:ok, :shunt_and_bus_voltage_continuous} = INA219.mode(conn())
    end
  end

  describe "mode/2" do
    test "when set to `:power_down` it sets configuration bits 13 through 15 to `0`" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(13), 0::size(3)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.mode(conn(), :power_down)
    end

    test "when set to `:shunt_voltage_triggered` it sets configuration bits 13 through 15 to `1`" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(13), 1::size(3)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.mode(conn(), :shunt_voltage_triggered)
    end

    test "when set to `:bus_voltage_triggered` it sets configuration bits 13 through 15 to `2`" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(13), 2::size(3)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.mode(conn(), :bus_voltage_triggered)
    end

    test "when set to `:shunt_and_bus_voltage_triggered` it sets configuration bits 13 through 15 to `3`" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(13), 3::size(3)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.mode(conn(), :shunt_and_bus_voltage_triggered)
    end

    test "when set to `:adc_off` it sets configuration bits 13 through 15 to `4`" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(13), 4::size(3)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.mode(conn(), :adc_off)
    end

    test "when set to `:shunt_voltage_continuous` it sets configuration bits 13 through 15 to `5`" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(13), 5::size(3)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.mode(conn(), :shunt_voltage_continuous)
    end

    test "when set to `:bus_voltage_continuous` it sets configuration bits 13 through 15 to `6`" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(13), 6::size(3)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.mode(conn(), :bus_voltage_continuous)
    end

    test "when set to `:shunt_and_bus_voltage_continuous` it sets configuration bits 13 through 15 to `7`" do
      INA219.Registers
      |> expect(:update_configuration, 1, fn _conn, callback ->
        assert <<_::size(13), 7::size(3)>> = callback.(<<0xFF, 0xFF>>)
        :ok
      end)

      assert :ok = INA219.mode(conn(), :shunt_and_bus_voltage_continuous)
    end
  end

  describe "conversion_ready?/1" do
    test "when bus voltage bit 15 is set to 1 it returns true" do
      INA219.Registers
      |> stub(:read_bus_voltage, fn _conn -> {:ok, <<0::size(14), 1::size(1), 0::size(1)>>} end)

      assert INA219.conversion_ready?(conn())
    end

    test "when bus voltage bit 15 is set to 0 it returns false" do
      INA219.Registers
      |> stub(:read_bus_voltage, fn _conn -> {:ok, <<0::size(16)>>} end)

      refute INA219.conversion_ready?(conn())
    end

    test "when the register read fails it returns false" do
      INA219.Registers
      |> stub(:read_bus_voltage, fn _conn -> {:error, "WAT"} end)

      refute INA219.conversion_ready?(conn())
    end
  end

  describe "math_overflow?/1" do
    test "when bit 16 is set to 1 it returns true" do
      INA219.Registers
      |> stub(:read_bus_voltage, fn _conn -> {:ok, <<0::size(15), 1::size(1)>>} end)

      assert INA219.math_overflow?(conn())
    end

    test "when bit 16 is set to 0 it returns false" do
      INA219.Registers
      |> stub(:read_bus_voltage, fn _conn -> {:ok, <<0::size(16)>>} end)

      refute INA219.math_overflow?(conn())
    end

    test "when the register read fails it returns false" do
      INA219.Registers
      |> stub(:read_bus_voltage, fn _conn -> {:error, "WAT"} end)

      refute INA219.math_overflow?(conn())
    end
  end

  describe "bus_voltage/1" do
    test "it correctly calculates the voltage" do
      INA219.Registers
      |> stub(:read_bus_voltage, fn _conn -> {:ok, <<0x1F40::size(13), 0::size(3)>>} end)

      assert {:ok, 32.0} = INA219.bus_voltage(conn())
    end
  end

  describe "shunt_voltage/1" do
    # these shunt voltage fixtures are taken directly from page 22 of the datasheet.

    test "when `shunt_voltage_pga` is `1` it correctly calculates millivolts" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(3), 0::size(2), 0::size(11)>>} end)
      |> stub(:read_shunt_voltage, fn _conn -> {:ok, <<0b00001111, 0b10100000>>} end)

      assert {:ok, 40.0} = INA219.shunt_voltage(conn())
    end

    test "when `shunt_voltage_pga` is `1` it correctly calculates negative millivolts" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(3), 0::size(2), 0::size(11)>>} end)
      |> stub(:read_shunt_voltage, fn _conn -> {:ok, <<0b11110000, 0b01100001>>} end)

      assert {:ok, -39.99} = INA219.shunt_voltage(conn())
    end

    test "when `shunt_voltage_pga` is `2` it correctly calculates millivolts" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(3), 1::size(2), 0::size(11)>>} end)
      |> stub(:read_shunt_voltage, fn _conn -> {:ok, <<0b00011111, 0b01000000>>} end)

      assert {:ok, 80.0} = INA219.shunt_voltage(conn())
    end

    test "when `shunt_voltage_pga` is `2` it correctly calculates negative millivolts" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(3), 1::size(2), 0::size(11)>>} end)
      |> stub(:read_shunt_voltage, fn _conn -> {:ok, <<0b11100000, 0b11000010>>} end)

      assert {:ok, -79.98} = INA219.shunt_voltage(conn())
    end

    test "when `shunt_voltage_pga` is `4` it correctly calculates millivolts" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(3), 2::size(2), 0::size(11)>>} end)
      |> stub(:read_shunt_voltage, fn _conn -> {:ok, <<0b00111110, 0b10000000>>} end)

      assert {:ok, 160.0} = INA219.shunt_voltage(conn())
    end

    test "when `shunt_voltage_pga` is `4` it correctly calculates negative millivolts" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(3), 2::size(2), 0::size(11)>>} end)
      |> stub(:read_shunt_voltage, fn _conn -> {:ok, <<0b11000001, 0b10000010>>} end)

      assert {:ok, -159.98} = INA219.shunt_voltage(conn())
    end

    test "when `shunt_voltage_pga` is `8` it correctly calculates millivolts" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(3), 3::size(2), 0::size(11)>>} end)
      |> stub(:read_shunt_voltage, fn _conn -> {:ok, <<0b01111101, 0b00000000>>} end)

      assert {:ok, 320.0} = INA219.shunt_voltage(conn())
    end

    test "when `shunt_voltage_pga` is `8` it correctly calculates negative millivolts" do
      INA219.Registers
      |> stub(:read_configuration, fn _conn -> {:ok, <<0::size(3), 3::size(2), 0::size(11)>>} end)
      |> stub(:read_shunt_voltage, fn _conn -> {:ok, <<0b11000001, 0b01111110>>} end)

      assert {:ok, -160.02} = INA219.shunt_voltage(conn())
    end
  end

  describe "current/1" do
    test "it returns the current value divided by the current divisor" do
      INA219.Registers
      |> stub(:read_current, fn _conn -> {:ok, <<0x12, 0x34>>} end)

      assert {:ok, 2330.0} = INA219.current(conn())
    end
  end

  describe "power/1" do
    test "it returns the current value divided by the current divisor" do
      INA219.Registers
      |> stub(:read_power, fn _conn -> {:ok, <<0x0B, 0xB8>>} end)

      assert {:ok, 1000.0} = INA219.power(conn())
    end
  end

  describe "calibrate/1" do
    test "it returns the calibration value" do
      INA219.Registers
      |> stub(:read_calibration, fn _conn -> {:ok, <<0xAB, 0xCD>>} end)

      {:ok, 0xABCD} = INA219.calibrate(conn())
    end
  end

  describe "calibrate/2" do
    test "it sets the calibration value" do
      INA219.Registers
      |> expect(:write_calibration, 1, fn _conn, <<0xAB, 0xCD>> -> :ok end)

      assert :ok = INA219.calibrate(conn(), 0xABCD)
    end
  end

  defp driver do
    with {:ok, driver} <- Fake.acquire([]), do: driver
  end

  defp conn do
    with {:ok, conn} <- INA219.acquire(conn: driver(), current_divisor: 2, power_divisor: 3),
         do: conn
  end
end
