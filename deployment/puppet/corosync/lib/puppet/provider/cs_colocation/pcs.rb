require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'pacemaker'

Puppet::Type.type(:cs_colocation).provide(:pcs, :parent => Puppet::Provider::Pacemaker) do
  desc 'Specific provider for a rather specific type since I currently have no plan to
        abstract corosync/pacemaker vs. keepalived.  This provider will check the state
        of current primitive colocations on the system; add, delete, or adjust various
        aspects.'

  defaultfor :operatingsystem => [:fedora, :centos, :redhat]

  # Path to the crm binary for interacting with the cluster configuration.
  # Decided to just go with relative.
  commands :pcs => 'pcs'

  def self.instances

    block_until_ready

    instances = []

    cmd = [ command(:pcs), 'cluster', 'cib' ]
    raw, status = run_pcs_command(cmd)
    doc = REXML::Document.new(raw)

    doc.root.elements['configuration'].elements['constraints'].each_element('rsc_colocation') do |e|
      items = e.attributes

      if items['rsc-role'] and items['rsc-role'] != "Started"
        rsc = "#{items['rsc']}:#{items['rsc-role']}"
      else
        rsc = items['rsc']
      end

      if items ['with-rsc-role'] and items['with-rsc-role'] != "Started"
        with_rsc = "#{items['with-rsc']}:#{items['with-rsc-role']}"
      else
        with_rsc = items['with-rsc']
      end

      # Sorting the array of primitives because order doesn't matter so someone
      # switching the order around shouldn't generate an event.
      colocation_instance = {
        :name       => items['id'],
        :ensure     => :present,
        :primitives => [rsc, with_rsc].sort,
        :score      => items['score'],
        :provider   => self.name,
        :new        => false
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
      :new        => true
    }
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Removing colocation')
    cmd=[ command(:pcs), 'constraint', 'remove', @resource[:name]]
    Puppet::Provider::Pacemaker::run_pcs_command(cmd)
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
    @property_hash[:primitives] = should.sort
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
        debug('Removing colocation')
        cmd=[ command(:pcs), 'constraint', 'remove', @resource[:name]]
        Puppet::Provider::Pacemaker::run_pcs_command(cmd)
      end

      cmd = [ command(:pcs), 'constraint', 'colocation' ]
      cmd << "add"
      rsc = @property_hash[:primitives].pop
      if rsc.include? ':'
        items = rsc.split[':']
        if items[1] == 'Master'
          cmd << 'master'
        elsif items[1] == 'Slave'
          cmd << 'slave'
        end
        cmd << items[0]
      else
        cmd << rsc
      end
      cmd << 'with'
      rsc = @property_hash[:primitives].pop
      if rsc.include? ':'
        items = rsc.split(':')
        if items[1] == 'Master'
          cmd << 'master'
        elsif items[1] == 'Slave'
          cmd << 'slave'
        end
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
