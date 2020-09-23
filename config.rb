# frozen_string_literal: true

class Config
  class UndefinedPersonalInfoError < StandardError; end

  class << self
    def people
      (0..).each_with_object([]) do |i, people|
        people << personal_info_at_index(i)
      rescue UndefinedPersonalInfoError
        raise if i.zero?

        break people
      end
    end

    def simulate_booking?
      ENV['SIMULATE_BOOKING'] == 'true'
    end

    private

    def personal_info_at_index(index)
      %i[first_name last_name email pass_number].each_with_object({}) do |key, info|
        info[key] = personal_value_at_index(key, index)
      end
    end

    def personal_value_at_index(name, index)
      var_name = "PERSON_#{index}_#{name.upcase}"
      raise UndefinedPersonalInfoError if (value = ENV[var_name]).nil?

      value
    end
  end
end
