require 'net/https'
require 'open-uri'

Puppet::Type.type(:package).provide :rrpm, :parent => :rpm, :source => :rpm do
  desc "Remote .rpm packages management"

  def get_packages(url)
    list = Net::HTTP.get(URI(url)).scan(/.*\.rpm/)
    return list.map { |x| x.gsub(/\<.*\>/, '') }
  end

  def get_package_file(name,url)
    get_packages(url).each do |package|
      if package.start_with?(name)
        return package
      end
    end
    nil
  end

  def download
    package = get_package_file(@resource[:name],@resource[:source])
    path = "#{@resource[:source]}/#{package}"
    File.open("/tmp/#{package}", 'wb') do |fo|
      fo.write open(path).read
    end
    @resource[:source] = "/tmp/#{package}"
  end

  def install
    download
    super
  end
end
