# swift_mountponts.rb

$result = ""


# File.open('/proc/self/mounts').each do |line|
#
#   if line.split()[0]!='none'
#     $result += line.split()[0]+"\n"
#
#   end
# end

mounted_devs = %x[df |grep '/srv/node']
mounted_devs.split("\n").each do |mountpoint|
  dev, weight = mountpoint.split(/\b/).values_at(-1, 5)
  if dev and weight.strip !=""
    $result += dev + " " + weight.to_i.fdiv(10485760).ceil.to_s + "\n"
  end
end

Facter.add("swift_mountpoints") do

 setcode do
   $result
   end
end
