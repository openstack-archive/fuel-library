require 'digest/md5'

module Puppet::Parser::Functions
  newfunction(:is_neutron_conf_updated, :type => :rvalue,
              :doc => <<-EOS
              Check, that /etc/neutron/neutron.conf was updated since last function execution
              EOS
             ) do |arg|


    conf = "/etc/neutron/neutron.conf"
    store = "/tmp/neutron.conf.md5"

    if File.exists?(conf)
      neutron_conf = File.read(conf)
    else
      neutron_conf = ""
    end

    actual_hash = Digest::MD5.hexdigest(neutron_conf)

    if File.exists?(store)
      old_hash = File.read(store)
    else
      old_hash = ""
    end

    File.write(store, actual_hash)

    actual_hash != old_hash

  end
end
