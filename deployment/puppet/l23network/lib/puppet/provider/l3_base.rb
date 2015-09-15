require File.join(File.dirname(__FILE__), 'interface_toolset')

class Puppet::Provider::L3_base < Puppet::Provider::InterfaceToolset

  def self.prefetch(resources)
    interfaces = instances
    resources.keys.each do |name|
      if provider = interfaces.find{ |ii| ii.name == name }
        resources[name].provider = provider
      end
    end
  end

end

# vim: set ts=2 sw=2 et :