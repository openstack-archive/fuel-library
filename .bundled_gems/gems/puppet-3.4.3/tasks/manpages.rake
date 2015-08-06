# require 'fileutils'

desc "Build Puppet manpages"
task :gen_manpages do
  require 'puppet/face'
  require 'fileutils'

  # TODO: this line is unfortunate.  In an ideal world, faces would serve
  #  as a clear, well-defined entry-point into the code and could be
  #  responsible for state management all on their own; this really should
  #  not be necessary.  When we can, we should get rid of it.
  #  --cprice 2012-05-16
  Puppet.initialize_settings()

  helpface = Puppet::Face[:help, '0.0.1']
  manface  = Puppet::Face[:man, '0.0.1']

  # TODO: This line is terrible.  The reason we need this here is because we
  #  handle state initialization differently when we run via command line
  #  (application.rb) than we do when we try to use Faces as library code.
  #  This is bad, we need to come up with an official stance on what our
  #  API is and what the entry points, so that we can make sure that
  #  state initialization is consistent.  See:
  # http://projects.puppetlabs.com/issues/14441
  Puppet::Util::Instrumentation.init()

  sbins = Dir.glob(%w{sbin/*})
  bins  = Dir.glob(%w{bin/*})
  non_face_applications = helpface.legacy_applications
  faces = Puppet::Face.faces
  ronn_args = '--manual="Puppet manual" --organization="Puppet Labs, LLC" -r'

  # Locate ronn
  ronn = %x{which ronn}.chomp
  unless File.executable?(ronn) then fail("Ronn does not appear to be installed.") end

#   def write_manpage(text, filename)
#     IO.popen("#{ronn} #{ronn_args} -r > #{filename}") do |fh| fh.write text end
#   end

  # Create puppet.conf.5 man page
#   IO.popen("#{ronn} #{ronn_args} > ./man/man5/puppet.conf.5", 'w') do |fh|
#     fh.write %x{RUBYLIB=./lib:$RUBYLIB bin/puppetdoc --reference configuration}
#   end
  %x{RUBYLIB=./lib:$RUBYLIB bin/puppet doc --reference configuration > ./man/man5/puppetconf.5.ronn}
  %x{#{ronn} #{ronn_args} ./man/man5/puppetconf.5.ronn}
  FileUtils.mv("./man/man5/puppetconf.5", "./man/man5/puppet.conf.5")
  FileUtils.rm("./man/man5/puppetconf.5.ronn")

  # Create LEGACY binary man pages (i.e. delete me for 2.8.0)
  binary = bins + sbins
  binary.each do |bin|
    b = bin.gsub( /^s?bin\//, "")
    %x{RUBYLIB=./lib:$RUBYLIB #{bin} --help > ./man/man8/#{b}.8.ronn}
    %x{#{ronn} #{ronn_args} ./man/man8/#{b}.8.ronn}
    FileUtils.rm("./man/man8/#{b}.8.ronn")
  end

  # Create regular non-face man pages
  non_face_applications.each do |app|
    %x{RUBYLIB=./lib:$RUBYLIB bin/puppet #{app} --help > ./man/man8/puppet-#{app}.8.ronn}
    %x{#{ronn} #{ronn_args} ./man/man8/puppet-#{app}.8.ronn}
    FileUtils.rm("./man/man8/puppet-#{app}.8.ronn")
  end

  # Create face man pages
  faces.each do |face|
    File.open("./man/man8/puppet-#{face}.8.ronn", 'w') do |fh|
      fh.write manface.man("#{face}")
    end

    %x{#{ronn} #{ronn_args} ./man/man8/puppet-#{face}.8.ronn}
    FileUtils.rm("./man/man8/puppet-#{face}.8.ronn")
  end

  # Vile hack: create puppet resource man page
  # Currently, the useless resource face wins against puppet resource in puppet
  # man. (And actually, it even gets removed from the list of legacy
  # applications.) So we overwrite it with the correct man page at the end.
  %x{RUBYLIB=./lib:$RUBYLIB bin/puppet resource --help > ./man/man8/puppet-resource.8.ronn}
  %x{#{ronn} #{ronn_args} ./man/man8/puppet-resource.8.ronn}
  FileUtils.rm("./man/man8/puppet-resource.8.ronn")

end
