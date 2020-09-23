# frozen_string_literal: true

require 'yaml'

require './config'

class BookedEvent
  EVENTS_FILE_PATH = 'booked_events.yml'

  class << self
    def exist?(id)
      event_ids.include? id
    end

    def create(id)
      return if Config.simulate_booking? || exist?(id)

      event_ids << id
      persist_event_ids
    end

    private

    def event_ids
      @event_ids ||= begin
        if File.exist? EVENTS_FILE_PATH
          events = YAML.safe_load(File.read(EVENTS_FILE_PATH))
          raise 'booked_events.yml has invalid structure' unless (ids = events['ids']).is_a? Array

          ids
        else
          []
        end
      end
    end

    def persist_event_ids
      File.open(EVENTS_FILE_PATH, 'w') do |file|
        file.write({ 'ids' => event_ids }.to_yaml)
      end
    end
  end
end
