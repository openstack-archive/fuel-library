require File.join File.dirname(__FILE__), '../test_common.rb'

class SslKeysSavingPostTest < Test::Unit::TestCase

  def public_ssl
    ssl_hash = TestCommon::Settings.lookup 'public_ssl'
    ssl_hash['horizon'] or ssl_hash['services']
  end

  def test_ssl_keys_availability
    assert File.file?('/var/lib/astute/haproxy/public_haproxy.pem'), 'No public keypair saved!' unless not public_ssl
    assert !File.file?('/var/lib/astute/haproxy/public_haproxy.pem'), 'Keypair exist but should not!' unless public_ssl
  end

end
