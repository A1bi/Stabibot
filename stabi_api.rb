# frozen_string_literal: true

require 'httparty'

class StabiApi
  include HTTParty

  EVENT_PATTERN = %r{<option value="(\d+)" ?(selected=selected)?>\w{2}., (\d{1,2}).(\d{1,2})., (\d{1,2}).(\d{2}) Uhr - Zugang zum Lesesaal</option>}.freeze # rubocop:disable Layout/LineLength
  FORM_INPUT_NAME = 'tx_sbbknowledgeworkshop_pi1'
  FORM_STATIC_INPUTS = { data: 'on', init: 1 }.freeze

  base_uri 'https://staatsbibliothek-berlin.de/vor-ort/oeffnungszeiten/' \
           'terminbuchung/terminbuchung-lesesaal/buchungsformular-lesesaal'

  open_timeout 30

  class << self
    def bookable_events
      html = retry_after_timeout do
        get('/')
      end
      events_from_html(html)
    end

    def book_event(event_id:, personal_info:)
      res = retry_after_timeout(tries: 2) do
        post('/', body: booking_request_body(event_id: event_id,
                                             personal_info: personal_info))
      end
      raise "Event with id=#{event_id} could not be booked" if res.body.include? 'leider ausgebucht'
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
      body = personal_info.dup
      body[:event] = event_id
      body.merge!(FORM_STATIC_INPUTS)

      body.transform_keys do |key, _value|
        "#{FORM_INPUT_NAME}[input_#{key}]"
      end
    end

    def retry_after_timeout(tries: 3, &block)
      retries ||= 0
      block.call
    rescue Net::OpenTimeout
      if (retries += 1) < tries
        puts "Request timed out, retrying (attempt ##{retries + 1})."
        retry
      end

      raise "Request timed out #{retries} times, giving up."
    end
  end
end
