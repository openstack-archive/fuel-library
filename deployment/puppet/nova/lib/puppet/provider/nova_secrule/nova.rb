require File.join File.dirname(__FILE__), '../nova_common.rb'

Puppet::Type.type(:nova_secrule).provide(:nova, :parent => Puppet::Provider::Nova_common) do
  desc "Manage security rules in nova"

  commands :nova => 'nova'

  def secgroup_name
    @resource[:security_group]
  end

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
    rules.each do |newrule|
      rule = {
        :ip_protocol => newrule[:ip_protocol],
        :from_port => newrule[:from_port],
        :to_port => newrule[:to_port],
        :ip_range => newrule[:ip_range][:cidr],
        :source_group => newrule[:group][:name],
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
      source_group = false
      connection.security_groups.each do |uuid, group|
        source_group = group if group[:name] == @resource[:source_group]
        break unless !source_group
      end
      params = {
       :ip_protocol => @resource[:ip_protocol],
       :from_port => @resource[:from_port],
       :to_port => @resource[:to_port],
       :group_id => source_group[:id],
      }
    else
      params = {
       :ip_protocol => @resource[:ip_protocol],
       :from_port => @resource[:from_port],
       :to_port => @resource[:to_port],
       :cidr => @resource[:ip_range],
      }
    end
    connection.create_security_group_rule secgroup[:id], params
  end

  def destroy
    id = ''
    security_rules = []
    rules.each do |newrule|
      rule = {
        :ip_protocol => newrule[:ip_protocol],
        :from_port => newrule[:from_port],
        :to_port => newrule[:to_port],
        :ip_range => newrule[:ip_range][:cidr],
        :source_group => newrule[:group][:name],
        :id => newrule[:id],
      }
      security_rules << rule
    end
    if @resource[:source_group]
      security_rules.each do |rule|
        if compare_keys rule, @resource, [:ip_protocol, :from_port, :to_port, :source_group]
          id = rule[:id]
          break
        end
      end
    else
      security_rules.each do |rule|
        if compare_keys rule, @resource, [:ip_protocol, :from_port, :to_port, :ip_range]
          id = rule[:id]
          break
        end
      end
    end
    connection.delete_security_group_rule id
  end
  
end
