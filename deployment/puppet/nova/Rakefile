remote_modules = [
  'git@github.com:bodepd/puppet-apt.git',
  'git@github.com:bodepd/puppetlabs-mysql.git' ,
  'git@github.com:bodepd/puppetlabs-gcc.git',
  'git@github.com:bodepd/puppetlabs-git.git',
  'git@github.com:bodepd/puppetlabs-rabbitmq.git'
]

task :prepare do
  ignore_add = []
  puts 'Downloading remote packages'
  ignore_file = File.join(File.dirname(__FILE__), '.gitignore')
  FileUtils.touch(ignore_file) unless File.exists?(ignore_file)
  File.open(ignore_file, 'w') do |fh|
    remote_modules.each do |mymodule|
      puts `git clone #{mymodule}`
      if mymodule =~ /.*?\/(\w+-(\w+))\.git$/
        if File.read(ignore_file).grep(/#{mymodule}/).empty?
          fh.puts($2)
        end
        puts "mv #{$1} #{$2}"
        FileUtils.mv($1, $2)
      else
        raise ArgumentError, "Invalid module name #{mymodule}"
      end
    end
  end
end
