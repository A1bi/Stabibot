# frozen_string_literal: true

require 'httparty'

require './config'
require './logger'

class StabiApi
  include HTTParty

  EVENT_PATTERN = %r{<option value="(\d+)" ?(selected=selected)?>\w{2}., (\d{1,2}).(\d{1,2})., (\d{1,2}).(\d{2}) Uhr - Zugang zum Lesesaal</option>}.freeze # rubocop:disable Layout/LineLength
  FORM_INPUT_NAME = 'tx_sbbknowledgeworkshop_pi1'
  FORM_STATIC_INPUTS = { data: 'on', init: 1, title: 1 }.freeze

  base_uri 'https://staatsbibliothek-berlin.de/vor-ort/oeffnungszeiten/' \
           'terminbuchung/terminbuchung-lesesaal/buchungsformular-lesesaal'

  class << self
    def bookable_events
      html = get('/')
      events_from_html(html)
    end

    def book_event(event_id:, personal_info:)
      if Config.simulate_booking?
        sleep(rand(1..5))
        return true
      end

      res = post('/', body: booking_request_body(event_id: event_id,
                                                 personal_info: personal_info))
      res&.code == 302
    end

    private

    def events_from_html(html)
      html.scan(EVENT_PATTERN).each_with_object([]) do |match, events|
        events << {
          id: match[0].to_i,
          date: event_date_from_match(match)
        }
      end
    end

    def event_date_from_match(match)
      DateTime.new(Time.now.year, match[3].to_i, match[2].to_i, match[4].to_i,
                   match[5].to_i)
    end

    def booking_request_body(event_id:, personal_info:)
      body = transformed_personal_info(personal_info)
      body[:event] = event_id
      body.merge!(FORM_STATIC_INPUTS)

      body.transform_keys do |key, _value|
        "#{FORM_INPUT_NAME}[input_#{key}]"
      end
    end

    def transformed_personal_info(info)
      {
        surname: info[:last_name],
        name: info[:first_name],
        email: info[:email],
        institution: info[:pass_number]
      }
    end

    def get(path)
      retry_after_timeout(tries: 4) do
        super(path, timeout: 45)
      end
    end

    def post(path, options = {})
      options[:timeout] = 120
      options[:follow_redirects] = false

      retry_after_timeout(tries: 2) do
        super
      end
    end

    def retry_after_timeout(tries:, &block)
      retries ||= 0
      block.call
    rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET
      if (retries += 1) < tries
        Logger.log "Request timed out, retrying (attempt ##{retries + 1})."
        retry
      end

      Logger.log "Request timed out #{retries} times, giving up."
      nil
    end
  end
end
