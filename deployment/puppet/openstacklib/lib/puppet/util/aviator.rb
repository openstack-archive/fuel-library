# Add the auth parameter to whatever type is given
module Puppet::Util::Aviator
  def self.add_aviator_params(type)

    type.newparam(:auth) do

      desc <<EOT
Hash of authentication credentials. Credentials can be specified as
password credentials, e.g.:

auth => {
  'username'    => 'test',
  'password'    => 'passw0rd',
  'tenant_name' => 'test',
  'host_uri'    => 'http://localhost:35357/v2.0',
}

or a path to an openrc file containing these credentials, e.g.:

auth => {
  'openrc' => '/root/openrc',
}

or a service token and host, e.g.:

auth => {
  'service_token' => 'ADMIN',
  'host_uri'    => 'http://localhost:35357/v2.0',
}

If not present, the provider will first look for environment variables
for password credentials and then to /etc/keystone/keystone.conf for a
service token.
EOT

      validate do |value|
        raise(Puppet::Error, 'This property must be a hash') unless value.is_a?(Hash)
      end
    end

    type.newparam(:log_file) do
      desc 'Log file. Defaults to no logging.'
      defaultto('/dev/null')
    end
  end
end
