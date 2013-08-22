module Puppet
  newtype(:cs_fencetopo) do
    @doc = "Type for manipulating corosync/pacemaker configuration for fencing topology.
      More information on fencing topologies can be found here:
      * http://clusterlabs.org/wiki/Fencing_topology
      "

    ensurable

    newparam(:name) do
      desc "Fencing topology name reference."

      isnamevar
    end

    newparam(:cib) do
      desc "Corosync applies its configuration immediately. Using a CIB allows
            you to group multiple primitives and relationships to be applied at
            once. This can be necessary to insert complex configurations into
            Corosync correctly.

            This paramater sets the CIB this order should be created in. A
            cs_shadow resource with a title of the same name as this value should
            also be added to your manifest."
    end

    newproperty(:nodes, :array_matching=>:all) do
      desc "An array with cluster nodes' fqdns"
      isrequired
    end

    newproperty(:fence_topology) do
      desc "A hash with predefined fence topology."
      isrequired
      validate do |fence_topology|
        raise Puppet::Error, "Puppet::Type::Cs_FenceTopo: fencing topology entries must be a hashes." unless fence_topology.is_a? Hash
      end
      defaultto Hash.new
    end

    autorequire(:service) do
      [ 'corosync' ]
    end

    autorequire(:cs_shadow) do
      autos = []
      if @parameters[:cib]
        autos << @parameters[:cib].value
      end

      autos
    end

  end
end
