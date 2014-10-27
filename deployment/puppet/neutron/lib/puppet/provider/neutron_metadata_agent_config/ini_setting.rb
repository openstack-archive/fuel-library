Puppet::Type.type(:neutron_metadata_agent_config).provide(:ini_setting,
  :parent => Puppet::Type.type(:ini_setting).provider(:ruby)
) do

  def separator
    '='
  end

  def setting
    resource[:name].split('/',2).last
  end

  def section
    resource[:name].split('/',2).first
  end

  def file_path
    '/etc/neutron/metadata_agent.ini'
  end

end