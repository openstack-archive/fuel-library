require 'pathname'

Puppet::Type.type(:x509_sign).provide(:openssl) do
  desc 'Signs certificate request with OpenSSL'

  commands :openssl => 'openssl'

  def exists?
    return Pathname.new(resource[:path]).exist?
  end

  def create
    openssl(
      'ca',
      '-out', resource[:path],
      '-config', resource[:template],
      '-batch',
      '-in', resource[:infile]
    )
  end

  def destroy
    Pathname.new(resource[:path]).delete
  end
end
