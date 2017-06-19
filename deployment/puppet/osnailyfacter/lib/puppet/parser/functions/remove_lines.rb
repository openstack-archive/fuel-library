require 'fileutils'
require 'tempfile'

module Puppet::Parser::Functions
  newfunction(:remove_lines,
:doc => <<-EOS
Remove lines from file that match a regexp
EOS
  ) do |args|

    raise(Puppet::ParseError, 'Function should contain path and matching string separated by comma') if args.size != 2

    filename = args[0]
    match    = args[1]
    basename = File.basename filename

    break unless File.file?(filename)

    t_file = Tempfile.new(basename)

    File.open(filename).each do |line|
      if line !~ /#{match}/
        t_file.puts line
      end
    end

    FileUtils.mv(t_file.path, filename)

  end
end

