Puppet::Type.type(:ini_setting)#.providers

Puppet::Type.type(:glance_api_paste_ini).provide(
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
    '/etc/glance/glance-api-paste.ini'
  end

end
