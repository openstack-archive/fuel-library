# type for managing persistent interface config options
# Inspired by puppet-network module. Adrien, thanks.

require 'puppetx/l23_utils'

class Puppet::Provider::L23_stored_config_base < Puppet::Provider

  COMMENT_CHAR = '#'

  # The valid vlan ID range is 0-4095; 4096 is out of range
  VLAN_RANGE_REGEX = %r[\d{1,3}|40[0-9][0-5]]

  # @return [Regexp] The regular expression for interface scripts
  SCRIPT_REGEX     = %r[\Aifcfg-[a-z]+[\w\d-]+(?::\d+|\.#{VLAN_RANGE_REGEX})?\Z]

  def self.script_directory
    raise "Should be implemented in more specific class."
  end

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

  # Map provider instances to files based on their name
  #
  # @return [String] The path of the file for the given interface resource
  #
  # @example
  #   prov = RedhatProvider.new(:name => 'eth1')
  #   prov.select_file # => '/etc/sysconfig/network-scripts/ifcfg-eth1'
  #
  def select_file
    "#{self.class.script_directory}/ifcfg-#{name}"
  end

  # Scan all files in the networking directory for interfaces
  #
  # @param script_dir [String] The path to the networking scripts, defaults to
  #   {#SCRIPT_DIRECTORY}
  #
  # @return [Array<String>] All network-script config files on this machine.
  #
  # @example
  #   RedhatProvider.target_files
  #   # => ['/etc/sysconfig/network-scripts/ifcfg-eth0', '/etc/sysconfig/network-scripts/ifcfg-eth1']
  def self.target_files(script_dir = nil)
    script_dir ||= script_directory
    return [] if ! File.directory?(script_dir)
    entries = Dir.entries(script_dir).select {|entry| entry.match SCRIPT_REGEX}
    entries.map {|entry| File.join(script_directory, entry)}
  end

  def self.post_flush_hook(filename)
    File.chmod(0644, filename) if File.exist? filename
  end

  def self.puppet_header
    str = "# *********************************************************************\n"\
          "# This file is being managed by Puppet. Changes to interfaces\n"\
          "# that are not being managed by Puppet will persist;\n"\
          "# however changes to interfaces that are being managed by Puppet will\n"\
          "# be overwritten.\n"\
          "# *********************************************************************"
    str
  end

end
# vim: set ts=2 sw=2 et :
