require File.expand_path('../../../util/ini_file', __FILE__)

Puppet::Type.type(:ini_setting).provide(:ruby) do

  def exists?
    ini_file.get_value(section, setting)
  end

  def create
    ini_file.set_value(section, setting, resource[:value])
    ini_file.save
    @ini_file = nil
  end

  def destroy
    ini_file.remove_setting(section, setting)
    ini_file.save
    @ini_file = nil
  end

  def value
    ini_file.get_value(section, setting)
  end

  def value=(value)
    ini_file.set_value(section, setting, resource[:value])
    ini_file.save
  end

  def section
    resource[:section]
  end

  def setting
    resource[:setting]
  end

  def file_path
    resource[:path]
  end

  def separator
    resource[:key_val_separator] || '='
  end

  private
  def ini_file
    @ini_file ||= Puppet::Util::IniFile.new(file_path, separator)
  end

end
