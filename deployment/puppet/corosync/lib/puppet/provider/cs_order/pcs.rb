require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'pacemaker'

Puppet::Type.type(:cs_order).provide(:pcs, :parent => Puppet::Provider::Pacemaker) do
  desc 'Specific provider for a rather specific type since I currently have no plan to
        abstract corosync/pacemaker vs. keepalived. This provider will check the state
        of current primitive start orders on the system; add, delete, or adjust various
        aspects.'

  defaultfor :operatingsystem => [:fedora, :centos, :redhat]

  # Path to the crm binary for interacting with the cluster configuration.
  commands :pcs => 'pcs'

  def self.instances

    block_until_ready

    instances = []

    cmd = [ command(:pcs), 'cluster', 'cib' ]
    raw, status = run_pcs_command(cmd)
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
      if items['score']
        score = items['score']
      else
        score = 'INFINITY'
      end

      order_instance = {
        :name       => items['id'],
        :ensure     => :present,
        :first      => first,
        :second     => second,
        :score      => score,
        :provider   => self.name,
        :new        => false
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
      :new        => true,
    }
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Removing order directive')
    cmd=[ command(:pcs), 'constraint', 'remove', @resource[:name]]
    Puppet::Provider::Pacemaker::run_pcs_command(cmd)
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
  # as stdin for the pcs command.
  def flush
    unless @property_hash.empty?
      if @property_hash[:new] == false
        debug('Removing order directive')
        cmd=[ command(:pcs), 'constraint', 'remove', @resource[:name]]
        Puppet::Provider::Pacemaker::run_pcs_command(cmd)
      end

      cmd = [ command(:pcs), 'constraint', 'order' ]
      rsc = @property_hash[:first]
      if rsc.include? ':'
        items = rsc.split(':')
        cmd << items[1]
        cmd << items[0]
      else
        cmd << rsc
      end
      cmd << 'then'
      rsc = @property_hash[:second]
      if rsc.include? ':'
        items = rsc.split(':')
        cmd << items[1]
        cmd << items[0]
      else
        cmd << rsc
      end
      cmd << @property_hash[:score]
      cmd << "id=#{@property_hash[:name]}"
      raw, status = Puppet::Provider::Pacemaker::run_pcs_command(cmd)
    end
  end
end
