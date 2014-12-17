require File.join(File.dirname(__FILE__), '..','..','puppet/provider/l23_store_config_base')

class Puppet::Provider::L23_store_config_ubuntu < Puppet::Provider::L23_store_config_base

  def separator_char
    ' '
  end

  def file
    "/etc/network/interfaces.d/#{resource[:file]}"
  end

end