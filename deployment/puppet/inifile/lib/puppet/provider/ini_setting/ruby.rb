require File.expand_path('../../../util/ini_file', __FILE__)

Puppet::Type.type(:ini_setting).provide(:ruby) do
  def exists?
    ini_file.get_value(resource[:section], resource[:setting]) == resource[:value].to_s
  end

  def create
    ini_file.set_value(resource[:section], resource[:setting], resource[:value])
    ini_file.save
    @ini_file = nil
  end


  private
  def ini_file
    @ini_file ||= Puppet::Util::IniFile.new(resource[:path],
                                            resource[:key_val_separator])
  end
end
