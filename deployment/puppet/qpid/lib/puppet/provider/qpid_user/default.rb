Puppet::Type.type(:qpid_user).provide(:default) do

  def self.instances
    []
  end

  def create
    default_fail
  end

  def destroy
    default_fail
  end

  def exists?
    default_fail
  end

  def default_fail
    fail('The default provider for qpid_user... all it does is fail.')
  end
end
