# type for managing persistent interface config options
# Inspired by puppet-network module. Adrien, thanks.

class Puppet::Provider::L23_stored_config_base < Puppet::Provider

  COMMENT_CHAR = '#'

  # The valid vlan ID range is 0-4095; 4096 is out of range
  VLAN_RANGE_REGEX = %r[\d{1,3}|40[0-9][0-5]]

  # @return [Regexp] The regular expression for interface scripts on redhat systems
  SCRIPT_REGEX     = %r[\Aifcfg-[a-z]+[a-z\d]+(?::\d+|\.#{VLAN_RANGE_REGEX})?\Z]

  class MalformedInterfacesError < Puppet::Error
    def initialize(msg = nil)
      msg = "Malformed config file; cannot instantiate stored_config resources for interface #{name}" if msg.nil?
      super
    end
  end

  def self.raise_malformed
    @failed = true
    raise MalformedInterfacesError
  end

  def self.post_flush_hook(filename)
    File.chmod(0644, filename) if File.exist? filename
  end

end