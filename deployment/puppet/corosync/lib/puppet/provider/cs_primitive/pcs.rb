require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'pacemaker'

Puppet::Type.type(:cs_primitive).provide(:pcs, :parent => Puppet::Provider::Pacemaker) do
  desc 'Specific provider for a rather specific type since I currently have no
        plan to abstract corosync/pacemaker vs. keepalived.  Primitives in
        Corosync are the thing we desire to monitor; websites, ipaddresses,
        databases, etc, etc.  Here we manage the creation and deletion of
        these primitives.  We will accept a hash for what Corosync calls
        operations and parameters.  A hash is used instead of constucting a
        better model since these values can be almost anything.'

  commands :pcs => 'pcs'

  defaultfor :operatingsystem => [:fedora, :centos, :redhat]
  # given an XML element containing some <nvpair>s, return a hash. Return an
  # empty hash if `e` is nil.
  def self.nvpairs_to_hash(e)
    return {} if e.nil?

    hash = {}
    e.each_element do |i|
      hash[(i.attributes['name'])] = i.attributes['value']
    end

    hash
  end

  # given an XML element (a <primitive> from cibadmin), produce a hash suitible
  # for creating a new provider instance.
  def self.element_to_hash(e)
    hash = {
      :primitive_class          => e.attributes['class'],
      :primitive_type           => e.attributes['type'],
      :provided_by              => e.attributes['provider'],
      :name                     => e.attributes['id'].to_sym,
      :ensure                   => :present,
      :provider                 => self.name,
      :parameters               => nvpairs_to_hash(e.elements['instance_attributes']),
      :operations               => {},
      :utilization              => nvpairs_to_hash(e.elements['utilization']),
      :metadata                 => nvpairs_to_hash(e.elements['meta_attributes']),
      :ms_metadata              => {},
      :promotable               => :false,
      :existing_resource        => :true,
      :existing_primitive_class => e.attributes['class'],
      :existing_primitive_type  => e.attributes['type'],
      :existing_provided_by     => e.attributes['provider'],
      :existing_operations      => {}
    }

    if ! e.elements['operations'].nil?
      e.elements['operations'].each_element do |o|
        valids = o.attributes.reject do |k,v| k == 'id' end
        if ! valids['role'].nil?
          name = valids['name']
          name << ":"
          name << valids['role']
        else
          name = valids['name']
        end
        hash[:operations][name] = {}
        valids.each do |k,v|
          hash[:operations][name][k] = v if k != 'name' and k != 'role'
        end
        hash[:existing_operations] = hash[:operations].dup
      end
    end
    if e.parent.name == 'master'
      hash[:promotable] = :true
      if ! e.parent.elements['meta_attributes'].nil?
        e.parent.elements['meta_attributes'].each_element do |m|
          hash[:ms_metadata][(m.attributes['name'])] = m.attributes['value']
        end
      end
    end

    hash
  end

  def self.instances

    block_until_ready

    instances = []

    cmd = [ command(:pcs), 'cluster', 'cib' ]
    raw, status = run_pcs_command(cmd)
    doc = REXML::Document.new(raw)

    REXML::XPath.each(doc, '//primitive') do |e|
      instances << new(element_to_hash(e))
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  # The existing_resource is there because pcs does not have a single command that
  # updates or create a resource, so we flag the resources with that parameter
  def create
    @property_hash = {
      :name              => @resource[:name],
      :ensure            => :present,
      :primitive_class   => @resource[:primitive_class],
      :provided_by       => @resource[:provided_by],
      :primitive_type    => @resource[:primitive_type],
      :promotable        => @resource[:promotable],
      :existing_resource => :false
    }
    @property_hash[:parameters] = @resource[:parameters] if ! @resource[:parameters].nil?
    @property_hash[:operations] = @resource[:operations] if ! @resource[:operations].nil?
    @property_hash[:utilization] = @resource[:utilization] if ! @resource[:utilization].nil?
    @property_hash[:metadata] = @resource[:metadata] if ! @resource[:metadata].nil?
    @property_hash[:ms_metadata] = @resource[:ms_metadata] if ! @resource[:ms_metadata].nil?
    @property_hash[:cib] = @resource[:cib] if ! @resource[:cib].nil?
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Removing primitive')
    Puppet::Provider::Pacemaker::run_pcs_command([command(:pcs), 'resource', 'delete', @property_hash[:name]])
    @property_hash.clear
  end

  # Getters that obtains the parameters and operations defined in our primitive
  # that have been populated by prefetch or instances (depends on if your using
  # puppet resource or not).
  def parameters
    @property_hash[:parameters]
  end

  def primitive_class
    @property_hash[:primitive_class]
  end

  def provided_by
    @property_hash[:provided_by]
  end

  def primitive_type
    @property_hash[:primitive_type]
  end

  def operations
    @property_hash[:operations]
  end

  def utilization
    @property_hash[:utilization]
  end

  def metadata
    @property_hash[:metadata]
  end

  def ms_metadata
    @property_hash[:ms_metadata]
  end

  def promotable
    @property_hash[:promotable]
  end

  # Our setters for parameters and operations.  Setters are used when the
  # resource already exists so we just update the current value in the
  # property_hash and doing this marks it to be flushed.
  def parameters=(should)
    @property_hash[:parameters] = should
  end

  def primitive_class=(should)
    @property_hash[:primitive_class] = should
  end

  def provided_by=(should)
    @property_hash[:provided_by] = should
  end

  def primitive_type=(should)
    @property_hash[:primitive_type] = should
  end
  def operations=(should)
    @property_hash[:operations] = should
  end

  def utilization=(should)
    @property_hash[:utilization] = should
  end

  def metadata=(should)
    @property_hash[:metadata] = should
  end

  def ms_metadata=(should)
    @property_hash[:ms_metadata] = should
  end

  def promotable=(should)
    case should
    when :true
      @property_hash[:promotable] = should
    when :false
      @property_hash[:promotable] = should
      pcs('resource', 'delete', "ms_#{@resource[:name]}")
    end
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.
  # It calls several pcs commands to make the resource look like the
  # params.
  def flush
    unless @property_hash.empty?
      # The ressource_type variable is used to check if one of the class,
      # provider or type has changed
      ressource_type = "#{@property_hash[:primitive_class]}:"
      if @property_hash[:provided_by]
        ressource_type << "#{@property_hash[:provided_by]}:"
      end
      ressource_type << "#{@property_hash[:primitive_type]}"

      unless @property_hash[:operations].empty?
        operations = []
        @property_hash[:operations].each do |o|
          op_name = o[0]
          operations << "op"
          if op_name.include? ':'
            items = op_name.split(':')
            operations << items[0]
            operations << "role=#{items[1]}"
          else
            operations << op_name
          end
          o[1].each_pair do |k,v|
            operations << "#{k}=#{v}"
          end
        end
      end
      unless @property_hash[:parameters].empty?
        parameters = []
        @property_hash[:parameters].each_pair do |k,v|
          parameters << "'#{k}=#{v}'"
        end
      end
      unless @property_hash[:utilization].empty?
        utilization = [ 'utilization' ]
        @property_hash[:utilization].each_pair do |k,v|
          utilization << "#{k}=#{v}"
        end
      end
      unless @property_hash[:metadata].empty?
        metadatas = [ 'meta' ]
        @property_hash[:metadata].each_pair do |k,v|
          metadatas << "#{k}=#{v}"
        end
      end

      # We destroy the ressource if it's type, class or provider has changed
      unless @property_hash[:existing_resource] == :false
        existing_ressource_type = "#{@property_hash[:existing_primitive_class]}:"
        existing_ressource_type << "#{@property_hash[:existing_provided_by]}:" if @property_hash[:existing_provided_by]
        existing_ressource_type << "#{@property_hash[:existing_primitive_type]}"
        if existing_ressource_type != ressource_type
          debug('Removing primitive')
          Puppet::Provider::Pacemaker::run_pcs_command([command(:pcs), 'resource', 'delete', @property_hash[:name]])
          force_reinstall = :true
        end
      end

      ENV['CIB_shadow'] = @property_hash[:cib]

      if @property_hash[:existing_resource] == :false or force_reinstall == :true
        cmd = [ command(:pcs), 'resource', 'create', "#{@property_hash[:name]}" ]
        cmd << ressource_type
        cmd += parameters unless parameters.nil?
        cmd += operations unless operations.nil?
        cmd += utilization unless utilization.nil?
        cmd += metadatas unless metadatas.nil?
        raw, status = Puppet::Provider::Pacemaker::run_pcs_command(cmd)
        # if we are using a master/slave resource, prepend ms_ before its name
        # and declare it as a master/slave resource
        if @property_hash[:promotable] == :true
          cmd = [ command(:pcs), 'resource', 'master', "ms_#{@property_hash[:name]}", "#{@property_hash[:name]}" ]
          unless @property_hash[:ms_metadata].empty?
            cmd << 'meta'
            @property_hash[:ms_metadata].each_pair do |k,v|
              cmd << "#{k}=#{v}"
            end
          end
          raw, status = Puppet::Provider::Pacemaker::run_pcs_command(cmd)
        end
        # try to remove the default monitor operation
        if @property_hash[:operations]["monitor"].nil?
          cmd = [ command(:pcs), 'resource', 'op', 'remove', "#{@property_hash[:name]}", 'monitor', 'interval=60s' ]
          Puppet::Provider::Pacemaker::run_pcs_command(cmd, false)
        end
      else
        # if there is no operations defined, we ensure that they are not present
        if @property_hash[:operations].empty? and not @property_hash[:existing_operations].empty?
          @property_hash[:existing_operations].each do |o|
            cmd = [ command(:pcs), 'resource', 'op', 'remove', "#{@property_hash[:name]}" ]
            cmd << "#{o[0]}"
            o[1].each_pair do |k,v|
              cmd << "#{k}=#{v}"
            end
            Puppet::Provider::Pacemaker::run_pcs_command(cmd)
          end
        end
        cmd = [ command(:pcs), 'resource', 'update', "#{@property_hash[:name]}" ]
        cmd += parameters unless parameters.nil?
        cmd += operations unless operations.nil?
        cmd += utilization unless utilization.nil?
        cmd += metadatas unless metadatas.nil?
        raw, status = Puppet::Provider::Pacemaker::run_pcs_command(cmd)
        if @property_hash[:promotable] == :true
          cmd = [ command(:pcs), 'resource', 'update', "ms_#{@property_hash[:name]}", "#{@property_hash[:name]}" ]
          unless @property_hash[:ms_metadata].empty?
            cmd << 'meta'
            @property_hash[:ms_metadata].each_pair do |k,v|
              cmd << "#{k}=#{v}"
            end
          end
          raw, status = Puppet::Provider::Pacemaker::run_pcs_command(cmd)
        end
      end
    end
  end
end
