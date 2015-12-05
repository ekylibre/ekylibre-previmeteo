# coding: utf-8
require 'net/http'

# Use has_parameter to specify access parameters to ActiveSensor, allowing user to set these parameters.
#
# Examples:
#
# Set *api* parameter. User could set his api key through interface.
# has_parameter :api
#
# Use *default* option to set a default value.
# has_parameter :url, default: 'http://xyz.com/api/'
class Weather::Previmeteo::GenericController < ActiveSensor::Controller
  has_parameter :id
  has_parameter :api
  has_parameter :id_station
  has_parameter :url, default: 'http://my.previmeteo.com/api/station.php'

  # ActiveSensor::Controller sends an +options+ hash, with *started_at* and
  # *stopped_at* as delimiters for a periodic summary (Time ruby objects).
  # If these keys aren't supplied, please feel free to return instant values.
  # Dates are formatted in UTC.
  # Example: 2015-09-14 17:12:40 +0200
  # Set list as a Hash where:
  # key is wanted indicator
  # value is a valid Measure
  #
  # Example:
  # For 30 °C
  # list[:temperature] = 30.in_celsius
  #
  # Please remember:
  # - Find available indicators and units on http://open-nomenclature.org or contact us to define a new one
  # - Set your public indicators in your sensor definition (sensors.yml)
  #
  # Existing indicators:
  # - temperature
  # - relative_humidity
  # - atmospheric_pressure
  # - wind_gust
  # - rainfall
  # - wind_speed
  # - wind_direction
  # - average_temperature
  # - minimal_temperature
  # - maximal_temperature
  # - maximal_rainfall
  # - average_atmospheric_pressure
  # - minimal_atmospheric_pressure
  # - maximal_atmospheric_pressure
  # - average_relative_humidity
  # - minimal_relative_humidity
  # - maximal_relative_humidity
  # - average_wind_speed
  # - average_wind_direction
  # - solar_irradiance
  def retrieve(parameters, options = {})
    hour_duration = find_period(options[:started_at], options[:stopped_at])

    uri = URI(parameters[:url])
    params = {
      id: parameters[:id],
      api: parameters[:api],
      id_station: parameters[:id_station]
    }
    params[:type] = hour_duration if hour_duration > 0
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    if response.is_a?(Net::HTTPSuccess)
      json_response = JSON.parse(response.body)
      json_response.deep_symbolize_keys!
    end

    if json_response.key? :error
      return { status: :sensor_error, message: json_response[:cause] } if json_response.key? :cause
    end

    values = {}
    report = {
      nature: :meteorological_analysis
    }

    info = json_response[:info] || {}
    data = json_response[:data] || {}

    if hour_duration == 0
      store = data[:last] || {}
      report[:sampling_temporal_mode] = 'instant'
      format = {
        temperature: [:temp, :celsius],
        relative_humidity: [:rh, :percent],
        atmospheric_pressure: [:press, :hectopascal],
        # Maximal wind speed on last 5 minutes... Not instant
        # wind_gust_count: [:wind_gust],
        # rainfall: [:rain, :millimeter_per_hour],
        wind_speed: [:wind_ave, :meter_per_second],
        wind_direction: [:wind_dir, :degree],
        solar_irradiance: [:sr, :watt_per_square_meter]
      }
      # Timestamp your report with time key: Use GMT/UTC.
      report[:sampled_at] = Time.utc(*store[:time_gmt].split(/[^\d]+/)).localtime
    else
      store = data[:summary] || {}
      report[:sampling_temporal_mode] = 'period'
      format = {
        average_temperature: [:temp_ave, :celsius],
        minimal_temperature: [:temp_min, :celsius],
        maximal_temperature: [:temp_max, :celsius],
        # maximal_rainfall: [:rain_max, :millimeter_per_hour],
        average_atmospheric_pressure: [:press_ave, :hectopascal],
        minimal_atmospheric_pressure: [:press_min, :hectopascal],
        maximal_atmospheric_pressure: [:press_max, :hectopascal],
        average_relative_humidity: [:rh_ave, :percent],
        minimal_relative_humidity: [:rh_min, :percent],
        maximal_relative_humidity: [:rh_max, :percent],
        average_wind_direction: [:wind_dir_ave, :degree],
        average_wind_speed: [:wind_ave, :meter_per_second],
        minimal_wind_speed: [:wind_min, :meter_per_second],
        maximal_wind_speed: [:wind_max, :meter_per_second],
        average_solar_irradiance: [:sr_ave, :watt_per_square_meter],
        minimal_solar_irradiance: [:sr_min, :watt_per_square_meter],
        maximal_solar_irradiance: [:sr_max, :watt_per_square_meter]
      }
    end
    format.each do |indicator_name, (key, unit)|
      value = store[key]
      values[indicator_name] = (unit ? value.in(unit) : value) if value
    end

    # Add geolocation. Use coordinate space as a {lat, lon} hash or [lat, lon] array
    latitude = info[:lat]
    longitude = info[:lon]
    if latitude && longitude
      report[:geolocation] = Charta.new_point(latitude, longitude, 4326)
    end
    report[:values] = values
    report[:status] = :ok

    report
  end

  # Find period hour_duration
  def find_period(started_at, stopped_at)
    return 0 if started_at.nil? || stopped_at.nil?
    if started_at.is_a?(Time) && stopped_at.is_a?(Time)
      period = ((stopped_at - started_at) / 1.hour).round.to_i
    else
      period = ((Time.parse(stopped_at) - Time.parse(started_at)) / 1.hour).round.to_i
    end
    period = 24 if period > 24
    period
  end
end
