Puppet::Type.type(:l23_store_config).provide(:ovs_centos6) do

  def exists?
    true
  end

  def create
    true
  end

  def destroy
    true
  end

  def config
    {}
  end

  def config=(value)
    true
  end

end
