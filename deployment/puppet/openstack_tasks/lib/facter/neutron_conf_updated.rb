require 'digest/md5'

conf = "/etc/neutron/neutron.conf"
store = "/tmp/neutron.conf.md5"

def read_file(file)
  if File.exists?(file)
    File.read(file)
  else
    ""
  end
end

def read_hash(file)
  Digest::MD5.hexdigest(read_file(file))
end

actual_hash = read_hash(conf)
old_hash = read_file(store)

File.write(store, actual_hash)

Facter.add(:neutron_conf_updated) do
  setcode do
    actual_hash != old_hash
  end
end
