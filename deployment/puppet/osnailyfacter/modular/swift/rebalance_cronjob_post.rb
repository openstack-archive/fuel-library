require File.join File.dirname(__FILE__), '../test_common.rb'

class SwiftRebalancePostTest < Test::Unit::TestCase
  def test_that_cron_job_is_configured
    if TestCommon::Settings.lookup('role') == 'primary-controller'
      assert TestCommon::Cron.cronjob_exists?('swift', 'swift-rings-rebalance.sh'),
        'No cronjob for swift-rings-rebalance.sh!'
    else
      assert TestCommon::Cron.cronjob_exists?('swift', 'swift-rings-sync.sh'),
        'No cronjob for swift-rings-sync.sh!'
    end
  end
end
