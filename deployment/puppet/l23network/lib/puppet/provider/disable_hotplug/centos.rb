Puppet::Type.type(:disable_hotplug).provide(:centos) do
  defaultfor :osfamily => :redhat

  def exists?
    info("\n Is not yet implemented! \n")
  end

  def create
    info("\n Is not yet implemented! \n")
  end

  def destroy
    info("\n Is not yet implemented! \n")
  end

end

# vim: set ts=2 sw=2 et :
