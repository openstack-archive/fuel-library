require File.join File.dirname(__FILE__), '../test_common.rb'

class ConnectivityTests < Test::Unit::TestCase

  def test_can_resolve_dns
    host = 'www.google.com'
    assert TestCommon::Network.resolve?(host), "
Cannot resolve host '#{host}'.
Please check the DNS servers on the settings page and network connectivity."
  end

  def test_can_communicate_with_ntp_hosts
    if %w(controller primary-controller).include? TestCommon::Settings.role
      ntp_list = TestCommon::Settings.external_ntp['ntp_list']
      ok = false
      ntp_list.split(",").each do |ntp_host|
        ntp_host.strip!
        if (TestCommon::Network.ntp?(ntp_host))
          ok = true
        end
      end
      assert ok, "
Unable to talk to at least 1 ntp server (#{ntp_list}).
Please check nodes access to all of the ntp servers on the settings page."
    end
  end

  def test_can_access_software_repos
    repos = TestCommon::Settings.repo_setup['repos']
    repos.each do |repo|
      uri = repo['uri'].strip
      assert TestCommon::Network.url_accessible?(uri), "
Unable to connect to software repo '#{uri}'.
Please check nodes access to all of the repos on the settings page."
    end
  end
end
