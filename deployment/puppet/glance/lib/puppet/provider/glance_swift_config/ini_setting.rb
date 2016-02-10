Puppet::Type.type(:glance_swift_config).provide(
  :ini_setting,
  :parent => Puppet::Type.type(:openstack_config).provider(:ruby)
) do

  def self.file_path
    '/etc/glance/glance-swift.conf'
  end

end
