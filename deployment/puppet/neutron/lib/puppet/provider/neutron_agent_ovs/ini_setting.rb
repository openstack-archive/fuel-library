Puppet::Type.type(:neutron_agent_ovs).provide(
  :ini_setting,
  :parent => Puppet::Type.type(:ini_setting).provider(:ruby)
) do

  def section
    resource[:name].split('/', 2).first
  end

  def setting
    resource[:name].split('/', 2).last
  end

  def separator
    '='
  end

  def file_path
    if Facter['operatingsystem'].value == 'Ubuntu'
      '/etc/neutron/plugins/ml2/ml2_conf.ini'
    else
      '/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini'
    end
  end

end
