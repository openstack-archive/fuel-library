require 'facter'

fuel_release_path = '/etc/fuel_release'
# FIXME(kozhukalov): This default value is necessary
# to solve chicken/egg problem. The thing is that
# deployment tests use the ISO where this file is not
# installed. This default value should be removed
# once the ISO is updated.
read_data = "9.0"

Facter.add('fuel_release') do
  if File.exist?(fuel_release_path)
    read_data = File.read(fuel_release_path).strip
  end
  setcode { read_data }
end
