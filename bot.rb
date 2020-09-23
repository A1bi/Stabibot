# frozen_string_literal: true

require 'dotenv/load'

require './stabi_api'
require './booked_event'
require './config'
require './logger'

max_attempts = ARGV[0].to_i || 1
attempt ||= 0
events_booked = false

loop do
  Logger.log "--- Attempt ##{attempt + 1} ---"

  Logger.log 'Querying open events...'
  events = StabiApi.bookable_events

  Logger.log 'No open events found.' if events.none?

  events.each do |event|
    if BookedEvent.exist? event[:id]
      Logger.log "Skipping already booked #{Logger.event_description(event)}."
      next
    end

    if event[:date] < Date.today.next_day || event[:date].hour > 12
      Logger.log "Skipping #{Logger.event_description(event)} as it does not match constraints."
      next
    end

    Logger.log "Booking #{Logger.event_description(event)}..."
    StabiApi.book_event(event_id: event[:id],
                        personal_info: Config.personal_info)

    BookedEvent.create(event[:id])
    Logger.log "Successfully booked #{Logger.event_description(event)}."
    events_booked = true
  end

  break unless (attempt += 1) < max_attempts && !events_booked

  sleep 1
end
