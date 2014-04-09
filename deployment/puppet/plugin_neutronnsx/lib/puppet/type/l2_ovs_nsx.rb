Puppet::Type.newtype(:l2_ovs_nsx) do
    @doc = "Manage a Open vSwitch connection NSX control plane"
    desc @doc

    ensurable

    newparam(:nsx_username) do
    end

    newparam(:nsx_password) do
    end

    newparam(:nsx_endpoint) do
    end

    newparam(:display_name, :namevar => true) do
    end

    newparam(:transport_zone_uuid) do
    end

    newparam(:ip_address) do
    end

    newparam(:connector_type) do
    end

    newparam(:integration_bridge) do
    end
end
