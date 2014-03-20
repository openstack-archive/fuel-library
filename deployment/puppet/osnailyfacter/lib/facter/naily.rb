require 'facter'

# This file is created and managed by Astute
astute_settings_path = '/etc/astute.yaml'

# FIXME: this code do not work with Ruby 2.1
#return unless File.exist?(astute_settings_path)

Facter.add('astute_settings_yaml') do
  setcode { File.read(astute_settings_path) }
end

