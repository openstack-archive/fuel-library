require File.join File.dirname(__FILE__), '../test_common.rb'

class ConnectivityTests < Test::Unit::TestCase

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
