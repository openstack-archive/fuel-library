require 'facter'

# This file created and managed by Astute
ASTUTE_SETTINGS_PATH = '/etc/astute.yaml'

return unless File.exist?(ASTUTE_SETTINGS_PATH)

Facter.add('astute_settings_yaml') do
  setcode { File.read(ASTUTE_SETTINGS_PATH) }
end

