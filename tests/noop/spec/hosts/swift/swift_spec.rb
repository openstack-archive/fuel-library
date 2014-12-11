require 'spec_helper'
require 'shared-examples'
manifest = 'swift/swift.pp'

describe manifest do
  shared_examples 'puppet catalogue' do
    settings = Noop.fuel_settings
    role = settings['role']

    it { should compile }
    # Swift
    if role == 'primary-controller'
      ['account', 'object', 'container'].each do | ring |
        it "should run pretend_min_part_hours_passed before rabalancing swift #{ring} ring" do
          should contain_exec("hours_passed_#{ring}").with(
            'command' => "swift-ring-builder /etc/swift/#{ring}.builder pretend_min_part_hours_passed",
            'user'    => 'swift',
          )
          should contain_exec("rebalance_#{ring}").with(
            'command' => "swift-ring-builder /etc/swift/#{ring}.builder rebalance",
            'user'    => 'swift',
          ).that_requires("Exec[hours_passed_#{ring}]")
          should contain_exec("create_#{ring}").with(
            'user'    => 'swift',
          )
        end
      end
    end
    it 'should create /etc/swift/backups directory with correct ownership' do
      should contain_file('/etc/swift/backups').with(
        'ensure' => 'directory',
        'owner'  => 'swift',
        'group'  => 'swift',
      )
    end
  end
  test_ubuntu_and_centos manifest
end

