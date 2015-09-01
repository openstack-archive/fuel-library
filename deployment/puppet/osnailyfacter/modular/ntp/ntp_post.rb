require File.join File.dirname(__FILE__), '../test_common.rb'

class NTPServerPostTest < Test::Unit::TestCase

  def has_external_ntp?
    TestCommon::Settings.lookup 'external_ntp'
  end

  def test_ntp_config_present
    assert File.file?('/etc/ntp.conf'), 'No NTP config file!'
  end

  def test_ntp_is_running
    assert TestCommon::Process.running?('/usr/sbin/ntpd'), 'NTP is not running!'
  end

  def test_ntp_monitor_inaccessible_via_public
    out = `ntpq -p #{TestCommon::Settings.public_address}`
    assert out == '', "NTP peers advertised on public address"
  end

  def test_ntp_monitor_inaccessible_via_internal
    out = `ntpq -p #{TestCommon::Settings.internal_address}`
    assert out == '', "NTP peers advertised on internal address"
  end
end

