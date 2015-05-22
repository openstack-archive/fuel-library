require File.join File.dirname(__FILE__), '../test_common.rb'

class SslKeysSavingPostTest < Test::Unit::TestCase

  def has_public_ssl?
    TestCommon::Settings.lookup 'public_ssl'
  end

  def test_ssl_keys_availability
    return unless has_public_ssl
    assert File.file?('/var/lib/astute/haproxy/public_haproxy.pem'), 'No public keypair saved!'
  end

end
