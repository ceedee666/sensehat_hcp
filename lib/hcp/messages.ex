defmodule HCP.HumiditySensorMessage do
	@derive [Poison.Encoder]

	defstruct [:timestamp, :humidity, :temperature]
end

defmodule HCP.PressureSensorMessage do
	@derive [Poison.Encoder]

	defstruct [:timestamp, :pressure, :temperature]
end

defmodule HCP.Message do
  @derive [Poison.Encoder]
	
	@humidity_sensor_message_type "b957cb9f60c087a144a5"
	@pressure_sensor_message_type "8a750a776851a61d2b54"
	
  defstruct [:messageType, :mode, :messages]

	def new_humidity_sensor_message(humidity, temperature, timestamp) do
		%HCP.Message{messageType: @humidity_sensor_message_type,
								 mode: "sync",
								 messages: [%HCP.HumiditySensorMessage{
															timestamp: timestamp,
															humidity: humidity,
															temperature: temperature}]}
	end

	def new_pressure_sensor_message(pressure, temperature, timestamp) do
		%HCP.Message{messageType: @pressure_sensor_message_type,
								 mode: "sync",
								 messages: [%HCP.PressureSensorMessage{
															timestamp: timestamp,
															pressure: pressure,
															temperature: temperature}]}
	end
end

