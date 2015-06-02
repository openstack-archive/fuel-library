module Puppet::Parser::Functions
  newfunction(:cpu_affinity_hex, :type => :rvalue, :doc => <<-EOS
Generate a HEX value used to set network device rsp_cpus value
EOS
  ) do |argv|
    number = argv[0].to_i
    fail "Argument should be the CPU number - positive integer value!" if number < 1
    # sysfs is unable to use more than 8 bit mask for cpu affinity
    # just use cpus 0-31 if > 32 cpus present
    # TODO: Remove these lines when sysfs supports > 8 bit mask for affinity
    if number > 32 then
      number = 32
    end
    ((2 ** number) - 1).to_s(16)
  end
end
