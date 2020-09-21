# frozen_string_literal: true

require 'dotenv/load'

require './stabi_api'
require './booked_event'
require './config'
require './logger'

if ARGV[0] == '--delay' && (seconds = ARGV[1].to_i).positive?
  Logger.log "Sleeping for #{seconds} seconds before querying open events..."
  sleep seconds
end

Logger.log 'Querying open events...'
events = StabiApi.bookable_events

if events.none?
  Logger.log 'No open events found.'
  exit true
end

events.each do |event|
  if BookedEvent.exist? event[:id]
    Logger.log "Skipping already booked #{Logger.event_description(event)}."
    next
  end

  if event[:date] < Date.today.next_day || event[:date].hour > 12
    Logger.log "Skipping #{Logger.event_description(event)} as it does not match constraints."
    next
  end

  StabiApi.book_event(event_id: events.first[:id],
                      personal_info: Config.personal_info)

  BookedEvent.create(event[:id])

  Logger.log "Booked #{Logger.event_description(event)}."
end
