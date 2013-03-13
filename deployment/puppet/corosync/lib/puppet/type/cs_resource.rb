module Puppet
  newtype(:cs_resource) do
    @doc = "Type for manipulating Corosync/Pacemaker primitives.  Primitives
      are probably the most important building block when creating highly
      available clusters using Corosync and Pacemaker.  Each primitive defines
      an application, ip address, or similar to monitor and maintain.  These
      managed primitives are maintained using what is called a resource agent.
      These resource agents have a concept of class, type, and subsystem that
      provides the functionality.  Regretibly these pieces of vocabulary
      clash with those used in Puppet so to overcome the name clashing the
      property and parameter names have been qualified a bit for clarity.

      More information on primitive definitions can be found at the following
      link:

      * http://www.clusterlabs.org/doc/en-US/Pacemaker/1.1/html/Clusters_from_Scratch/_adding_a_resource.html"

    ensurable

    newparam(:name) do
      desc "Name identifier of primitive.  This value needs to be unique
        across the entire Corosync/Pacemaker configuration since it doesn't have
        the concept of name spaces per type."

      isnamevar
    end
    newparam(:primitive_class) do
      desc "Corosync class of the primitive.  Examples of classes are lsb or ocf.
        Lsb funtions a lot like the init provider in Puppet for services, an init
        script is ran periodically on each host to identify status, or to start
        and stop a particular application.  Ocf of the other hand is a script with
        meta-data and stucture that is specific to Corosync and Pacemaker."
      isrequired
    end
    newparam(:primitive_type) do
      desc "Corosync primitive type.  Type generally matches to the specific
        'thing' your managing, i.e. ip address or vhost.  Though, they can be
        completely arbitarily named and manage any number of underlying
        applications or resources."
      isrequired
    end
    newparam(:provided_by) do
      desc "Corosync primitive provider.  All resource agents used in a primitve
        have something that provides them to the system, be it the Pacemaker or
        redhat plugins...they're not always obvious though so currently you're
        left to understand Corosync enough to figure it out.  Usually, if it isn't
        obvious it is because there is only one provider for the resource agent.

        To find the list of providers for a resource agent run the following
        from the command line has Corosync installed:

        * `crm configure ra providers <ra> <class>`"
      isrequired
    end

    newparam(:cib) do
      desc "Corosync applies its configuration immediately. Using a CIB allows
        you to group multiple primitives and relationships to be applied at
        once. This can be necessary to insert complex configurations into
        Corosync correctly.

        This paramater sets the CIB this primitive should be created in. A
        cs_shadow resource with a title of the same name as this value should
        also be added to your manifest."
    end

    # Our parameters and operations properties must be hashes.
    newproperty(:parameters) do
      desc "A hash of params for the primitive.  Parameters in a primitive are
        used by the underlying resource agent, each class using them slightly
        differently.  In ocf scripts they are exported and pulled into the
        script as variables to be used.  Since the list of these parameters
        are completely arbitrary and validity not enforced we simply defer
        defining a model and just accept a hash."

      validate do |value|
        raise Puppet::Error, "Puppet::Type::Cs_Primitive: parameters property must be a hash." unless value.is_a? Hash
      end
      munge do |parameters|
        convert_to_sym(parameters)
      end
      defaultto Hash.new
    end
    newproperty(:operations) do
      desc "A hash of operations for the primitive.  Operations defined in a
        primitive are little more predictable as they are commonly things like
        monitor or start and their values are in seconds.  Since each resource
        agent can define its own set of operations we are going to defer again
        and just accept a hash.  There maybe room to model this one but it
        would require a review of all resource agents to see if each operation
        is valid."

      validate do |value|
        raise Puppet::Error, "Puppet::Type::Cs_Primitive: operations property must be a hash." unless value.is_a? Hash
      end
      munge do |operations|
        convert_to_sym(operations)
      end
      defaultto Hash.new
    end

    newproperty(:metadata) do
      desc "A hash of metadata for the primitive.  A primitive can have a set of
        metadata that doesn't affect the underlying Corosync type/provider but
        affect that concept of a resource.  This metadata is similar to Puppet's
        resources resource and some meta-parameters, they change resource
        behavior but have no affect of the data that is synced or manipulated."

      validate do |value|
        raise Puppet::Error, "Puppet::Type::Cs_Primitive: metadata property must be a hash." unless value.is_a? Hash
      end
      munge do |metadata|
        convert_to_sym(metadata)
      end
      defaultto Hash.new
    end

    newproperty(:ms_metadata) do
      desc "A hash of metadata for the multistate state."

      munge do |value_hash|
        value_hash.inject({}) do |memo,(key,value)|
          memo[key] = String(value)
          memo
        end
      end

      validate do |value|
        raise Puppet::Error, "Puppet::Type::Cs_Primitive: ms_metadata property must be a hash" unless value.is_a? Hash
      end

      defaultto Hash.new
    end

    newproperty(:multistate_hash) do
      desc "Designates if the primitive is capable of being managed in a multistate
        state.  This will create a new ms or clone resource in your Corosync config and add
        this primitive to it.  Concequently Corosync will be helpful and update all
        your colocation and order resources too but Puppet won't. Hash contains
        two key-value pairs: type (master, clone) and its name (${type}_{$primitive_name})
        by default"

      munge do |value_hash|
        munged_hash = value_hash.inject({}) do |memo,(key,value)|
          memo[key.to_sym] = String(value)
          memo
        end
        if munged_hash[:name].to_s.empty? and !munged_hash[:type].to_s.empty?
          munged_hash[:name] = "#{munged_hash[:type]}_#{@resource[:name]}"
        end
        munged_hash
      end

      validate do |value|
        raise Puppet::Error, "Puppet::Type::Cs_Resource: multistate_hash property must be a hash" unless
        value.is_a? Hash

        raise Puppet::Error, "Puppet::Type::Cs_Resource: multistate_hash type property #{value[:type]} must be in master|clone|'' if set" unless
        ["master", "clone", ""].include?(value[:type]) or value[:type] == nil

      end
      defaultto Hash.new

    end

    autorequire(:cs_shadow) do
      autos = []
      if @parameters[:cib]
        Puppet.debug("#{@parameters[:cib].value}")
        autos << @parameters[:cib].value
      end

      autos
    end

    autorequire(:service) do
      [ 'corosync' ]
    end
  end
end

def convert_to_sym(hash)
  if hash.is_a? Hash
    hash.inject({}) do |memo,(key,value)|
      value = convert_to_sym(value)
      if value.is_a?(Array)
        value.collect! do |arr_el|
          convert_to_sym(arr_el)
        end
      end
      memo[key.to_sym] = value
      memo
    end
  else
    hash
  end
end
