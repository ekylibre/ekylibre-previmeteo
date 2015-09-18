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
  def retrieve(parameters, options = {})

    # Get parameters to connect sensor
    id = parameters[:id]
    api = parameters[:api]
    id_station = parameters[:id_station]
    url = parameters[:url]

    started_at = options[:started_at]
    stopped_at = options[:stopped_at]

    type = find_period(started_at, stopped_at) unless started_at.nil? or stopped_at.nil?

    uri = URI(url)
    params = {}
    params[:id] = id
    params[:api] = api
    params[:id_station] = id_station
    params[:type] = type unless type.nil? or type == 0
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    if response.is_a?(Net::HTTPSuccess)
      json_response = JSON.parse(response.body)
      json_response.deep_symbolize_keys!
    end

    if json_response.key? :error
      return {status: :sensor_error, message: json_response[:cause]} if json_response.key? :cause
    end

    values = {}
    report = {}

    info = json_response.try(:[], :info)
    last = json_response.try(:[], :data).try(:[], :last)
    summary = json_response.try(:[], :data).try(:[], :summary)

    if type.nil? || type == 0

      report[:sampling_temporal_mode] = 'instant'

      # instant measures
      values[:temperature] = last.try(:[], :temp).in_celsius
      values[:hygrometry] = last.try(:[], :rh).in_percent
      values[:atmospheric_pressure] = last.try(:[], :press).in_hectopascal
      values[:wind_gust_count] = last.try(:[], :wind_gust)
      values[:rainfall] = last.try(:[], :rain).in_millimeter
      values[:wind_speed] = last.try(:[], :wind_ave).in_meter_per_second
      values[:wind_direction] = last.try(:[], :wind_dir).in_degree

    else

      report[:sampling_temporal_mode] = 'period'

      # period
      values[:average_temperature] = summary.try(:[], :temp_ave).try(:in_celsius)
      values[:minimal_temperature] = summary.try(:[], :temp_min).try(:in_celsius)
      values[:maximal_temperature] = summary.try(:[], :temp_max).try(:in_celsius)
      values[:maximal_rainfall] = summary.try(:[], :rain_max).try(:in_millimeter)
      values[:average_atmospheric_pressure] = summary.try(:[], :press_ave).try(:in_hectopascal)
      values[:minimal_atmospheric_pressure] = summary.try(:[], :press_min).try(:in_hectopascal)
      values[:maximal_atmospheric_pressure] = summary.try(:[], :press_max).try(:in_hectopascal)
      values[:average_hygrometry] = summary.try(:[], :rh_ave).try(:in_percent)
      values[:minimal_hygrometry] = summary.try(:[], :rh_min).try(:in_percent)
      values[:maximal_hygrometry] = summary.try(:[], :rh_max).try(:in_percent)
      values[:average_wind_direction] = summary.try(:[], :wind_dir_ave).try(:in_degree)
      values[:average_wind_speed] = summary.try(:[], :wind_ave).try(:in_meter_per_second)
      values[:maximal_wind_speed] = summary.try(:[], :wind_max).try(:in_meter_per_second)

      values[:pyranometry] = summary.try(:[], :sr).try(:watt_per_square_meter)
    end

    # Timestamp your report with time key: Use GMT/UTC.
    report[:sampled_at] = Time.utc(*last.try(:[], :time_gmt).split(%r([^\d]+))).localtime

    # Add geolocation. Use coordinate space as a {lat, lon} hash or [lat, lon] array
    report[:geolocation] = Charta::Geometry.point(info.try(:[], :lat), info.try(:[], :lon), 4326)
    report[:values] = values
    report[:status] = :ok

    report
  end

  # Find period type
  def find_period(started_at, stopped_at)
    if started_at.is_a? Time and stopped_at.is_a? Time
      period = ((stopped_at - started_at) / 1.hour).round.to_i
    else
      period = ((Time.parse(stopped_at) - Time.parse(started_at)) / 1.hour).round.to_i
    end
    period = 24 if period > 24
    period
  end

end
