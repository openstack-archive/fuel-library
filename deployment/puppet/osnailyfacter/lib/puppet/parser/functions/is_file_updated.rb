require 'digest/md5'

module Puppet::Parser::Functions
  newfunction(:is_file_updated, :type => :rvalue,
              :doc => <<-EOS
              Check, that the file was updated since last function execution
              for specific entity (e.g. class name)
              EOS
             ) do |args|

    file = args[0]
    entity = args[1]

    conf = "/etc/neutron/neutron.conf"
    store_dir = "/var/cache/fuel/#{entity}"
    storefile = "#{File.basename.gsub('/','___')}"
    fullpath = "#{store_dir}/#{store_file}"

    FileUtils.mkdir_p store_dir

    if File.exists?(conf)
      actual_hash = Digest::MD5.hexdigest(File.read(conf))
    else
      actual_hash = ""
    end

    if File.exists?(fullpath)
      old_hash = File.read(fullpath)
    else
      old_hash = ""
    end

    File.write(fullpath, actual_hash)

    actual_hash != old_hash

  end
end
