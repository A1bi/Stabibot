# frozen_string_literal: true

require 'dotenv/load'

require './stabi_api'
require './booked_event'
require './config'

StabiApi.bookable_events.each do |event|
  next if BookedEvent.exist? event[:id]

  puts event

  # StabiApi.book_event(event_id: events.first[:id],
  #                     personal_info: Config.personal_info)

  BookedEvent.create(event[:id])
end
