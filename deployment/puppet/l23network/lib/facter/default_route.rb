def get_def_route
  addr = nil
  File.open("/proc/net/route", "r") do |rff|
    while (line = rff.gets)
      rgx = line.match('^\s*(\S+)\s+00000000\s+([\dABCDEF]{8})\s+')
      if rgx
        vals = rgx.to_a[2]
        addr = []
        0.step(6, 2) do |i| 
          addr << vals.slice(i,2).hex
        end
        addr = addr.reverse.join('.')
        break
      end
    end
  end
  return addr
end

Facter.add('default_route') do
  setcode do
    get_def_route()
  end 
end