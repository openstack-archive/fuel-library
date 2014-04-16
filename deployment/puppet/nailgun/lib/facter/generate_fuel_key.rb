require 'facter'
fuel_uuid_path = [ '/etc/fuel/fuel-uuid', '/etc/fuel-uuid' ]

fuel_uuid_path.each do |uuid_file|
  if File.exist?(uuid_file)
    Facter.add('generate_fuel_key') do
      setcode { File.read(uuid_file).chomp }
    end
    break
  end
end
