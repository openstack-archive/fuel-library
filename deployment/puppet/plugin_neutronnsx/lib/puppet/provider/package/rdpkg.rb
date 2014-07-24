require 'net/https'
require 'open-uri'

Puppet::Type.type(:package).provide :rdpkg, :parent => :dpkg, :source => :dpkg do
  desc "Remote .deb packages management"

  def get_packages(url)
    list = Net::HTTP.get(URI(url)).scan(/\S*\.deb\"\>/)
    return list.map { |x| x.gsub(/.*\"(.*)../, '\1') }
  end

  def get_package_file(name,url)
    Puppet.debug "RDPKG: URL '#{url}' contains packages:"
    get_packages(url).each do |package|
      Puppet.debug "RDPKG:    #{package}"
      if package.start_with?(name)
        return package
      end
    end
    Puppet.warning "RDPKG: package '#{name}' not found by URL '#{url}'"
    nil
  end

  def download
    Puppet.debug "RDPKG: trying to download package #{@resource[:name]}"
    package = get_package_file(@resource[:name],@resource[:source])
    path = "#{@resource[:source]}/#{package}"
    Puppet.debug "RDPKG: package is found at #{path}"
    File.open("/tmp/#{package}", 'wb') do |fo|
      fo.write open(path).read
    end
    @resource[:source] = "/tmp/#{package}"
    Puppet.debug "RDPKG: package is saved to #{@resource[:source]}"
  end

  def install
    download
    super
  end
end
