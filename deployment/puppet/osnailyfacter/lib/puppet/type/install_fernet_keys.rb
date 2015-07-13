Puppet::Type.newtype(:install_fernet_keys,
                     :doc => <<-'ENDOFDOC'
  Copy keys for Keystone Fernet tokens:

install_fernet_keys {'keys_for_fernet_token':
  ensure            => present,
  user              => 'keystone',
  staged_key_path   => '/var/lib/astute/keystone/0',
  primary_key_path  => '/var/lib/astute/keystone/1',
  # Optional parameters
  staged_key_name   => '0',
  primary_key_name  => '1',
  keystone_dir      => '/etc/keystone/',
}
ENDOFDOC
) do

  ensurable

  newparam (:name) do
    desc 'the name of keys'
  end

  newproperty(:user) do
    desc 'keystone user'

    munge do |value|
      String value
    end
  end

  newproperty(:staged_key_path) do
    desc 'Path to staged key in temporary location'
    validate do |value|
      fail "#{value}: does not look like PATH" unless value =~ /^\/\S/
    end
  end

  newproperty(:primary_key_path) do
    desc 'Path to primary key in temporary location'
    validate do |value|
      fail "#{value}: does not look like PATH" unless value =~ /^\/\S/
    end
  end

  newproperty(:staged_key_name) do
    desc 'Name of staged key inside user\'s directory'

    defaultto '0'

    validate do |value|
      fail "Staged key name is empty!" if value.empty?
    end
  end

  newproperty(:primary_key_name) do
    desc 'Name of primary key inside user\'s directory'

    defaultto '1'

    validate do |value|
      fail "Primary key name is empty!" if value.empty?
    end
  end

  newproperty(:keystone_dir) do
    desc 'Path to keystone directory'
    defaultto '/etc/keystone/'
  end

end
