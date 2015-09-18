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

  def find_period(started_at, stopped_at)
    if started_at.is_a? Time and stopped_at.is_a? Time
      period = ((stopped_at - started_at) / 1.hour).round.to_i
    else
      period = ((Time.parse(stopped_at) - Time.parse(started_at)) / 1.hour).round.to_i
    end
    period = 24 if period > 24
    period
  end

  # ActiveSensor::Controller sends an +options+ hash, with *started_at* and
  # *stopped_at* as delimiters for a periodic summary (Time ruby objects).
  # If these keys aren't supplied, please feel free to return instant values.
  # Dates are formatted in UTC.
  # Example: 2015-09-14 17:12:40 +0200
  def retrieve(options = {})

    # Get parameters to connect sensor
    id = parameters[:id]
    api = parameters[:api]
    id_station = parameters[:id_station]
    url = parameters[:url]

    started_at = options.try(:[], :started_at)
    stopped_at = options.try(:[], :stopped_at)

    type = find_period(started_at, stopped_at) unless started_at.nil? or stopped_at.nil?

    uri = URI(url)
    params = {}
    params[:id] = id
    params[:api] = api
    params[:id_station] = id_station
    params[:type] = type unless type.nil? or type == 0
    uri.query = URI.encode_www_form(params)

    res = Net::HTTP.get_response(uri)

    if res.is_a?(Net::HTTPSuccess)
      results = JSON.parse(res.body)
      results.deep_symbolize_keys!
    end

    if results.key? :error
      fail results[:cause] if results.key? :cause
    end

    list = {}

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

    # Existing indicators:
    # - temperature
    # - hygrometry
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
    # - average_hygrometry
    # - minimal_hygrometry
    # - maximal_hygrometry
    # - average_wind_speed
    # - average_wind_direction
    # - pyranometry

    info = results.try(:[], :info)
    last = results.try(:[], :data).try(:[], :last)
    summary = results.try(:[], :data).try(:[], :summary)

    if type.nil? or type == 0

      list[:sampling_temporal_mode] = 'instant'

      # instant measures
      list[:temperature] = last.try(:[], :temp).in_celsius
      list[:hygrometry] = last.try(:[], :rh).in_percent
      list[:atmospheric_pressure] = last.try(:[], :press).in_hectopascal
      list[:wind_gust_count] = last.try(:[], :wind_gust)
      list[:rainfall] = last.try(:[], :rain).in_millimeter
      list[:wind_speed] = last.try(:[], :wind_ave).in_meter_per_second
      list[:wind_direction] = last.try(:[], :wind_dir).in_degree

    else

      list[:sampling_temporal_mode] = 'period'

      # period
      list[:average_temperature] = summary.try(:[], :temp_ave).try(:in_celsius)
      list[:minimal_temperature] = summary.try(:[], :temp_min).try(:in_celsius)
      list[:maximal_temperature] = summary.try(:[], :temp_max).try(:in_celsius)
      list[:maximal_rainfall] = summary.try(:[], :rain_max).try(:in_millimeter)
      list[:average_atmospheric_pressure] = summary.try(:[], :press_ave).try(:in_hectopascal)
      list[:minimal_atmospheric_pressure] = summary.try(:[], :press_min).try(:in_hectopascal)
      list[:maximal_atmospheric_pressure] = summary.try(:[], :press_max).try(:in_hectopascal)
      list[:average_hygrometry] = summary.try(:[], :rh_ave).try(:in_percent)
      list[:minimal_hygrometry] = summary.try(:[], :rh_min).try(:in_percent)
      list[:maximal_hygrometry] = summary.try(:[], :rh_max).try(:in_percent)
      list[:average_wind_speed] = summary.try(:[], :wind_ave).try(:in_meter_per_second)
      list[:average_wind_direction] = summary.try(:[], :wind_dir_ave).try(:in_degree)
      list[:maximal_wind_speed] = summary.try(:[], :wind_max).try(:in_meter_per_second)

      list[:pyranometry] = summary.try(:[], :sr).try(:watt_per_square_meter)
    end

    # Timestamp your list with time key: Use GMT/UTC.
    list[:time] = last.try(:[], :time_gmt)

    # Add geolocation. Use coordinate space as a {lat, lon} hash or [lat, lon] array
    list[:geolocation] = { lat: info.try(:[], :lat), lon: info.try(:[], :lon) }

    list
  end
end
