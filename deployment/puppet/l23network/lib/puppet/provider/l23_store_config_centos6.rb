require File.join(File.dirname(__FILE__), '..','..','puppet/provider/L23_store_config_base')

class Puppet::Provider::L23_store_config_centos6 < Puppet::Provider::L23_store_config_base

  def separator_char
    '='
  end

  def file
    "/etc/sysconfig/network-scripts/#{resource[:file]}"
  end

end