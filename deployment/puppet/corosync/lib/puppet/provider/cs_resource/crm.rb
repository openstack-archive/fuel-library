require File.join File.dirname(__FILE__), '../corosync.rb'
require 'pp'

Puppet::Type.type(:cs_resource).provide(:crm, :parent => Puppet::Provider::Corosync) do
  desc 'Specific provider for a rather specific type since I currently have no
        plan to abstract corosync/pacemaker vs. keepalived.  Primitives in
        Corosync are the thing we desire to monitor; websites, ipaddresses,
        databases, etc, etc.  Here we manage the creation and deletion of
        these primitives.  We will accept a hash for what Corosync calls
        operations and parameters.  A hash is used instead of constucting a
        better model since these values can be almost anything.'

  commands :cibadmin => 'cibadmin'
  commands :crm_shadow => 'crm_shadow'
  commands :crm => 'crm'
  commands :pcs => 'pcs'
  commands :crm_diff => 'crm_diff'
  commands :crm_attribute => 'crm_attribute'

  # parse CIB XML and create the array of found primitives
  # @return [Array<Puppet::Provider::Crm>]
  def self.instances
    block_until_ready
    instances = []
    raw, status = dump_cib
    doc = REXML::Document.new(raw)

    REXML::XPath.each(doc, '//primitive') do |e|
      items = e.attributes

      primitive = {
        :ensure          => :present,
        :name            => items['id'].to_s,
        :primitive_class => items['class'].to_s,
        :primitive_type  => items['type'].to_s,
        :provided_by     => items['provider'].to_s,
      }

      primitive[:parameters]      = {}
      primitive[:operations]      = {}
      primitive[:metadata]        = {}
      primitive[:ms_metadata]     = {}

      if e.elements['instance_attributes']
        e.elements['instance_attributes'].each_element do |i|
          primitive[:parameters].store i.attributes['name'].to_s, i.attributes['value'].to_s
        end
      end

      if e.elements['meta_attributes']
        e.elements['meta_attributes'].each_element do |m|
          primitive[:metadata].store m.attributes['name'].to_s, m.attributes['value'].to_s
        end
      end

      if e.elements['operations']
        e.elements['operations'].each_element do |o|
          op_name = o.attributes['name'].to_s
          op_name += ":#{o.attributes['role']}" if o.attributes['role']
          primitive[:operations][op_name] = {}
          o.attributes.each do |k,v|
            next if k == 'name'
            next if k == 'id'
            primitive[:operations][op_name].store k.to_s, v.to_s
          end
        end
      end

      if e.parent.name == 'master' or e.parent.name == 'clone'
        primitive[:complex_type] = e.parent.name
        if e.parent.elements['meta_attributes']
          e.parent.elements['meta_attributes'].each_element do |m|
            primitive[:ms_metadata].store m.attributes['name'].to_s, m.attributes['value'].to_s
          end
        end
      end

      instances << new(primitive)
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  def create
    debug "Call: create on cs_resource '#{@resource[:name]}'"
    @property_hash = {
      :name            => @resource[:name],
      :ensure          => :present,
      :primitive_class => @resource[:primitive_class],
      :provided_by     => @resource[:provided_by],
      :primitive_type  => @resource[:primitive_type],
      :complex_type    => @resource[:complex_type],
    }
    @property_hash[:parameters]  = @resource[:parameters]  if @resource[:parameters]
    @property_hash[:operations]  = @resource[:operations]  if @resource[:operations]
    @property_hash[:metadata]    = @resource[:metadata]    if @resource[:metadata]
    @property_hash[:ms_metadata] = @resource[:ms_metadata] if @resource[:ms_metadata]
    @property_hash[:cib]         = @resource[:cib]         if @resource[:cib]
  end

  # Unlike create we actually immediately delete the item.  Corosync forces us
  # to "stop" the primitive before we are able to remove it.
  def destroy
    debug "Call: destroy on cs_resource '#{@resource[:name]}'"
    pcs 'resource', 'disable', @resource[:name]
    pcs 'resource', 'cleanup', @resource[:name]
    pcs 'resource', 'delete', @resource[:name]
  end

  # Getters that obtains the parameters and operations defined in our primitive
  # that have been populated by prefetch or instances (depends on if your using
  # puppet resource or not).
  def parameters
    @property_hash[:parameters]
  end

  def operations
    @property_hash[:operations]
  end

  def metadata
    @property_hash[:metadata]
  end

  def ms_metadata
    @property_hash[:ms_metadata]
  end

  def complex_type
    @property_hash[:complex_type]
  end

  # Our setters for parameters and operations.  Setters are used when the
  # resource already exists so we just update the current value in the
  # property_hash and doing this marks it to be flushed.
  def parameters=(should)
    Puppet.debug "Set paramemter:\n#{should.pretty_inspect}"
    @property_hash[:parameters] = should
  end

  def operations=(should)
    Puppet.debug "Set operations:\n#{should.pretty_inspect}"
    @property_hash[:operations] = should
  end

  def metadata=(should)
    Puppet.debug "Set metadata:\n#{should.pretty_inspect}"
    @property_hash[:metadata] = should
  end

  def ms_metadata=(should)
    Puppet.debug "Set ms_metadata:\n#{should.pretty_inspect}"
    @property_hash[:ms_metadata] = should
  end

  def complex_type=(should)
    Puppet.debug "Set complex_type:\n#{should.pretty_inspect}"

    # try to change complex_type of the existing primitive by deleting and recreating it later
    if should != @property_hash[:complex_type]
      self.destroy
    end

    @property_hash[:complex_type] = should
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.  It generates a temporary file with
  # the updates that need to be made.  The temporary file is then used
  # as stdin for the crm command.  We have to do a bit of munging of our
  # operations and parameters hash to eventually flatten them into a string
  # that can be used by the crm command.
  def flush
    debug "Call: flush on cs_resource '#{@resource[:name]}'"
    return if @property_hash.empty?
    self.class.block_until_ready

    unless @property_hash[:operations].empty?
      operations = ''
      @property_hash[:operations].each do |o|
        op_namerole = o[0].to_s.split(':')
        if op_namerole[1]
          o[1]['role'] = o[1]['role'] || op_namerole[1]  # Hash['role'] has more priority, than Name
        end
        operations << "op #{op_namerole[0]} "
        o[1].each_pair do |k,v|
          operations << "#{k}=#{v} "
        end
      end
    end

    unless @property_hash[:parameters].empty?
      parameters = 'params '
      @property_hash[:parameters].each_pair do |k,v|
        parameters << "#{k}=#{v} "
      end
    end

    unless @property_hash[:metadata].empty?
      metadatas = 'meta '
      @property_hash[:metadata].each_pair do |k,v|
        metadatas << "#{k}=#{v} "
      end
    end

    updated = 'primitive '
    updated << "#{@property_hash[:name]} #{@property_hash[:primitive_class]}:"
    updated << "#{@property_hash[:provided_by]}:" if @property_hash[:provided_by]
    updated << "#{@property_hash[:primitive_type]} "
    updated << "#{operations} " unless operations.nil?
    updated << "#{parameters} " unless parameters.nil?
    updated << "#{metadatas} "  unless metadatas.nil?

    if @property_hash[:complex_type]
      complex_name = "#{@property_hash[:complex_type]}_#{@property_hash[:name]}"
      crm_cmd_type = @property_hash[:complex_type].to_s == 'master' ? 'ms' : 'clone'
      debug "Creating '#{crm_cmd_type}' parent named '#{complex_name}' for #{@property_hash[:name]} resource"
      updated << "\n"
      updated << " #{crm_cmd_type} #{complex_name} #{@property_hash[:name]} "
      unless @property_hash[:ms_metadata].empty?
        updated << 'meta '
        @property_hash[:ms_metadata].each_pair do |k,v|
          updated << "#{k}=#{v} "
        end
      end
    end

    debug("Will update tmpfile with '#{updated}'")
    Tempfile.open('puppet_crm_update') do |tmpfile|
      tmpfile.write(updated)
      tmpfile.flush
      apply_changes(@resource[:name], tmpfile, 'resource')
    end
  end

end
