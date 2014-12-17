require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/l23_store_config_centos6')

Puppet::Type.type(:l23_store_config).provide(:lnx_centos6, :parent => Puppet::Provider::L23_store_config_centos6) do
  commands(
    :sed => "/bin/sed"
  )

  def exists?
    get_value(key)
  end

  def create
    set_value(key, resource[:value])
  end

  def destroy
    if exists?
      sed("-ire", "/^\s*#{key}\s*#{separator_char}.*$/D", file)
    end
  end

  def config
    get_value(key)
  end

  def config=(value)
    set_value(key, value)
  end

end
