require 'facter'

fuel_openstack_version_path = '/etc/fuel_openstack_version'
# FIXME(kozhukalov): This default value is necessary
# to solve chicken/egg problem. The thing is that
# deployment tests use the ISO where this file is not
# installed. This default value should be removed
# once the ISO is updated.
read_data = "mitaka-9.0"

Facter.add('fuel_openstack_version') do
  if File.exist?(fuel_openstack_version_path)
    read_data = File.read(fuel_openstack_version_path).strip
  end
  setcode { read_data }
end
