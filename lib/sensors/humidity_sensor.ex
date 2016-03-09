defmodule Sensors.HumiditySensor do
	use GenServer
	
	@i2c_addr 0x5f

	## Client API
	def start do
		GenServer.start_link(__MODULE__, :ok, [])
	end

	def get_humidity(server) do
		GenServer.call(server, :humidity)
	end

	def get_temperature(server) do
		GenServer.call(server, :temperature)
	end
	

	## Server Callbacks
	def init(:ok) do
		{:ok, pid} = I2c.start_link("i2c-1", @i2c_addr)

		I2c.write(pid, <<0x20,0x80>>)
		
		sm = Map.merge(%{pid: pid}, read_temperature_calibration(pid))
		sm = Map.merge(sm, read_humidity_calibration(pid))
		
		{:ok, sm}
	end

	def handle_call(:humidity, _from, sm) do
		trigger_measurement(sm)
		{:reply, read_humidity(sm), sm}
	end

	def handle_call(:temperature, _from, sm) do
		trigger_measurement(sm)
		{:reply, read_temperature(sm), sm}
	end

	defp trigger_measurement(sm) do
		I2c.write(sm.pid, <<0x21,0x1>>)
	end

	defp read_temperature_calibration(pid) do
		<<t0_out::signed-size(16)>> = I2c.write_read(pid, <<0x3d>>, 1) <>
		                              I2c.write_read(pid, <<0x3c>>, 1)
		<<t1_out::signed-size(16)>> = I2c.write_read(pid, <<0x3f>>, 1) <>
		                              I2c.write_read(pid, <<0x3e>>, 1)
		
		<<t0_deg_c_lsb>> = I2c.write_read(pid, <<0x32>>, 1)
		<<t1_deg_c_lsb>> = I2c.write_read(pid, <<0x33>>, 1)
		<<_::4, t1_msb::2, t0_msb::2>> = I2c.write_read(pid, <<0x35>>, 1)

		<<t0_deg_c_x8::16>> = <<t0_msb>> <> <<t0_deg_c_lsb>> 
	  <<t1_deg_c_x8::16>> = <<t1_msb>> <> <<t1_deg_c_lsb>>
		
		t0_deg_c = t0_deg_c_x8 / 8
		t1_deg_c = t1_deg_c_x8 / 8

		%{t0_out: t0_out, t1_out: t1_out, t0_deg_c: t0_deg_c, t1_deg_c: t1_deg_c}
	end
  
  defp read_humidity_calibration(pid) do
		<<h0_out::signed-size(16)>> = I2c.write_read(pid, <<0x37>>, 1) <>
		                              I2c.write_read(pid, <<0x36>>, 1)
		<<h1_out::signed-size(16)>> = I2c.write_read(pid, <<0x3b>>, 1) <>
		                              I2c.write_read(pid, <<0x3a>>, 1)
		
		<<h0_rh_x2>> = I2c.write_read(pid, <<0x30>>, 1)
		<<h1_rh_x2>> = I2c.write_read(pid, <<0x31>>, 1)
				
		h0_rh = h0_rh_x2 / 2
		h1_rh = h1_rh_x2 / 2

		%{h0_out: h0_out, h1_out: h1_out, h0_rh: h0_rh, h1_rh: h1_rh}
	end
																																							
	
	defp read_temperature(sm) do
		<<t_out::signed-size(16)>> = I2c.write_read(sm.pid, <<0x2b>>, 1) <>
		                             I2c.write_read(sm.pid, <<0x2a>>, 1)
		
		linear_interpolation(t_out, sm.t0_out, sm.t0_deg_c, sm.t1_out, sm.t1_deg_c)
		  |>Float.round(2)
	end

	defp read_humidity(sm) do
		<<h_out::signed-size(16)>> = I2c.write_read(sm.pid, <<0x29>>, 1) <>
		                             I2c.write_read(sm.pid, <<0x28>>, 1)
		
		linear_interpolation(h_out, sm.h0_out, sm.h0_rh, sm.h1_out, sm.h1_rh)
		  |>Float.round(2)
	end

	defp linear_interpolation(x, x0, y0, x1, y1) do
		y0 + (y1 - y0) * (x - x0) / (x1 - x0)
	end
	
end
