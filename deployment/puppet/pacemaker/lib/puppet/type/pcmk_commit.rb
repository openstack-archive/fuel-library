module Puppet
  newtype(:pcmk_commit) do
    desc %q(This type is an implementation detail. DO NOT use it directly)

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

    autorequire(:pcmk_location) do
      resources_with_cib :pcmk_location
    end

    autorequire(:pcmk_resource) do
      resources_with_cib :pcmk_resource
    end

    autorequire(:pcmk_property) do
      resources_with_cib :pcmk_property
    end

    autorequire(:pcmk_order) do
      resources_with_cib :pcmk_order
    end

    autorequire(:pcmk_colocation) do
      resources_with_cib :pcmk_colocation
    end

    autorequire(:pcmk_group) do
      resources_with_cib :pcmk_group
    end

    autorequire(:pcmk_shadow) do
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
