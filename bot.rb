# frozen_string_literal: true

require 'dotenv/load'

require './stabi_api'
require './booked_event'
require './config'

events = StabiApi.bookable_events

if events.none?
  puts 'No open events found.'
  exit true
end

events.each do |event|
  next if BookedEvent.exist? event[:id]

  if event[:date] < DateTime.now || event[:date].hour < 13 || event[:date].wednesday?
    puts "Skipping event with id=#{event[:id]} as it does not match constraints."
    next
  end

  StabiApi.book_event(event_id: events.first[:id],
                      personal_info: Config.personal_info)

  BookedEvent.create(event[:id])

  puts "Booked event with id=#{event[:id]}."
end
