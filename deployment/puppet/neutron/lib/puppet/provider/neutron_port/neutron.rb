require File.join(File.dirname(__FILE__), "..","..","..",
                  "puppet/provider/neutron")

Puppet::Type.type(:neutron_port).provide(
  :neutron,
  :parent => Puppet::Provider::Neutron
) do
  desc <<-EOT
    Neutron provider to manage neutron_port type.

    Assumes that the neutron service is configured on the same host.
  EOT
  #TODO No security group support

  commands :neutron => "neutron"

  mk_resource_methods

  def self.instances
    list_neutron_resources("port").collect do |id|
      attrs = get_neutron_resource_attrs("port", id)
      attrs["name"] = attrs["id"] if attrs["name"].empty?
      new(
        :ensure         => :present,
        :name           => attrs["name"],
        :id             => attrs["id"],
        :status         => attrs["status"],
        :tenant_id      => attrs["tenant_id"],
        :network_id     => attrs["network_id"],
        :admin_state_up => attrs["admin_state_up"],
        :network_name   => get_network_name(attrs["network_id"]),
        :subnet_name    => get_subnet_name(parse_subnet_id(attrs["fixed_ips"])),
        :subnet_id      => parse_subnet_id(attrs["fixed_ips"]),
        :ip_address     => parse_ip_address(attrs["fixed_ips"])
      )
    end
  end

  def self.prefetch(resources)
    instances_ = instances
    resources.keys.each do |name|
      if provider = instances_.find{ |instance| instance.name == name }
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    opts = Array.new

    if @resource[:admin_state_up] == "False"
      opts << "--admin-state-down"
    end

    if @resource[:ip_address]
      # The spec says that multiple ip addresses may be specified, but this
      # doesn't seem to work yet.
      opts << "--fixed-ip"
      opts << @resource[:ip_address].map{|ip|"ip_address=#{ip}"}.join(',')
    end

    if @resource[:subnet_name]
      # The spec says that multiple subnets may be specified, but this doesn't
      # seem to work yet.
      opts << "--fixed-ip"
      opts << @resource[:subnet_name].map{|s|"subnet_id=#{s}"}.join(',')
    end

    if @resource[:tenant_name]
      tenant_id = self.class.get_tenant_id(
        model.catalog,
        @resource[:tenant_name]
      )
      opts << "--tenant_id=#{tenant_id}"
    elsif @resource[:tenant_id]
      opts << "--tenant_id=#{@resource[:tenant_id]}"
    end

    results = auth_neutron(
      "port-create",
      "--format=shell",
      "--name=#{resource[:name]}",
      opts,
      resource[:network_name]
    )

    if results =~ /Created a new port:/
      attrs = self.class.parse_creation_output(results)
      @property_hash = {
        :ensure         => :present,
        :name           => resource[:name],
        :id             => attrs["id"],
        :status         => attrs["status"],
        :tenant_id      => attrs["tenant_id"],
        :network_id     => attrs["network_id"],
        :admin_state_up => attrs["admin_state_up"],
        :network_name   => resource[:network_name],
        :subnet_name    => resource[:subnet_name],
        :subnet_id      => self.class.parse_subnet_id(attrs["fixed_ips"]),
        :ip_address     => self.class.parse_ip_address(attrs["fixed_ips"])
      }
    else
      fail("did not get expected message on port creation, got #{results}")
    end
  end

  def destroy
    auth_neutron("port-delete", name)
    @property_hash[:ensure] = :absent
  end

  def admin_state_up=(value)
    auth_neutron("port-update", "--admin-state-up=#{value}", name)
  end

  private

  def self.get_network_name(network_id_)
    if network_id_
      network_instances = Puppet::Type.type("neutron_network").instances
      network_name = network_instances.find do |instance|
        instance.provider.id == network_id_
      end.provider.name
    end
    network_name
  end

  def get_network_name(network_id_)
    @get_network_name ||= self.class.get_network_name(network_id_)
  end

  def self.get_subnet_name(subnet_id_)
    if subnet_id_
      subnet_ids = Array(subnet_id_)
      subnet_instances = Puppet::Type.type("neutron_subnet").instances
      subnet_names = subnet_instances.collect do |instance|
        if subnet_ids.include?(instance.provider.id)
          instance.provider.name
        else
          nil
        end
      end.compact
      if subnet_names.length > 1
        subnet_names
      else
        subnet_names.first
      end
    end
  end

  def get_subnet_name(subnet_id_)
    @subnet_name ||= self.class.subnet_name(subnet_id_)
  end

  def self.parse_subnet_id(fixed_ips_)
    subnet_ids = Array(fixed_ips_).collect do |json|
      match_data = /\{"subnet_id": "(.*)", /.match(json)
      if match_data
        match_data[1]
      else
        nil
      end
    end.compact
    if subnet_ids.length > 1
      subnet_ids
    else
      subnet_ids.first
    end
  end

  def self.parse_ip_address(fixed_ips_)
    ip_addresses = Array(fixed_ips_).collect do |json|
      match_data = /"ip_address": "(.*)"\}/.match(json)
      if match_data
        match_data[1]
      else
        nil
      end
    end.compact
    if ip_addresses.length > 1
      ip_addresses
    else
      ip_addresses.first
    end
  end

end
