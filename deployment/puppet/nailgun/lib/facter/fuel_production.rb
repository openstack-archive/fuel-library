require 'facter'

fuel_production_path = '/etc/fuel_production'
read_data = ""

Facter.add('fuel_production') do
  if File.exist?(fuel_production_path)
    read_data = File.read(fuel_production_path).strip
  end
  setcode { read_data }
end
