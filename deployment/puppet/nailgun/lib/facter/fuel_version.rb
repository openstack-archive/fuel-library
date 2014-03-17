require 'facter'

fuel_version_path = '/etc/nailgun/version.yaml'

Facter.add('fuel_version_yaml') do
  if File.exist?(fuel_version_path)
    setcode { File.read(fuel_version_path) }
  else
    setcode { "none" }
  end
end
