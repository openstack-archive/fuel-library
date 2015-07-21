# LP#1408531
File.expand_path('../..', File.dirname(__FILE__)).tap { |dir| $LOAD_PATH.unshift(dir) unless $LOAD_PATH.include?(dir) }
File.expand_path('../../../../openstacklib/lib', File.dirname(__FILE__)).tap { |dir| $LOAD_PATH.unshift(dir) unless $LOAD_PATH.include?(dir) }

require 'puppet/provider/keystone/util'

Puppet::Type.newtype(:keystone_user_role) do

  desc <<-EOT
    This is currently used to model the creation of
    keystone users roles.

    User roles are an assignment of a role to a user on
    a certain tenant. The combination of all of these
    attributes is unique.
  EOT

  ensurable

  newparam(:name, :namevar => true) do
  end

  newproperty(:roles,  :array_matching => :all) do
    def insync?(is)
      return false unless is.is_a? Array
      # order of roles does not matter
      is.sort == self.should.sort
    end
  end

  autorequire(:keystone_user) do
    self[:name].rpartition('@').first
  end

  autorequire(:keystone_tenant) do
    proj, dom = Util.split_domain(self[:name].rpartition('@').last)
    rv = nil
    if proj # i.e. not ::domain
      rv = self[:name].rpartition('@').last
    end
    rv
  end

  autorequire(:keystone_role) do
    self[:roles]
  end

  autorequire(:keystone_domain) do
    rv = []
    userdom = Util.split_domain(self[:name].rpartition('@').first)[1]
    if userdom
      rv << userdom
    end
    projectdom = Util.split_domain(self[:name].rpartition('@').last)[1]
    if projectdom
      rv << projectdom
    end
    rv
  end

  # we should not do anything until the keystone service is started
  autorequire(:service) do
    ['keystone']
  end
end
