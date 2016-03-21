require 'facter'

fuel_release_path = '/etc/fuel_release'

Facter.add('fuel_release') do
  if File.exist?(fuel_release_path)
    read_data = File.read(fuel_release_path).strip
  end
  setcode { read_data }
end
