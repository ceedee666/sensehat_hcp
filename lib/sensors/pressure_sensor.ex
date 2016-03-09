defmodule Sensors.PressureSensor do
	use GenServer
	
	@i2c_addr 0x5c

	## Client API
	def start do
		GenServer.start_link(__MODULE__, :ok, [])
	end

	def get_pressure(server) do
		GenServer.call(server, :pressure)
	end

	def get_temperature(server) do
		GenServer.call(server, :temperature)
	end
	

	## Server Callbacks
	def init(:ok) do
		{:ok, pid} = I2c.start_link("i2c-1", @i2c_addr)
		I2c.write(pid, <<0x20,0x80>>)
		{:ok, pid}
	end

	def handle_call(:pressure, _from, pid) do
		trigger_measurement(pid)
		{:reply, read_pressure(pid), pid}
	end

	def handle_call(:temperature, _from, pid) do
		trigger_measurement(pid)
		{:reply, read_temperature(pid), pid}
	end

	defp trigger_measurement(pid) do
		I2c.write(pid, <<0x21,0x1>>)
	end

	defp read_temperature(pid) do
		<<temperature::signed-size(16)>> = I2c.write_read(pid, <<0x2c>>, 1) <>
		                                   I2c.write_read(pid, <<0x2b>>, 1)
		42.5 + (temperature / 480)
		  |> Float.round(2)
	end

	defp read_pressure(pid) do
		<<pressure::signed-size(24)>> = I2c.write_read(pid, <<0x2a>>, 1) <>
		                                I2c.write_read(pid, <<0x29>>, 1) <>
				                            I2c.write_read(pid, <<0x28>>, 1)
		pressure / 4096
		  |> Float.round(2)
	end
									
end
