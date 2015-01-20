require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'crmsh'

Puppet::Type.type(:cs_primitive).provide(:crm, :parent => Puppet::Provider::Crmsh) do
  desc 'Specific provider for a rather specific type since I currently have no
        plan to abstract corosync/pacemaker vs. keepalived.  Primitives in
        Corosync are the thing we desire to monitor; websites, ipaddresses,
        databases, etc, etc.  Here we manage the creation and deletion of
        these primitives.  We will accept a hash for what Corosync calls
        operations and parameters.  A hash is used instead of constucting a
        better model since these values can be almost anything.'

  # Path to the crm binary for interacting with the cluster configuration.
  commands :crm => 'crm'

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
      :primitive_class  => e.attributes['class'],
      :primitive_type   => e.attributes['type'],
      :provided_by      => e.attributes['provider'],
      :name             => e.attributes['id'].to_sym,
      :ensure           => :present,
      :provider         => self.name,
      :parameters       => nvpairs_to_hash(e.elements['instance_attributes']),
      :operations       => {},
      :utilization      => nvpairs_to_hash(e.elements['utilization']),
      :metadata         => nvpairs_to_hash(e.elements['meta_attributes']),
      :ms_metadata      => {},
      :promotable       => :false
    }

    if ! e.elements['operations'].nil?
      e.elements['operations'].each_element do |o|
        valids = o.attributes.reject do |k,v| k == 'id' end
        currentop = {}
        valids.each do |k,v|
          currentop[k] = v if k != 'name'
        end
        if ! o.elements['instance_attributes'].nil?
          o.elements['instance_attributes'].each_element do |i|
            currentop[(i.attributes['name'])] = i.attributes['value']
          end
        end
        if hash[:operations][valids['name']].instance_of?(Hash)
          # There is already an operation with the same name, change to Array
          hash[:operations][valids['name']] = [hash[:operations][valids['name']]]
        end
        if hash[:operations][valids['name']].instance_of?(Array)
          # Append to an existing list
          hash[:operations][valids['name']] += [currentop]
        else
          hash[:operations][valids['name']] = currentop
        end
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

    cmd = [ command(:crm), 'configure', 'show', 'xml' ]
    if Puppet::PUPPETVERSION.to_f < 3.4
      raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd)
    else
      raw = Puppet::Util::Execution.execute(cmd)
      status = raw.exitstatus
    end
    doc = REXML::Document.new(raw)

    REXML::XPath.each(doc, '//primitive') do |e|
      instances << new(element_to_hash(e))
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  def create
    @property_hash = {
      :name            => @resource[:name],
      :ensure          => :present,
      :primitive_class => @resource[:primitive_class],
      :provided_by     => @resource[:provided_by],
      :primitive_type  => @resource[:primitive_type],
      :promotable      => @resource[:promotable]
    }
    @property_hash[:parameters] = @resource[:parameters] if ! @resource[:parameters].nil?
    @property_hash[:operations] = @resource[:operations] if ! @resource[:operations].nil?
    @property_hash[:utilization] = @resource[:utilization] if ! @resource[:utilization].nil?
    @property_hash[:metadata] = @resource[:metadata] if ! @resource[:metadata].nil?
    @property_hash[:ms_metadata] = @resource[:ms_metadata] if ! @resource[:ms_metadata].nil?
    @property_hash[:cib] = @resource[:cib] if ! @resource[:cib].nil?
  end

  # Unlike create we actually immediately delete the item.  Corosync forces us
  # to "stop" the primitive before we are able to remove it.
  def destroy
    debug('Stopping primitive before removing it')
    crm('resource', 'stop', @resource[:name])
    debug('Revmoving primitive')
    crm('configure', 'delete', @resource[:name])
    @property_hash.clear
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
      crm('resource', 'stop', "ms_#{@resource[:name]}")
      crm('configure', 'delete', "ms_#{@resource[:name]}")
    end
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.  It generates a temporary file with
  # the updates that need to be made.  The temporary file is then used
  # as stdin for the crm command.  We have to do a bit of munging of our
  # operations and parameters hash to eventually flatten them into a string
  # that can be used by the crm command.
  def flush
    unless @property_hash.empty?
      unless @property_hash[:operations].empty?
        operations = ''
        @property_hash[:operations].each do |o|
          [o[1]].flatten.each do |o2|
            operations << "op #{o[0]} "
            o2.each_pair do |k,v|
              operations << "#{k}=#{v} "
            end
          end
        end
      end
      unless @property_hash[:parameters].empty?
        parameters = 'params '
        @property_hash[:parameters].each_pair do |k,v|
          parameters << "'#{k}=#{v}' "
        end
      end
      unless @property_hash[:utilization].empty?
        utilization = 'utilization '
        @property_hash[:utilization].each_pair do |k,v|
          utilization << "#{k}=#{v} "
        end
      end
      unless @property_hash[:metadata].empty?
        metadatas = 'meta '
        @property_hash[:metadata].each_pair do |k,v|
          metadatas << "#{k}=#{v} "
        end
      end
      updated = "primitive "
      updated << "#{@property_hash[:name]} #{@property_hash[:primitive_class]}:"
      updated << "#{@property_hash[:provided_by]}:" if @property_hash[:provided_by]
      updated << "#{@property_hash[:primitive_type]} "
      updated << "#{operations} " unless operations.nil?
      updated << "#{parameters} " unless parameters.nil?
      updated << "#{utilization} " unless utilization.nil?
      updated << "#{metadatas} " unless metadatas.nil?
      if @property_hash[:promotable] == :true
        updated << "\n"
        updated << "ms ms_#{@property_hash[:name]} #{@property_hash[:name]} "
        unless @property_hash[:ms_metadata].empty?
          updated << 'meta '
          @property_hash[:ms_metadata].each_pair do |k,v|
            updated << "#{k}=#{v} "
          end
        end
      end
      Tempfile.open('puppet_crm_update') do |tmpfile|
        tmpfile.write(updated)
        tmpfile.flush
        ENV['CIB_shadow'] = @resource[:cib]
        crm('configure', 'load', 'update', tmpfile.path.to_s)
      end
    end
  end
end
