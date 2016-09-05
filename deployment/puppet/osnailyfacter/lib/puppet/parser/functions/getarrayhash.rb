module Puppet::Parser::Functions
  newfunction(:getarrayhash, :type=>:rvalue, :doc=> <<-'ENDHEREDOC') do |args|
    Creates an array of hashes with keys as args[0] and values as args[1][].
    Attention! args[0] is a constant, not the array.
    For example:
      args[0]="ensure"
      args[1]=["1ubuntu2.3", "1ubuntu3.4", "latest"]
      result is [{"ensure" => "1ubuntu2.3"},{"ensure" => "1ubuntu3.4"},{"ensure" => "latest"}]

    ENDHEREDOC

    Array.new(args[1].length) {  |index|  Hash[args[0], args[1][index]]  }
  end
end
