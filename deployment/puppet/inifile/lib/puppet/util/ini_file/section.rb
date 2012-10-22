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

    def remove_existing_setting(setting_name)
      if (@existing_settings.delete(setting_name))
        if @end_line
          @end_line = @end_line - 1
        end
      end
    end

    def set_additional_setting(setting_name, value)
      @additional_settings[setting_name] = value
    end

    # Decrement the start and end line numbers for the section (if they are
    # defined); this is intended to be called when a setting is removed
    # from a section that comes before this section in the ini file.
    def decrement_line_nums()
      if @start_line
        @start_line = @start_line - 1
      end
      if @end_line
        @end_line = @end_line - 1
      end
    end

  end
end
end
end
