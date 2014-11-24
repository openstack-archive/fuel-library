Puppet::Type.type(:nova_secgroup).provide(:nova) do
  desc "Manage security groups in nova"

  commands :nova => 'nova'

  def secgroup_name
    resource[:name]
  end

  def secgroup_description
    resource[:description]
  end

  def list
    secgroups = {}
    nova("secgroup-list").split("\n").each do |line|
      fields = line.split('|').map { |f| f.chomp.strip }
      next if fields.length < 2
      next if fields[1] == 'Id'
      secgroups.store fields[2], fields[3]
    end
    Puppet.debug "Found secgroups: #{secgroups.inspect}"
    secgroups
  end

  def exists?
    debug "Call exists? on nova secgroup '#{secgroup_name}'"
    out = list.key? secgroup_name
    debug "Return: #{out}"
    out
  end

  def create
    debug "Call create on nova secgroup '#{secgroup_name}' - '#{secgroup_description}'"
    nova "secgroup-create", secgroup_name, secgroup_description
  end

  def destroy
    debug "Call destroy on nova secgroup '#{secgroup_name}'"
    nova "secgroup-delete", secgroup_name
  end

  def description
    debug "Call description on nova secgroup '#{secgroup_name}'"
    out = list[secgroup_name]
    debug "Return: #{out}"
    out
  end

  def description=(value)
    debug "Call description= on nova secgroup '#{secgroup_name}' set #{value}"
    nova 'secgroup-update', secgroup_name, secgroup_name, value
  end
  
end
