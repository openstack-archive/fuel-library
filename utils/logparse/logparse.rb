require 'English'
require 'time'

log = []
top = 10
total = 0

def show_seconds(seconds)
  "#{sprintf('%.02f',seconds)} sec (#{sprintf('%.02f',seconds / 60)} min)"
end

while gets
  begin

    # evaltrace line
    if ($LAST_READ_LINE =~ /.*\/?([A-Z0-9][0-9A-Za-z_]+)\[(.*)\].*Evaluated\s+in\s+(.*)\s+seconds/)
      type = $1.to_sym
      title = $2
      duration = $3.to_f
      level = nil
      time = nil
      message = nil
      
      # remove garbage entries
      next if [ :Filebucket, :Stage, :Schedule, :Class].include? type

      log << { :time => time, :message => message, :level => level, :duration => duration, :number => $INPUT_LINE_NUMBER, :type => type, :title => title }
      total += duration

      # line processed
      next
    end

  rescue
    # error. skip this line
    next
  end
end

# claculates stats by types
types = {}
log.each { |line|
  type = line[:type].to_sym
  duration = line[:duration]

  unless (types[type])
    types[type] = 0.0
  end
  types[type] += duration
}

# OUTPUT

if log.empty?
  puts "No records found!"
  exit 1
end

puts
puts "Top lines:"
number = 1
log.sort_by { |line| line[:duration] }.reverse[0,top].each { |line|
  puts "#{"%02d" % number} - #{show_seconds(line[:duration])}, line: #{line[:number]}, #{line[:type]}[#{line[:title]}]#{line[:level] == 'err:' ? ' ERROR!' : ''}"
  number += 1
}

puts
puts "Top types:"
number = 1
types.sort_by { |type,duration| duration }.reverse[0,top].each { |type,duration|
  puts "#{"%02d" % number} - #{show_seconds(duration)}, #{type}"
  number += 1
}
puts

if total
  puts "Total: #{show_seconds(total)}"
end
