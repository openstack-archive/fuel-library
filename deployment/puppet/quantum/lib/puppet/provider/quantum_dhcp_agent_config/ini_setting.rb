Puppet::Type.type(:ini_setting)#.providers

Puppet::Type.type(:quantum_dhcp_agent_config).provide(
  :ini_setting,
  :parent => Puppet::Type::Ini_setting::ProviderRuby
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
    '/etc/quantum/dhcp_agent.ini'
  end

end
