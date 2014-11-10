module Puppet
  newtype(:cs_commit) do
    desc 'This type is an implementation detail. DO NOT use it directly'

    newproperty(:cib) do
      def sync
        provider.sync(self.should)
      end

      def retrieve
        :absent
      end

      def insync?(is)
        false
      end

      defaultto { @resource[:name] }
    end

    newparam(:name) do
      isnamevar
    end

    autorequire(:service) do
      ['corosync']
    end

    autorequire(:cs_location) do
      resources_with_cib :cs_location
    end

    autorequire(:cs_resource) do
      resources_with_cib :cs_resource
    end

    autorequire(:cs_property) do
      resources_with_cib :cs_property
    end

    autorequire(:cs_order) do
      resources_with_cib :cs_order
    end

    autorequire(:cs_colocation) do
      resources_with_cib :cs_colocation
    end

    autorequire(:cs_group) do
      resources_with_cib :cs_group
    end

    autorequire(:cs_shadow) do
      [parameter(:cib).value] if parameter :cib
    end

    def resources_with_cib(cs_resource_type)
      cs_resource_names = []
      catalog.resources.each do |r|
        next unless r.is_a? Puppet::Type.type(cs_resource_type)
        cib_param = r.parameter(:cib)
        next unless cib_param.value == @parameters[:cib].value
        cs_resource_names << r.parameter(:name).value
      end
      cs_resource_names
    end

  end
end
