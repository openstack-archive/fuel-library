Puppet::Type.newtype(:install_ssh_keys,
                     :doc => <<-'ENDOFDOC'
  Copy and append key to authorized_keys for users:

install_ssh_keys {'root_ssh_key':
  ensure           => present,
  user             => 'root',
  private_key_path => '/root/key',
  public_key_path  => '/root/key.pub',
  # Optional parameters
  private_key_name => 'id_rsa',
  public_key_name  => 'id_rsa_pub',
  authorized_keys  => 'authorized_keys2',
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

  newparam :private_key_path do
    desc 'Path to private key in temporary location'
    validate do |value|
      raise Puppet::Error, "#{value} does not look like PATH" unless value =~ /^\/\S/
      raise Puppet::Error, "#{value} no such file" unless File.exists? value
    end
  end

  newparam :public_key_path do
    desc 'Path to public key in temporary location'
    validate do |value|
      raise Puppet::Error, "#{value} does not look like PATH" unless value =~ /^\/\S/
      raise Puppet::Error, "#{value} no such file" unless File.exists? value
    end
  end

  newparam :private_key_name do
    desc 'Name of private key inside user\'s directory'

    defaultto 'id_rsa'

    validate do |value|
      raise Puppet::Error, "Private key name is empty!" if value.empty?
    end
  end

  newparam :public_key_name do
    desc 'Name of public key inside user\'s directory'

    defaultto 'id_rsa.pub'

    validate do |value|
      raise Puppet::Error, "Public key name is empty!" if value.empty?
    end
  end

  newparam :authorized_keys do

    defaultto 'authorized_keys'

    validate do |value|
      unless ['authorized_keys', 'authorized_keys2'].include? value
        raise Puppet::Error, "#{value} it should be authorized_keys or authorized_keys2"
      end
    end
  end
end
