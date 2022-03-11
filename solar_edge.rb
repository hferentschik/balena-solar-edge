# frozen_string_literal: true

require 'amazing_print'
require 'date'
require 'dotenv'
Dotenv.load('./.env')
require 'httparty'
require 'json'
require 'logger'
require 'mqtt'
require 'rufus-scheduler'

abort('SITE must be specified') unless ENV.key? 'SITE'
abort('SERIAL must be specified') unless ENV.key? 'SERIAL'
abort('KEY must be specified') unless ENV.key? 'KEY'

SITE = ENV['SITE']
SERIAL = ENV['SERIAL']
KEY = ENV['KEY']

logger = Logger.new($stdout)

# Module containing functionality to interact with SolarEdge installation.
module SolarEdge
  module TimeUnit
    QUARTER_OF_AN_HOUR = 'QUARTER_OF_AN_HOUR'
    HOUR = 'HOUR'
    DAY = 'DAY'
    WEEK = 'WEEK'
    YEAR = 'YEAR'
  end

  # Provides abilty to retrieve data for SolarEdge inverter.
  class Client
    include HTTParty
    base_uri 'https://monitoringapi.solaredge.com/'

    def initialize(site_id, serial, api_key)
      @site_id = site_id
      @serial = serial
      @api_key = api_key
    end

    def list
      query '/sites/list', {}
    end

    def details
      query "/site/#{@site_id}/details", {}
    end

    def overview
      query "/site/#{@site_id}/overview", {}
    end

    def energy(start_date, end_date, time_unit)
      query "/site/#{@site_id}/energy", { startDate: start_date, endDate: end_date, timeUnit: time_unit }
    end

    def components
      query "/equipment/#{@site_id}/list", {}
    end

    def data(start_time, end_time)
      query "/equipment/#{@site_id}/#{@serial}/data", { startTime: start_time, endTime: end_time }
    end

    def query(endpoint, options)
      options[:api_key] = @api_key
      response = self.class.get(endpoint, { query: options })
      JSON.parse(response.body)
    end
  end
end

def pretty_print(json)
  puts JSON.pretty_generate(json)
end

client = SolarEdge::Client.new SITE, SERIAL, KEY
# today = DateTime.now.strftime '%Y-%m-%d'
# pretty_print(client.energy(today, today, SolarEdge::TimeUnit::QUARTER_OF_AN_HOUR))

# start_of_day = DateTime.now.strftime '%Y-%m-%d 00:00:00'
# end_of_day = DateTime.now.strftime '%Y-%m-%d 23:59:59'

# pretty_print(client.data(start_of_day, end_of_day))

broker_address = ENV.fetch('MQTT_BROKER', 'mqtt')
sample_rate = ENV.fetch('SAMPLE_RATE', 600).to_i

logger.info "creating scheduler for Solar Edge with sample rate #{sample_rate} seconds"
details = client.details
logger.info ap(details)
scheduler = Rufus::Scheduler.new

# rubocop:disable Metrics/BlockLength
scheduler.every sample_rate, first: :now do
  result = client.overview
  now = Time.new
  payload = {
    time: now.strftime('%Y-%m-%dT%T'),
    measurement: 'solar-edge',
    fields: {
      power: result['overview']['currentPower']['power'],
      energy: result['overview']['lastDayData']['energy'],
      energy_month: result['overview']['lastMonthData']['energy'],
      energy_year: result['overview']['lastYearData']['energy'],
      energy_life_time: result['overview']['lifeTimeData']['energy'],
      peak_power: details['details']['peakPower']
    },
    tags: {
      name: details['details']['name'],
      image: details['details']['uris']['SITE_IMAGE'],
      site: details['details']['uris']['PUBLIC_URL'],
      model: details['details']['primaryModule']['modelName']
    }
  }

  begin
    logger.info ap(payload)
    MQTT::Client.connect(host: broker_address, username: ENV['MQTT_USER'], password: ENV['MQTT_PASSWORD']) do |c|
      c.publish('solar', JSON[payload])
    end
  rescue StandardError => e
    logger.info "unable to connect or publish to MQTT client: #{e.message}"
  end
end
# rubocop:enable Metrics/BlockLength

scheduler.join
