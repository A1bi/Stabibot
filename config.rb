# frozen_string_literal: true

class Config
  class << self
    def personal_info
      {
        surname: env_value(:first_name),
        name: env_value(:last_name),
        email: env_value(:email),
        institution: env_value(:pass_number)
      }
    end

    private

    def env_value(name)
      var_name = "USER_#{name.upcase}"
      raise "Environment variable #{var_name} not set" if (value = ENV[var_name]).nil?

      value
    end
  end
end
