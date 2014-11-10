module Puppet
  newtype(:cs_resource) do
    desc 'Type for manipulating Corosync/Pacemaker primitives.  Primitives
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

      * http://www.clusterlabs.org/doc/en-US/Pacemaker/1.1/html/Clusters_from_Scratch/_adding_a_resource.html'

    ensurable

    newparam(:name) do
      desc "Name identifier of primitive.  This value needs to be unique
        across the entire Corosync/Pacemaker configuration since it doesn't have
        the concept of name spaces per type."
      isnamevar
    end

    newproperty(:primitive_class) do
      desc 'Corosync class of the primitive.  Examples of classes are lsb or ocf.
        Lsb funtions a lot like the init provider in Puppet for services, an init
        script is ran periodically on each host to identify status, or to start
        and stop a particular application.  Ocf of the other hand is a script with
        meta-data and stucture that is specific to Corosync and Pacemaker.'
      isrequired
    end

    newproperty(:primitive_type) do
      desc "Corosync primitive type.  Type generally matches to the specific
        'thing' your managing, i.e. ip address or vhost.  Though, they can be
        completely arbitarily named and manage any number of underlying
        applications or resources."
      isrequired
    end

    newproperty(:primitive_provider) do
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
      desc 'Corosync applies its configuration immediately. Using a CIB allows
        you to group multiple primitives and relationships to be applied at
        once. This can be necessary to insert complex configurations into
        Corosync correctly.

        This paramater sets the CIB this primitive should be created in. A
        cs_shadow resource with a title of the same name as this value should
        also be added to your manifest.'
    end

    # Our parameters and operations properties must be hashes.
    newproperty(:parameters) do
      desc 'A hash of params for the primitive.  Parameters in a primitive are
        used by the underlying resource agent, each class using them slightly
        differently.  In ocf scripts they are exported and pulled into the
        script as variables to be used.  Since the list of these parameters
        are completely arbitrary and validity not enforced we simply defer
        defining a model and just accept a hash.'

      validate do |value|
        unless value.is_a? Hash
          fail 'Parameters property must be a hash'
        end
      end

      def insync?(is)
        insync_debug is, should, 'parameters'
        super
      end

      munge do |value|
        stringify value
      end
    end

    newproperty(:operations, :array_matching => :all) do
      desc 'A hash of operations for the primitive.  Operations defined in a
        primitive are little more predictable as they are commonly things like
        monitor or start and their values are in seconds.  Since each resource
        agent can define its own set of operations we are going to defer again
        and just accept a hash. There maybe room to model this one but it
        would require a review of all resource agents to see if each operation
        is valid.'

      validate do |value|
        unless value.is_a? Hash
          fail 'Operations property must be a hash.'
        end
      end

      munge do |value|
        stringify value
      end

      def should=(value)
        super
        @should = munge_operations @should
      end

      def insync?(is)
        insync_debug is, should, 'operations'
        compare_operations is, should
      end
    end

    newproperty(:metadata) do
      desc "A hash of metadata for the primitive.  A primitive can have a set of
        metadata that doesn't affect the underlying Corosync type/provider but
        affect that concept of a resource.  This metadata is similar to Puppet's
        resources resource and some meta-parameters, they change resource
        behavior but have no affect of the data that is synced or manipulated."

      validate do |value|
        unless value.is_a? Hash
          fail 'Metadata property must be a hash'
        end
      end

      munge do |value|
        stringify value
      end

      def insync?(is)
        insync_debug is, should, 'metadata'
        compare_meta_attributes is, should
      end
    end

    newproperty(:complex_metadata) do
      desc 'A hash of metadata for the multistate state'

      validate do |value|
        unless value.is_a? Hash
          fail 'Complex_metadata property must be a hash'
        end
      end

      munge do |value|
        stringify value
      end

      def insync?(is)
        insync_debug is, should, 'complex_metadata'
        compare_meta_attributes is, should
      end
    end

    newproperty(:complex_type) do
      desc "Designates if the primitive is capable of being managed in a multistate
        state.  This will create a new ms or clone resource in your Corosync config and add
        this primitive to it.  Concequently Corosync will be helpful and update all
        your colocation and order resources too but Puppet won't. Hash contains
        two key-value pairs: type (master, clone) and its name (${type}_{$primitive_name})
        by default"
      newvalues 'clone', 'master'
    end

    autorequire(:cs_shadow) do
      [parameter(:cib).value] if parameter :cib
    end

    autorequire(:service) do
      ['corosync']
    end

    validate do
      if self[:complex_metadata] and not self[:complex_type]
        fail 'You should not use ms_metadata if your resource is not clone or master!' if self[:complex_metadata].any?
      end
    end

  end
end

# convert data structure to strings
def stringify(data)
  if data.is_a? Hash
    new_data = {}
    data.each do |key, value|
      new_data.store stringify(key), stringify(value)
    end
    data.clear
    data.merge! new_data
  elsif data.is_a? Array
    data.map! do |element|
      stringify element
    end
  else
    data.to_s
  end
end

# modify provided operations data
def munge_operations(operations_from)
  operations_from = [operations_from] unless operations_from.is_a? Array
  operations_to = []
  operations_from.each do |operation|
    if operation['name']
      operations_to << operation
      next
    end
    operation.each do |k, v|
      next unless v.is_a? Hash
      operation_structure = {}
      operation_structure['name'] = k
      operation_structure.merge! v
      operations_to << operation_structure if operation_structure.any?
    end
  end
  operations_to.each do |operation|
    operation['interval'] = '0' unless operation['interval']
    operation['role'].capitalize! if operation['role']
  end
  operations_to.sort_by do |operation|
    sort_order = [operation['name'], operation['interval'], operation['role']]
    sort_order.reject! { |c| c.nil? }
    sort_order.join '-'
  end
end

# compare meta_attribute hashes
# exclude status_metadata from comarsion
# @param is [Hash]
# @param should [Hash]
# @return [true,false]
def compare_meta_attributes(is, should)
  return unless is.is_a? Hash and should.is_a? Hash
  status_metadata = %w(target-role is-managed)
  is_without_state = is.reject do |k, v|
    status_metadata.include? k.to_s
  end
  should_without_state = should.reject do |k, v|
    status_metadata.include? k.to_s
  end
  is_without_state == should_without_state
end

# generate operation id for sorting
# @param operation [Hash]
# @return [String]
def operation_id(operation)
  id_components = [operation['name'], operation['role'], operation['interval']]
  id_components.reject! { |v| v.nil? }
  id_components.join '-'
end

# sort operations array before insync?
# to make different order and same data arrays equal
# TODO make operations sets
# @param is [Array]
# @param should [Array]
# @return [true,false]
def compare_operations(is, should)
  if is.is_a? Array and should.is_a? Array
    is = is.sort_by { |operation| operation_id operation }
    should = should.sort_by  { |operation| operation_id operation }
  end
  is == should
end

# output IS and SHOULD values for debugging
def insync_debug(is, should, tag = nil)
  debug "insync?: #{tag}" if tag
  debug "IS: #{is.inspect} #{is.class}"
  debug "SH: #{should.inspect} #{should.class}"
end
