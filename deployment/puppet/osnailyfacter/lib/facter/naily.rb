require 'facter'

# This file is created and managed by Astute
astute_settings_path = ['/etc/fuel/astute.yaml', '/etc/astute.yaml']

astute_settings_path.each do |astute_file|
  if File.exist?(astute_file)
    Facter.add('astute_settings_file') do
      setcode { astute_file }
    end
    Facter.add('astute_settings_yaml') do
      setcode { File.read(astute_file) }
    end
    break
  end
end
