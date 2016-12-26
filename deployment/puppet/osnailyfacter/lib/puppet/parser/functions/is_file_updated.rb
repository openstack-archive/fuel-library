require 'digest/md5'

module Puppet::Parser::Functions
  newfunction(:is_file_updated, :type => :rvalue, :arity => 2,
              :doc => <<-EOS
              Check, that the file was updated since last function execution
              for specific entity (e.g. class name)
              EOS
             ) do |args|

    file = args[0]
    entity = args[1]

    store_dir = "/var/cache/fuel/#{entity}"
    store_file = "#{File.basename(file).gsub('/','___')}"
    fullpath = "#{store_dir}/#{store_file}"

    FileUtils.mkdir_p store_dir

    actual_hash = Digest::MD5.hexdigest(File.read(file)) rescue ""
    old_hash = File.read(fullpath) rescue ""

    File.write(fullpath, actual_hash)

    actual_hash != old_hash

  end
end
