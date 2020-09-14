# frozen_string_literal: true

require './stabi_api'
require './booked_event'

StabiApi.bookable_events.each do |event|
  next if BookedEvent.exist? event[:id]

  puts event

  # StabiApi.book_event(event_id: events.first[:id],
  #                     personal_info: {
  #                       surname: 'Foo',
  #                       name: 'Bar',
  #                       email: 'albo@a0s.de',
  #                       institution: '1213456'
  #                     })

  BookedEvent.create(event[:id])
end
