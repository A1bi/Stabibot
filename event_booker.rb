# frozen_string_literal: true

require 'yaml'

require './stabi_api'
require './config'
require './logger'

class EventBooker
  EVENTS_FILE_PATH = 'booked_events.yml'

  def find_and_book_events
    bookable_events.each_with_object([]) do |event, booked_events|
      next unless should_book_event?(event)

      book_event(event)
      booked_events << event
    end
  end

  private

  def bookable_events
    log 'Querying open events...'
    events = StabiApi.bookable_events
    log 'No open events found.' if events.none?
    events
  end

  def book_event(event)
    log "Booking #{Logger.event_description(event)}..."

    threads = book_event_for_people_concurrently(event)

    add_booked_event(event) if threads.any?(&:value)
    return unless threads.all?(&:value)

    log "Successfully booked #{Logger.event_description(event)} for all people."
  end

  def book_event_for_people_concurrently(event)
    Config.people.map do |person|
      Thread.new do
        log_booking_for_person(person, '..')

        success = StabiApi.book_event(event_id: event[:id], personal_info: person)

        message = success ? 'succeeded' : 'failed'
        log_booking_for_person(person, " #{message}")

        success
      end
    end
  end

  def should_book_event?(event)
    if event_booked?(event)
      log "Skipping already booked #{Logger.event_description(event)}."
      return
    end

    unless event_matches_contraints?(event)
      log "Skipping #{Logger.event_description(event)} as it does not match constraints."
      return
    end

    true
  end

  def event_booked?(event)
    booked_event_ids.include? event[:id]
  end

  def event_matches_contraints?(event)
    event[:date] > Date.today.next_day && event[:date].hour < 12
  end

  def add_booked_event(event)
    return if Config.simulate_booking? || event_booked?(event)

    booked_event_ids << event[:id]
    persist_booked_event_ids
  end

  def booked_event_ids
    @booked_event_ids ||= begin
      if File.exist? EVENTS_FILE_PATH
        events = YAML.safe_load(File.read(EVENTS_FILE_PATH))
        raise 'booked_events.yml has invalid structure' unless (ids = events['ids']).is_a? Array

        ids
      else
        []
      end
    end
  end

  def persist_booked_event_ids
    File.open(EVENTS_FILE_PATH, 'w') do |file|
      file.write({ 'ids' => booked_event_ids }.to_yaml)
    end
  end

  def log_booking_for_person(person, message)
    log "Booking for #{person[:first_name]} #{person[:last_name]}#{message}."
  end

  def log(message)
    Logger.log message
  end
end
