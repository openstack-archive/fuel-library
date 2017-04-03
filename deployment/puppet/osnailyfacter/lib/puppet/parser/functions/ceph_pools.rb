Puppet::Parser::Functions::newfunction(:ceph_pools, :arity => 0, :type => :rvalue, :doc => <<-EOS
  Parses osd pools and returns only pool names as an array
EOS
) do |args|
  pools = %x(ceph osd lspools).chomp!.split(',')
  pools.map {|x| x.sub(/^\d+ /, '')  }
end
