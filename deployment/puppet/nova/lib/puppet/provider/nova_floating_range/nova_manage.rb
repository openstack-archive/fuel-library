require 'openstack'
require 'netaddr'

Puppet::Type.type(:nova_floating_range).provide :nova_manage do
  desc 'Create nova floating range'

  commands :nova_manage => 'nova-manage'

  def exists?
    @resource[:ensure] = 'present' unless @resource[:ensure]

    if @resource[:ensure] == :absent
      operate_range.any?
    else
      operate_range.empty?
    end
  end

  def create
    mixed_range.each do |ip|
      connect.create_floating_ips_bulk :ip_range => ip, :pool => @resource[:pool]
    end
  end

  def destroy
    mixed_range.each do |ip|
      nova_manage("floating", "delete", ip )
    end
  end

  # Create range in cidr, including first and last ip
  # Nova will create this range, excluding network and broadcast IPs
  def mixed_range
    range = []
    NetAddr.merge(operate_range).each do |cidr|
      tmp_range = NetAddr::CIDR.create(cidr).enumerate
      range << tmp_range.first.to_s
      range << tmp_range.last.to_s
    end

    range.uniq!

    range += NetAddr.merge(operate_range).delete_if{ |part| part =~ /\/3[12]/}
  end

  # Calculate exist IP and current range
  def operate_range
    exist_range = []
    connect.get_floating_ips_bulk.each do |element|
      exist_range << element.address
    end
    if @resource[:ensure] == :absent
      ip_range & exist_range
    else
      ip_range - exist_range
    end
  end

  # Create array of IPs from range
  def ip_range
    ip = @resource[:name].split('-')
    ip_range = NetAddr.range NetAddr::CIDR.create(ip.first), NetAddr::CIDR.create(ip.last)
    ip_range.unshift(ip.first).push(ip.last)
  end

  # Connect to OpenStack
  def connect
    @connect ||= OpenStack::Connection.create :username => @resource[:username],
                                 :api_key => @resource[:api_key],
                                 :auth_method => @resource[:auth_method],
                                 :auth_url => @resource[:auth_url],
                                 :authtenant_name => @resource[:authtenant_name],
                                 :service_type => @resource[:service_type],
                                 :retries => @resource[:api_retries],
                                 :is_debug => Puppet[:debug]
  end
end
