require File.expand_path('../external_iterator', __FILE__)
require File.expand_path('../ini_file/section', __FILE__)

module Puppet
module Util
  class IniFile

    SECTION_REGEX = /^\s*\[([\w\d\.\\\/\-\:]+)\]\s*$/
    SETTING_REGEX = /^\s*([\w\d\.\\\/\-]+)\s*=\s*([\S]+)\s*$/

    def initialize(path, key_val_separator = ' = ')
      @path = path
      @key_val_separator = key_val_separator
      @section_names = []
      @sections_hash = {}
      if File.file?(@path)
        parse_file
      end
    end

    def section_names
      @section_names
    end

    def get_value(section_name, setting)
      if (@sections_hash.has_key?(section_name))
        @sections_hash[section_name].get_value(setting)
      end
    end

    def set_value(section_name, setting, value)
      unless (@sections_hash.has_key?(section_name))
        add_section(Section.new(section_name, nil, nil, nil))
      end

      section = @sections_hash[section_name]
      if (section.has_existing_setting?(setting))
        update_line(section, setting, value)
        section.update_existing_setting(setting, value)
      else
        section.set_additional_setting(setting, value)
      end
    end

    def save
      File.open(@path, 'w') do |fh|

        @section_names.each do |name|
          section = @sections_hash[name]

          if section.start_line.nil?
            fh.puts("\n[#{section.name}]")
          elsif ! section.end_line.nil?
            (section.start_line..section.end_line).each do |line_num|
              fh.puts(lines[line_num])
            end
          end

          section.additional_settings.each_pair do |key, value|
            fh.puts("#{key}#{@key_val_separator}#{value}")
          end
        end
      end
    end


    private
    def add_section(section)
      @sections_hash[section.name] = section
      @section_names << section.name
    end

    def parse_file
      line_iter = create_line_iter

      # We always create a "global" section at the beginning of the file, for
      # anything that appears before the first named section.
      section = read_section('', 0, line_iter)
      add_section(section)
      line, line_num = line_iter.next

      while line
        if (match = SECTION_REGEX.match(line))
          section = read_section(match[1], line_num, line_iter)
          add_section(section)
        end
        line, line_num = line_iter.next
      end
    end

    def read_section(name, start_line, line_iter)
      settings = {}
      end_line_num = nil
      while true
        line, line_num = line_iter.peek
        if (line_num.nil? or match = SECTION_REGEX.match(line))
          return Section.new(name, start_line, end_line_num, settings)
        elsif (match = SETTING_REGEX.match(line))
          settings[match[1]] = match[2]
        end
        end_line_num = line_num
        line_iter.next
      end
    end

    def update_line(section, setting, value)
      (section.start_line..section.end_line).each do |line_num|
        if (match = SETTING_REGEX.match(lines[line_num]))
          if (match[1] == setting)
            lines[line_num] = "#{setting}#{@key_val_separator}#{value}"
          end
        end
      end
    end

    def create_line_iter
      ExternalIterator.new(lines)
    end

    def lines
        @lines ||= IniFile.readlines(@path)
    end

    # This is mostly here because it makes testing easier--we don't have
    #  to try to stub any methods on File.
    def self.readlines(path)
        # If this type is ever used with very large files, we should
        #  write this in a different way, using a temp
        #  file; for now assuming that this type is only used on
        #  small-ish config files that can fit into memory without
        #  too much trouble.
        File.readlines(path)
    end

  end
end
end
