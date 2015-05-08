module Puppet
  newtype(:pcmk_nodes) do
    desc %q(Add and remove cluster nodes)

    newparam(:name) do
      isnamevar
    end

    newparam(:debug) do
      desc %q(Don't actually make changes)
      defaultto false
    end

    newparam(:nodes) do
      desc <<-eos
Nodes data structure:
{
  'node-1' => { 'id' => '1', 'ip' => '192.168.0.1'},
  'node-2' => { 'id' => '2', 'ip' => '192.168.0.2'},
}
      eos
      validate do |value|
        unless value.is_a? Hash and value.any?
          fail 'Nodes should be a non-empty hash!'
        end
      end
    end

    newproperty(:corosync_nodes) do
      desc <<-eos
Corosync_nodes data structure:
{
# 'id' => 'ip',
  '1'  => '192.168.0.1',
  '2'  => '192.168.0.2',
}
      eos
      defaultto { @resource.set_corosync_nodes }

      def insync?(is)
        is == should
      end

      def is_to_s(is)
        is.inspect
      end

      def should_to_s(should)
        should.inspect
      end
    end

    newproperty(:pacemaker_nodes) do
      desc <<-eos
Pacemaker_nodes data structure:
{
# 'name'    => 'id',
  'node-1'  => '1',
  'node-2'  => '2',
}
      eos
      defaultto { @resource.set_pacemaker_nodes }

      def insync?(is)
        is == should
      end

      def is_to_s(is)
        is.inspect
      end

      def should_to_s(should)
        should.inspect
      end
    end

    newparam(:add_pacemaker_nodes) do
      defaultto true
    end

    newparam(:remove_pacemaker_nodes) do
      defaultto true
    end

    newparam(:add_corosync_nodes) do
      defaultto true
    end

    newparam(:remove_corosync_nodes) do
      defaultto true
    end

    def validate
      fail 'No corosync_nodes!' unless self[:corosync_nodes].is_a? Hash and self[:corosync_nodes].any?
      fail 'No pacemaker_nodes!' unless self[:pacemaker_nodes].is_a? Hash and self[:pacemaker_nodes].any?
    end

    def set_corosync_nodes
      return unless self[:nodes].respond_to? :each
      corosync_nodes = {}
      self[:nodes].each do |name, node|
        id = node['id']
        ip = node['ip']
        next unless id and ip
        corosync_nodes.store id, ip
      end
      self[:corosync_nodes] = corosync_nodes
    end

    def set_pacemaker_nodes
      return unless self[:nodes].respond_to? :each
      pacemaker_nodes = {}
      self[:nodes].each do |name, node|
        id = node['id']
        next unless id and name
        pacemaker_nodes.store name, id
      end
      self[:pacemaker_nodes] = pacemaker_nodes
    end

  end
end

