Puppet::Type.type(:nova_network).provide(:default) do

  desc "This is a default provider that does nothing. This allows us to install nova-manage on the same puppet run where we want to use it."

  def create
    return false
  end

  def destroy
    return false
  end

  def exists?
    fail('This is just the default provider for nova_admin, all it does is fail')
  end
end
