Puppet::Type.type(:ceph_conf).provide(
  :ini_setting,
  :parent => Puppet::Type.type(:ini_setting).provider(:ruby)
) do

  def section
    resource[:name].split('/', 2).first
  end

  def setting
    resource[:name].split('/', 2).last
  end
  #Ceph-deploy 1.2.3 uses ' = ' not '='
  def separator
    ' = '
  end

  def self.file_path
    '/etc/ceph/ceph.conf'
  end

  # this needs to be removed. This has been replaced with the class method
  def file_path
    self.class.file_path
  end

end
