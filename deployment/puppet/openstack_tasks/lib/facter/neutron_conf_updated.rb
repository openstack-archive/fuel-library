require 'digest/md5'

conf = "/etc/neutron/neutron.conf"
store = "/tmp/neutron.conf.md5"

def read_hash(file)
  if File.exists?(file)
    Digest::MD5.hexdigest(File.read(file))
  end
end

actual_hash = read_hash(conf)
old_hash = File.read(store)

File.write(store, actual_hash)

Facter.add(:neutron_conf_updated) do
  setcode do
    actual_hash != old_hash
  end
end
