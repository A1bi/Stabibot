# frozen_string_literal: true

require 'dotenv/load'

require './event_booker'
require './logger'

max_attempts = ARGV[0].to_i || 1
attempt ||= 0
booker = EventBooker.new

loop do
  Logger.log "--- Attempt ##{attempt + 1} ---"

  booked_events = booker.find_and_book_events
  break unless (attempt += 1) < max_attempts && booked_events.none?

  sleep 1
end
