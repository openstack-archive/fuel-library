require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'corosync'

Puppet::Type.type(:cs_order).provide(:crm, :parent => Puppet::Provider::Corosync) do
  desc 'Specific provider for a rather specific type since I currently have no plan to
        abstract corosync/pacemaker vs. keepalived. This provider will check the state
        of current primitive start orders on the system; add, delete, or adjust various
        aspects.'

  # Path to the crm binary for interacting with the cluster configuration.

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

    doc.root.elements['configuration'].elements['constraints'].each_element('rsc_order') do |e|
      items = e.attributes

      if items['first-action']
        first = "#{items['first']}:#{items['first-action']}"
      else
        first = items['first']
      end

      if items['then-action']
        second = "#{items['then']}:#{items['then-action']}"
      else
        second = items['then']
      end

      order_instance = {
        :name       => items['id'],
        :ensure     => :present,
        :first      => first,
        :second     => second,
        :score      => items['score'],
        :provider   => self.name
      }
      instances << new(order_instance)
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  def create
    @property_hash = {
      :name       => @resource[:name],
      :ensure     => :present,
      :first      => @resource[:first],
      :second     => @resource[:second],
      :score      => @resource[:score],
      :cib        => @resource[:cib],
    }
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Revmoving order directive')
    crm('configure', 'delete', @resource[:name])
    @property_hash.clear
  end

  # Getters that obtains the first and second primitives and score in our
  # ordering definintion that have been populated by prefetch or instances
  # (depends on if your using puppet resource or not).
  def first
    @property_hash[:first]
  end

  def second
    @property_hash[:second]
  end

  def score
    @property_hash[:score]
  end

  # Our setters for the first and second primitives and score.  Setters are
  # used when the resource already exists so we just update the current value
  # in the property hash and doing this marks it to be flushed.
  def first=(should)
    @property_hash[:first] = should
  end

  def second=(should)
    @property_hash[:second] = should
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
      updated = 'order '
      updated << "#{@property_hash[:name]} #{@property_hash[:score]}: "
      updated << "#{@property_hash[:first]} #{@property_hash[:second]}"
      Tempfile.open('puppet_crm_update') do |tmpfile|
        tmpfile.write(updated.rstrip)
        tmpfile.flush
        apply_changes(@resource[:name],tmpfile,'order')
      end
    end
  end
end
