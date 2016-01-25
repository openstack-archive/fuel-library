# THIS FILE IS JUST A BIT PATCHED VERSION OF STANDARD GEM
# PACKAGE PROVIDER FROM puppet 2.7.19
# TWO ADDITIONAL OPTIONS HAVE BEEN ADDED TO gem COMMAND
# --no-ri --no-rdoc

require 'puppet/provider/package'
require 'uri'

# Ruby gems support.
Puppet::Type.type(:package).provide :gem, :parent => Puppet::Provider::Package do
  desc "Ruby Gem support.  If a URL is passed via `source`, then that URL is used as the
    remote gem repository; if a source is present but is not a valid URL, it will be
    interpreted as the path to a local gem file.  If source is not present at all,
    the gem will be installed from the default gem repositories."

  has_feature :versionable

  commands :gemcmd => "gem"

  def self.gemlist(options)
    gem_list_command = [command(:gemcmd), "list"]

    if options[:local]
      gem_list_command << "--local"
    else
      gem_list_command << "--remote"
    end

    if name = options[:justme]
      gem_list_command << name + "$"
    end

    begin
      list = execute(gem_list_command).lines.
        map {|set| gemsplit(set) }.
        reject {|x| x.nil? }
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error, "Could not list gems: #{detail}"
    end

    if options[:justme]
      return list.shift
    else
      return list
    end
  end

  def self.gemsplit(desc)
    # `gem list` when output console has a line like:
    # *** LOCAL GEMS ***
    # but when it's not to the console that line
    # and all blank lines are stripped
    # so we don't need to check for them

    if desc =~ /^(\S+)\s+\((.+)\)/
      name = $1
      versions = $2.split(/,\s*/)
      {
        :name     => name,
        :ensure   => versions,
        :provider => :gem
      }
    else
      Puppet.warning "Could not match #{desc}"
      nil
    end
  end

  def self.instances(justme = false)
    gemlist(:local => true).collect do |hash|
      new(hash)
    end
  end

  def install(useversion = true)
    command = [command(:gemcmd), "install"]
    command << "-v" << resource[:ensure] if (! resource[:ensure].is_a? Symbol) and useversion
    # Always include dependencies
    command << "--include-dependencies"

    command << "--no-rdoc" << "--no-ri"

    if source = resource[:source]
      begin
        uri = URI.parse(source)
      rescue => detail
        fail "Invalid source '#{uri}': #{detail}"
      end

      case uri.scheme
      when nil
        # no URI scheme => interpret the source as a local file
        command << source
      when /file/i
        command << uri.path
      when 'puppet'
        # we don't support puppet:// URLs (yet)
        raise Puppet::Error.new("puppet:// URLs are not supported as gem sources")
      else
        # interpret it as a gem repository
        command << "--source" << "#{source}" << resource[:name]
      end
    else
      command << resource[:name]
    end

    output = execute(command)
    # Apparently some stupid gem versions don't exit non-0 on failure
    self.fail "Could not install: #{output.chomp}" if output.include?("ERROR")
  end

  def latest
    # This always gets the latest version available.
    hash = self.class.gemlist(:justme => resource[:name])

    hash[:ensure][0]
  end

  def query
    self.class.gemlist(:justme => resource[:name], :local => true)
  end

  def uninstall
    gemcmd "uninstall", "-x", "-a", resource[:name]
  end

  def update
    self.install(false)
  end

end

