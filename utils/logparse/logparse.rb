require 'English'
require 'time'

log = []
top = 10

def show_seconds(seconds)
  "#{sprintf('%.02f',seconds)} sec (#{sprintf('%.02f',seconds / 60)} min)"
end

while gets
  begin
    if $LAST_READ_LINE =~ /MODULAR:\s*(\S+)/
      task_name = $1
    end

    if $LAST_READ_LINE =~ /.*\/?([A-Z0-9][0-9A-Za-z_]+)\[(.*)\].*Evaluated\s+in\s+(.*)\s+seconds/
      type = $1.to_sym
      title = $2
      duration = $3.to_f
      level = nil
      time = nil
      message = nil
      
      # remove garbage entries
      next if [ :Filebucket, :Stage, :Schedule, :Class].include? type

      log << { :time => time, :message => message, :level => level, :duration => duration, :number => $INPUT_LINE_NUMBER, :type => type, :title => title, :task => task_name }

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

  unless types[type]
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
  puts "#{"%02d" % number} - #{show_seconds(line[:duration])}, task: #{line[:task]}, line: #{line[:number]}, #{line[:type]}[#{line[:title]}]#{line[:level] == 'err:' ? ' ERROR!' : ''}"
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
puts "Top tasks:"
task_stat = {}
log.each do |line|
  task_name = line[:task]
  duration = line[:duration]
  next unless task_name and duration
  task_stat[task_name] = 0 unless task_stat[task_name]
  task_stat[task_name] += duration
end

number = 1
task_stat.sort_by { |task, time| time }.reverse[0,top].each do |task, time|
  puts "#{"%02d" % number} - #{show_seconds(time)}, task: #{task}"
  number += 1
end

puts
puts "Total resource time (does not include facter and catalog compile time)"
total_time = 0
log.each do |line|
  total_time += line[:duration] if line[:duration]
end
puts show_seconds total_time
