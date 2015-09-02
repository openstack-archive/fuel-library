require 'facter'

fuel_openstack_version_path = '/etc/fuel_openstack_version'
read_data = ""

Facter.add('fuel_openstack_version') do
  if File.exist?(fuel_openstack_version_path)
    read_data = File.read(fuel_openstack_version_path).strip
  end
  setcode { read_data }
end
