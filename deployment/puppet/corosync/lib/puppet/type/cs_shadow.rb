module Puppet
  newtype(:cs_shadow) do
    @doc = "cs_shadow resources represent a Corosync shadow CIB. Any corosync
      resources defined with 'cib' set to the title of a cs_shadow resource
      will not become active until all other resources with the same cib
      value have also been applied."

    newproperty(:cib) do
      def sync
        provider.sync(self.should)
      end

      def retrieve
        :absent
      end

      def insync?(is)
        false
      end

      defaultto { @resource[:name] }
    end

    newparam(:name) do
      desc "Name of the shadow CIB to create and manage"
      isnamevar
    end

    def generate
      options = { :name => @title }
      [ Puppet::Type.type(:cs_commit).new(options) ]
    end

    autorequire(:service) do
      [ 'corosync' ]
    end
  end
end
