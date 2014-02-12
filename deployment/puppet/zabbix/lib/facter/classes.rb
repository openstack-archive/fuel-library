#classes.rb

classes = '/var/lib/puppet/classes.txt'

if File.exists?(classes)
  output = Array.new
  File.open(classes).each do |line|
    output << line.chop
  end
  Facter.add('classes') do
    setcode do
      output.sort.join(',')
    end
  end
end

