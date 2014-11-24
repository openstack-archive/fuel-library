Puppet::Type.type(:nova_secrule).provide(:nova) do
  desc "Manage security rules in nova"

  commands :nova => 'nova'

  def compare_keys(a,b,keys)
    match = true
    keys.each do |key|
      match = false unless a[key].to_s == b[key].to_s
      break unless match
    end
    match
  end

  def exists?
    debug "Call exists? on security_rule '#{@resource[:security_group]}|#{@resource[:ip_protocol]}|#{@resource[:from_port]}|#{@resource[:to_port]}|#{@resource[:ip_range]}|#{@resource[:source_group]}'"
    security_rules = []
    nova('secgroup-list-rules', @resource[:security_group]).split("\n").each do |line|
      fields = line.split('|').map { |f| f.chomp.strip }
      next if fields.length < 2
      next if fields[1] == 'IP Protocol'
      rule = {
        :ip_protocol => fields[1],
        :from_port => fields[2],
        :to_port => fields[3],
        :ip_range => fields[4],
        :source_group => fields[5],
      }
      security_rules << rule
    end
    Puppet.debug "Found security rules in group '#{@resource[:security_group]}' #{security_rules.inspect}"
    out = if @resource[:source_group]
      !!security_rules.find do |rule|
        compare_keys rule, @resource, [:ip_protocol, :from_port, :to_port, :source_group]
      end
    else
      !!security_rules.find do |rule|
        compare_keys rule, @resource, [:ip_protocol, :from_port, :to_port, :ip_range]
      end
    end
    debug "Return: #{out}"
    out
  end

  def create
    if @resource[:source_group]
      nova 'secgroup-add-group-rule', @resource[:security_group], @resource[:source_group], @resource[:ip_protocol], @resource[:from_port], @resource[:to_port]
    else
      nova 'secgroup-add-rule', @resource[:security_group], @resource[:ip_protocol], @resource[:from_port], @resource[:to_port], @resource[:ip_range]
    end
  end

  def destroy
    if @resource[:source_group]
      nova 'secgroup-delete-group-rule', @resource[:security_group], @resource[:source_group], @resource[:ip_protocol], @resource[:from_port], @resource[:to_port]
    else
      nova 'secgroup-delete-rule', @resource[:security_group], @resource[:ip_protocol], @resource[:from_port], @resource[:to_port], @resource[:ip_range]
    end
  end
  
end