# frozen_string_literal: true

require 'httparty'
require 'fileutils'

require './config'
require './logger'

class StabiApi
  include HTTParty

  EVENT_PATTERN = %r{<option value="(\d+)" ?(selected=selected)?>\w{2}., (\d{1,2}).(\d{1,2})., (\d{1,2}).(\d{2}) Uhr - Zugang zum Lesesaal</option>}.freeze # rubocop:disable Layout/LineLength
  FORM_INPUT_NAME = 'tx_sbbknowledgeworkshop_pi1'
  FORM_STATIC_INPUTS = { data: 'on', init: 1, title: 1 }.freeze
  REMOTE_RESPONSES_DIR = File.join(File.dirname(__FILE__), 'remote_responses').freeze

  base_uri 'https://staatsbibliothek-berlin.de/vor-ort/oeffnungszeiten/' \
           'terminbuchung/terminbuchung-lesesaal/buchungsformular-lesesaal'

  class << self
    def bookable_events
      res = save_response(:bookable_events) { get('/') }
      return [] if (html = res&.body).nil?

      events_from_html(html)
    end

    def book_event(event_id:, personal_info:)
      if Config.simulate_booking?
        sleep(rand(1..5))
        return true
      end

      res = save_response(:book_event) do
        post('/', body: booking_request_body(event_id: event_id,
                                             personal_info: personal_info))
      end

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
      retry_after_timeout do
        super(path, timeout: 45)
      end
    end

    def post(path, options = {})
      options[:timeout] = 120
      options[:follow_redirects] = false

      retry_after_timeout do
        super
      end
    end

    def save_response(filename)
      res = yield

      if Config.save_remote_responses?
        FileUtils.mkdir_p(REMOTE_RESPONSES_DIR)
        filename = "#{filename}_#{current_thread_index}"
        path = File.join(REMOTE_RESPONSES_DIR, "#{filename}.txt")
        File.write(path, format_response_for_file(res))
      end

      res
    end

    def format_response_for_file(res)
      headers = res.headers.map { |name, value| "#{name}: #{value.join(',')}" }
      [res.code, *headers, res.body].join("\n")
    end

    def retry_after_timeout(tries: 5, &block)
      retries ||= 0
      block.call
    rescue Timeout::Error, SystemCallError => e
      if (retries += 1) < tries
        Logger.log "Raised #{e.class.name}, retrying (attempt ##{retries + 1})."
        retry
      end

      Logger.log "Request timed out #{retries} times, giving up."
      nil
    end

    def current_thread_index
      Thread.list.index(Thread.current)
    end
  end
end
