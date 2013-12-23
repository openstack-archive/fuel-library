require 'English'
require 'time'

log = []
last_time = nil
errors = 0
top = 10
evaltrace = false

def show_seconds(seconds)
  "#{sprintf('%.02f',seconds)} sec (#{sprintf('%.02f',seconds / 60)} min)"
end

while gets
  begin

    # last line. exit this file!
    if ($LAST_READ_LINE =~ /Finished catalog run in (\S+) seconds/)
      total = $1.to_f
      break
    end

    # evaltrace line
    if ($LAST_READ_LINE =~ /.*\/?([A-Z0-9][0-9A-Za-z_]+)\[(.*)\].*Evaluated\s+in\s+(.*)\s+seconds/)
      unless evaltrace
        evaltrace = true
        puts "Evaltrace found!"
        log = []
      end
      type = $1.to_sym
      title = $2
      duration = $3.to_f
      level = nil
      time = nil
      message = nil
      
      # remove garbage entries
      next if [ :Filebucket, :Stage, :Schedule, :Class].include? type

      log << { :time => time, :message => message, :level => level, :duration => duration, :number => $INPUT_LINE_NUMBER, :type => type, :title => title }

      # line processed
      next
    end

    # if we use evaltrace don't do normal parsing
    next if evaltrace

    # a puppet line with time
    if ($LAST_READ_LINE =~ /^(\S+)\s+(\S+)\s+\((.*?)\)/)
      time = Time.parse $1
      level = $2
      message = $3

      # set duration of this line
      if last_time
        duration = time - last_time
      else
        duration = 0.0
      end
      last_time = time
      
      # line with resource
      if (message =~ /.*\/([A-Z0-9][0-9A-Za-z_]+)\[(.*)\]/)
        type = $1.to_sym
        title = $2

        log << { :time => time, :message => message, :level => level, :duration => duration, :number => $INPUT_LINE_NUMBER, :type => type, :title => title }
        if (level == 'err:')
          errors += 1
        end

        # line processed
        next
      end
      
      # line did not match
      next

    end
    # end line with time
 
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

if errors > 0
  puts "Errors: #{errors}"
end
