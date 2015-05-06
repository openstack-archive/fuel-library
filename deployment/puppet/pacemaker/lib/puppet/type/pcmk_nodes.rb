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

    newparam(:nodes, :array_matching => :all) do
      desc 'Nodes data structure. Hash { "name" => "ip" }'
      validate do |value|
        unless value.is_a? Hash and value.any?
          fail 'Nodes should be a non-empty hash { "name" => "ip" }!'
        end
      end
    end

    newproperty(:corosync_nodes, :array_matching => :all) do
      defaultto { @resource[:nodes].keys if @resource[:nodes] }

      def insync?(is)
        return false unless is.is_a? Array and should.is_a? Array
        is.sort == should.sort
      end

      def is_to_s(is)
        is.inspect
      end

      def should_to_s(should)
        should.inspect
      end
    end

    newproperty(:pacemaker_nodes, :array_matching => :all) do
      defaultto { @resource[:nodes].keys if @resource[:nodes] }

      def insync?(is)
        return false unless is.is_a? Array and should.is_a? Array
        is.sort == should.sort
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
      fail 'No corosync_nodes!' unless self[:corosync_nodes].is_a? Array and self[:corosync_nodes].any?
      fail 'No pacemaker_nodes!' unless self[:pacemaker_nodes].is_a? Array and self[:pacemaker_nodes].any?
    end

  end
end

