Puppet::Type.newtype(:heat_domain_id_setter) do

    ensurable

    newparam(:name, :namevar => true) do
        desc 'The name of the setting to update'
    end

    newparam(:domain_name) do
        desc 'The heat domain name'
    end

    newparam(:auth_url) do
        desc 'The Keystone endpoint URL'
        defaultto 'http://localhost:35357/v2.0'
    end

    newparam(:auth_username) do
        desc 'Username with which to authenticate'
        defaultto 'admin'
    end

    newparam(:auth_password) do
        desc 'Password with which to authenticate'
    end

    newparam(:auth_tenant_name) do
        desc 'Tenant name with which to authenticate'
        defaultto 'admin'
    end
end
