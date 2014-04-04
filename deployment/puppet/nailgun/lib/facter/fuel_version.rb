require 'facter'

fuel_version_path = [ '/etc/fuel/version.yaml', '/etc/fuel/nailgun/version.yaml', '/etc/nailgun/version.yaml' ]
read_data = "none"

Facter.add('fuel_version_yaml') do
  fuel_version_path.each do |fuel_version_file|
    if File.exist?(fuel_version_file)
      read_data = File.read(fuel_version_file)
      break
    end
  end
  setcode { read_data }
end
