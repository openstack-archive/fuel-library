Puppet::Type.newtype(:install_ssh_keys,
                     :doc => <<-'ENDOFDOC'
  Copy and append key to authorized_keys for users:

install_ssh_keys {'root_ssh_key':
  ensure      => present,
  user        => 'root',
  keypath     => '/root/key',
  pub_keypath => '/root/key.pub',
}
ENDOFDOC
) do

  ensurable

  newparam :name, :namevar => true do
    desc 'the name of keys'
  end

  newparam :user do
    desc 'sshkey access user'

    munge do |value|
      String value
    end
  end

  newparam :keypath do
    desc 'path to private key'
    validate do |value|
      raise Puppet::Error, "#{value} does not look like PATH" unless value =~ /^\/\S/
      raise Puppet::Error, "#{value} no such file" unless File.exist? value
    end
  end

  newparam :pub_keypath do
    desc 'path to public key'
    validate do |value|
      raise Puppet::Error, "#{value} does not look like PATH" unless value =~ /^\/\S/
      raise Puppet::Error, "#{value} no such file" unless File.exist? value
    end
  end

  newparam :authkey do

    defaultto 'authorized_keys2'

    validate do |value|
      unless ['authorized_keys', 'authorized_keys2'].include? value
        raise Puppet::Error, "#{value} it should be authorized_keys or authorized_keys2"
      end
    end
  end
end
