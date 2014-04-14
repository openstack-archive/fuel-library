require 'facter'

# This file is created and managed by Astute
astute_settings_path = ['/etc/fuel/astute.yaml', '/etc/astute.yaml']

astute_settings_path.each do |astute_file|
  if FileTest.file?(astute_file)
    Facter.add('astute_settings_yaml') do
      setcode { File.read(astute_file) }
    end
    break
  end
end

