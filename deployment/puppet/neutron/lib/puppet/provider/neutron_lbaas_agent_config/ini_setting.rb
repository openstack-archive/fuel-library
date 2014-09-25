Puppet::Type.type(:neutron_lbaas_agent_config).provide(
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
    '/etc/neutron/lbaas_agent.ini'
  end

end
