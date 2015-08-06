require 'puppet/indirector/ssl_file'
require 'puppet/ssl/key'

class Puppet::SSL::Key::File < Puppet::Indirector::SslFile
  desc "Manage SSL private and public keys on disk."

  store_in :privatekeydir
  store_ca_at :cakey

  def allow_remote_requests?
    false
  end

  # Where should we store the public key?
  def public_key_path(name)
    if ca?(name)
      Puppet[:capub]
    else
      File.join(Puppet[:publickeydir], name.to_s + ".pem")
    end
  end

  # Remove the public key, in addition to the private key
  def destroy(request)
    super

    return unless Puppet::FileSystem::File.exist?(public_key_path(request.key))

    begin
      Puppet::FileSystem::File.unlink(public_key_path(request.key))
    rescue => detail
      raise Puppet::Error, "Could not remove #{request.key} public key: #{detail}"
    end
  end

  # Save the public key, in addition to the private key.
  def save(request)
    super

    begin
      Puppet.settings.setting(:publickeydir).open_file(public_key_path(request.key), 'w') { |f| f.print request.instance.content.public_key.to_pem }
    rescue => detail
      raise Puppet::Error, "Could not write #{request.key}: #{detail}"
    end
  end
end
