require 'pathname' # JJM WORK_AROUND #14073
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'pacemaker'

Puppet::Type.type(:cs_property).provide(:pcs, :parent => Puppet::Provider::Pacemaker) do
  desc 'Specific provider for a rather specific type since I currently have no plan to
        abstract corosync/pacemaker vs. keepalived. This provider will check the state
        of Corosync cluster configuration properties.'

  defaultfor :operatingsystem => [:fedora, :centos, :redhat]

  # Path to the crm binary for interacting with the cluster configuration.
  commands :pcs           => 'pcs'

  def self.instances

    block_until_ready

    instances = []

    cmd = [ command(:pcs), 'cluster', 'cib' ]
    raw, status = run_pcs_command(cmd)
    doc = REXML::Document.new(raw)

    doc.root.elements['configuration/crm_config/cluster_property_set'].each_element do |e|
      items = e.attributes
      property = { :name => items['name'], :value => items['value'] }

      property_instance = {
        :name       => property[:name],
        :ensure     => :present,
        :value      => property[:value],
        :provider   => self.name
      }
      instances << new(property_instance)
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  def create
    @property_hash = {
      :name   => @resource[:name],
      :ensure => :present,
      :value  => @resource[:value],
    }
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Removing cluster property')
    cmd = [ command(:pcs), 'property', 'unset', "#{@property_hash[:name]}" ]
    raw, status = run_pcs_command(cmd)
    @property_hash.clear
  end

  # Getters that obtains the first and second primitives and score in our
  # ordering definintion that have been populated by prefetch or instances
  # (depends on if your using puppet resource or not).
  def value
    @property_hash[:value]
  end

  # Our setters for the first and second primitives and score.  Setters are
  # used when the resource already exists so we just update the current value
  # in the property hash and doing this marks it to be flushed.
  def value=(should)
    @property_hash[:value] = should
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.  It generates a temporary file with
  # the updates that need to be made.  The temporary file is then used
  # as stdin for the pcs command.
  def flush
    unless @property_hash.empty?
      # clear this on properties, in case it's set from a previous
      # run of a different corosync type
      ENV['CIB_shadow'] = nil
      cmd = [ command(:pcs), 'property', 'set', "#{@property_hash[:name]}=#{@property_hash[:value]}" ]
      raw, status = Puppet::Provider::Pacemaker::run_pcs_command(cmd)
    end
  end
end
