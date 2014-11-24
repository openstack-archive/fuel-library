require File.join File.dirname(__FILE__), '../nova_common.rb'

Puppet::Type.type(:nova_secgroup).provide(:nova, :parent => Puppet::Provider::Nova_common) do
  desc "Manage security groups in nova"

  commands :nova => 'nova'

  def secgroup_name
    @resource[:name]
  end

  def secgroup_description
    @resource[:description]
  end

  def exists?
    debug "Call exists? on nova secgroup '#{secgroup_name}'"
    out = secgroup.is_a? Hash
    debug "Return: #{out}"
    out
  end

  def create
    debug "Call create on nova secgroup '#{secgroup_name}' - '#{secgroup_description}'"
    connection.create_security_group secgroup_name, secgroup_description
  end

  def destroy
    debug "Call destroy on nova secgroup '#{secgroup_name}'"
    connection.delete_security_group secgroup[:id]
  end

  def description
    debug "Call description on nova secgroup '#{secgroup_name}'"
    out = nil
    out = secgroup[:description] if secgroup
    debug "Return: #{out}"
    out
  end

  def description=(value)
    debug "Call description= on nova secgroup '#{secgroup_name}' set #{value}"
    connection.update_security_group secgroup[:id], secgroup_name, secgroup_description
  end
  
end
