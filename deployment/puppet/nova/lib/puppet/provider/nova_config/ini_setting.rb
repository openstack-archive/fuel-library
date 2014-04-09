Puppet::Type.type(:nova_config).provide(
  :ini_setting,
  :parent => Puppet::Type.type(:ini_setting).provider(:ruby)
) do

  # the setting is always default
  # this if for backwards compat with the old puppet providers for nova_config
  def section
    resource[:name].split('/', 2)[0]
  end

  # assumes that the name was the setting
  # this is to maintain backwards compat with the the older
  # stuff
  def setting
    resource[:name].split('/', 2)[1]
  end

  def separator
    '='
  end

  def self.file_path
    '/etc/nova/nova.conf'
  end

  # this needs to be removed. This has been replaced with the class method
  def file_path
    self.class.file_path
  end

end
