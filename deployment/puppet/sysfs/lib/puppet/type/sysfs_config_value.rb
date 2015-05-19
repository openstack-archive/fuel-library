require 'digest/md5'

Puppet::Type.newtype(:sysfs_config_value, :doc => <<-eos
This resource creates a single file in the sysfs config directory. The content
of this files can either be passed directly by the "content" property the same
way as usual "file" resource works or it can be autogenerated.

For example, it you want to set the scheduler of all your SSDs to "noop" you
can specify "/sys/block/sd*/queue/scheduler" as the "sysfs" property and "noop"
as the "value" property. The configuration file will contain:

block/sda/queue/scheduler = noop
block/sdb/queue/scheduler = noop

The globulation will be opened to match every drive and the value will be set
for every line.

You can exclude sysfs path elements by specifying "sdb" to the "exclude"
parameter to exclude matching lines from the file.

If you need to pass different values for different lines you can pass a hash
to the "value" parameter instead of a string:

value => { 'sdb' => 'deadline', 'default' => 'noop' }

The matching lines will be set to their values and the “default” values will be
used for the lines that have not matched any of the hash keys.

Parameters "sysfs" and "exclude" can actually accept several patterns as an
array, but, perhaps, it would be better to use several instances of this
resources if you need to set a lot of different values.
eos
) do

  ensurable

  newparam :name, :namevar => true do
    desc 'The path to the config file'
  end

  newparam :sysfs do
    desc 'Path to the SysFS nodes to be updated'
    munge do |value|
      break unless value
      break value if value.is_a? Array
      [value]
    end
  end

  newparam :exclude do
    desc 'Path to the SysFS nodes to be excluded'
    munge do |value|
      break unless value
      break value if value.is_a? Array
      [value]
    end
  end

  newparam :value do
    desc 'Set the SysFS nodes to this value'
    validate do |value|
      fail "The value should be either a string or a hash!" unless value.is_a? String or value.is_a? Hash
    end
  end

  newproperty :content do
    desc 'Content of the config file. Should be autogenerated unless overriden.'

    def should_to_s(value)
      "(md5)#{Digest::MD5.hexdigest value}"
    end

    def is_to_s(value)
      "(md5)#{Digest::MD5.hexdigest value}"
    end
  end

  def generate_content?
    return false if self[:content]
    !self[:sysfs].nil? and !self[:value].nil?
  end

  def validate
    fail 'You should privide either "sysfs" and "value" to generate content or the "content" itself!' unless self[:content] or generate_content?
  end

end
