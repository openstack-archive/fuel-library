require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'corosync'

Puppet::Type.type(:cs_colocation).provide(:crm, :parent => Puppet::Provider::Corosync) do
  desc 'Specific provider for a rather specific type since I currently have no plan to
        abstract corosync/pacemaker vs. keepalived.  This provider will check the state
        of current primitive colocations on the system; add, delete, or adjust various
        aspects.'

  # Path to the crm binary for interacting with the cluster configuration.
  # Decided to just go with relative.

  commands :cibadmin => 'cibadmin'
  commands :crm_shadow => 'crm_shadow'
  commands :crm => 'crm'
  commands :crm_diff => 'crm_diff'
  commands :crm_attribute => 'crm_attribute'

  def self.instances

    block_until_ready

    instances = []

    #cmd = [ command(:crm), 'configure', 'show', 'xml' ]
    raw, status = dump_cib
    doc = REXML::Document.new(raw)

    doc.root.elements['configuration'].elements['constraints'].each_element('rsc_colocation') do |e|
      items = e.attributes

      if items['rsc-role']
        rsc = "#{items['rsc']}:#{items['rsc-role']}"
      else
        rsc = items['rsc']
      end

      if items ['with-rsc-role']
        with_rsc = "#{items['with-rsc']}:#{items['with-rsc-role']}"
      else
        with_rsc = items['with-rsc']
      end

      colocation_instance = {
        :name       => items['id'],
        :ensure     => :present,
        :primitives => [rsc, with_rsc],
        :score      => items['score'],
        :provider   => self.name
      }
      instances << new(colocation_instance)
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  def create
    @property_hash = {
      :name       => @resource[:name],
      :ensure     => :present,
      :primitives => @resource[:primitives],
      :score      => @resource[:score],
      :cib        => @resource[:cib],
    }
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Revmoving colocation')
    crm('configure', 'delete', @resource[:name])
    @property_hash.clear
  end

  # Getter that obtains the primitives array for us that should have
  # been populated by prefetch or instances (depends on if your using
  # puppet resource or not).
  def primitives
    @property_hash[:primitives]
  end

  # Getter that obtains the our score that should have been populated by
  # prefetch or instances (depends on if your using puppet resource or not).
  def score
    @property_hash[:score]
  end

  # Our setters for the primitives array and score.  Setters are used when the
  # resource already exists so we just update the current value in the property
  # hash and doing this marks it to be flushed.
  def primitives=(should)
    @property_hash[:primitives] = should
  end

  def score=(should)
    @property_hash[:score] = should
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.  It generates a temporary file with
  # the updates that need to be made.  The temporary file is then used
  # as stdin for the crm command.
  def flush
    unless @property_hash.empty?
      self.class.block_until_ready
      updated = "colocation "
      updated << "#{@property_hash[:name]} #{@property_hash[:score]}: #{@property_hash[:primitives].join(' ')}"
      Tempfile.open('puppet_crm_update') do |tmpfile|
        tmpfile.write(updated.rstrip)
        tmpfile.flush
        apply_changes(@resource[:name],tmpfile,'colocation')
      end
    end
  end
end
