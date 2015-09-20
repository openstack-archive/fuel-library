Puppet::Type.type(:enable_hotplug).provide(:centos) do
  defaultfor :osfamily => :redhat

  def exists?
    info("\n Is not yet implemented!")
  end

  def create
    info("\n Is not yet implemented!")
  end

  def destroy
    info("\n Is not yet implemented!")
  end

end

# vim: set ts=2 sw=2 et :
