module Puppet
module Util
class IniFile
  class Section
    def initialize(name, start_line, end_line, settings)
      @name = name
      @start_line = start_line
      @end_line = end_line
      @existing_settings = settings.nil? ? {} : settings
      @additional_settings = {}
    end

    attr_reader :name, :start_line, :end_line, :additional_settings

    def get_value(setting_name)
      @existing_settings[setting_name] || @additional_settings[setting_name]
    end

    def has_existing_setting?(setting_name)
      @existing_settings.has_key?(setting_name)
    end

    def update_existing_setting(setting_name, value)
      @existing_settings[setting_name] = value
    end

    def set_additional_setting(setting_name, value)
      @additional_settings[setting_name] = value
    end

  end
end
end
end