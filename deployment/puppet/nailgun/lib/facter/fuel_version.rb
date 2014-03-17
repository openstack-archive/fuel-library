require 'facter'

fuel_version_path = '/etc/nailgun/version.yaml'

return unless File.exist?(fuel_version_path)

Facter.add('fuel_version_yaml') do
  setcode { File.read(fuel_version_path) }
end

