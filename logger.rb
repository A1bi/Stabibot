# frozen_string_literal: true

class Logger
  class << self
    def log(message)
      puts "<#{Time.now}> <Thread #{current_thread_index}> #{message}"
      $stdout.flush
    end

    def event_description(event)
      "event with id=#{event[:id]} (#{event[:date].strftime('%FT%R')})"
    end

    private

    def current_thread_index
      Thread.list.index(Thread.current)
    end
  end
end
