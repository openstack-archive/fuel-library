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

    newproperty(:corosync_nodes) do
      defaultto { @resource[:nodes] }

      def insync?(is)
        @resource.compare_by_keys is, should, %w(id ip)
      end

      def is_to_s(is)
        is.inspect
      end

      def should_to_s(should)
        should.inspect
      end
    end

    newproperty(:pacemaker_nodes) do
      defaultto { @resource[:nodes] }

      def insync?(is)
        @resource.compare_by_keys is, should, 'id'
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

    def compare_by_keys(hash1, hash2, keys=nil)
      return hash1 == hash2 unless keys
      keys = [keys] unless keys.is_a? Array
      fail 'First argument should be a Hash!' unless hash1.is_a? Hash
      fail 'Second argument should be a Hash!' unless hash2.is_a? Hash
      filtered_hash1 = filter_hash hash1, keys
      filtered_hash2 = filter_hash hash2, keys
      filtered_hash1 == filtered_hash2
    end

    def filter_hash(hash, keys)
      data = {}
      keys = [keys] unless keys.is_a? Array
      fail 'First argument should be a Hash!' unless hash.is_a? Hash
      hash.each do |hash_key, hash_value|
        data[hash_key] = {}
        keys.each do |key|
          data[hash_key].store key, hash_value[key] if hash_value.key? key
        end
      end
      data
    end

  end
end

