defmodule SensehatHcp do
	use GenServer
	require Logger

	@iot_service_url "https://iotmmsp650074trial.hanatrial.ondemand.com/com.sap.iotservices.mms/v1/api/http/data/"
	@oauth_token "ea727d424848244f43c2891274f937a9"
	@device_id "803bea58-60fa-47e0-9455-09455a0e4d4a"

	## Client API
	def start do
		GenServer.start_link(__MODULE__, :ok, [])
	end

	  ## Server Callbacks
	def init(:ok) do
		{:ok, hs} = Sensors.HumiditySensor.start
		{:ok, ps} = Sensors.PressureSensor.start
		schedule_sensor_read
		{:ok, %{hs: hs, ps: ps}}
	end

	def handle_info(:send_sensor_data, sm) do
		ts = :os.system_time(:seconds)

		HCP.Message.new_humidity_sensor_message(
			Sensors.HumiditySensor.get_humidity(sm.hs),
			Sensors.HumiditySensor.get_temperature(sm.hs),
			ts) |>
			Poison.encode! |>
		  send_to_hcp

		HCP.Message.new_pressure_sensor_message(
			Sensors.PressureSensor.get_pressure(sm.ps)
			Sensors.Pressureensor.get_temperature(sm.ps),
		  ts) |>
			Poison.encode! |>
		  send_to_hcp
		
		schedule_sensor_read
		
		{:noreply, sm}
	end

	defp schedule_sensor_read do
		Process.send_after(self(), :send_sensor_data, 2000)
	end


	defp send_to_hcp(message_body) do
		response = HTTPoison.post!("#{@iot_service_url}#{@device_id}",
										           message_body,
										           %{"Authorization" => "Bearer #{@oauth_token}", "Content-Type" => "application/json"})

		Logger.debug "Message: #{inspect hsm}"
		Logger.debug "Response: #{inspect response}"
	end
end
