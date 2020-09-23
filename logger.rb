# frozen_string_literal: true

class Logger
  class << self
    def log(message)
      puts "<#{Time.now}> #{message}"
      $stdout.flush
    end

    def event_description(event)
      "event with id=#{event[:id]} (#{event[:date].strftime('%FT%R')})"
    end
  end
end
