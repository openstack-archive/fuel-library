require 'spec_helper'

describe 'swift::dispersion' do

  let :facts do
    { :osfamily => 'Debian' }
  end

  it { should contain_file('/etc/swift/dispersion.conf').with(
    :ensure  => 'present',
    :owner   => 'swift',
    :group   => 'swift',
    :mode    => '0660',
    :require => 'Package[swift]')
  }

  describe 'with default parameters' do
    it { should contain_file('/etc/swift/dispersion.conf') \
      .with_content(/^\[dispersion\]$/)
    }
    it { should contain_file('/etc/swift/dispersion.conf') \
      .with_content(/^auth_url = http:\/\/127.0.0.1:5000\/v2.0\/$/)
    }
    it { should contain_file('/etc/swift/dispersion.conf') \
      .with_content(/^auth_version = 2.0$/)
    }
    it { should contain_file('/etc/swift/dispersion.conf') \
      .with_content(/^auth_user = services:dispersion$/)
    }
    it { should contain_file('/etc/swift/dispersion.conf') \
      .with_content(/^auth_key = dispersion_password$/)
    }
    it { should contain_file('/etc/swift/dispersion.conf') \
      .with_content(/^swift_dir = \/etc\/swift$/)
    }
    it { should contain_file('/etc/swift/dispersion.conf') \
      .with_content(/^dispersion_coverage = 1$/)
    }
    it { should contain_file('/etc/swift/dispersion.conf') \
      .with_content(/^retries = 5$/)
    }
    it { should contain_file('/etc/swift/dispersion.conf') \
      .with_content(/^concurrency = 25$/)
    }
    it { should contain_file('/etc/swift/dispersion.conf') \
      .with_content(/^dump_json = no$/)
    }
    it { should contain_exec('swift-dispersion-populate').with(
      :path      => ['/bin', '/usr/bin'],
      :subscribe => 'File[/etc/swift/dispersion.conf]',
      :onlyif    => "swift -A http://127.0.0.1:5000/v2.0/ -U services:dispersion -K dispersion_password -V 2.0 stat | grep 'Account: '",
      :unless    => "swift -A http://127.0.0.1:5000/v2.0/ -U services:dispersion -K dispersion_password -V 2.0 list | grep dispersion_"
    )}
  end

  describe 'when parameters are overriden' do
    let :params do
      {
        :auth_url     => 'https://169.254.0.1:7000/auth/v8.0/',
        :auth_user    => 'foo',
        :auth_tenant  => 'bar',
        :auth_pass    => 'dummy',
        :auth_version => '1.0',
        :swift_dir    => '/usr/local/etc/swift',
        :coverage     => 42,
        :retries      => 51,
        :concurrency  => 4682,
        :dump_json    => 'yes'
      }
    end
    it { should contain_file('/etc/swift/dispersion.conf') \
      .with_content(/^\[dispersion\]$/)
    }
    it { should contain_file('/etc/swift/dispersion.conf') \
      .with_content(/^auth_url = https:\/\/169.254.0.1:7000\/auth\/v8.0\/$/)
    }
    it { should contain_file('/etc/swift/dispersion.conf') \
      .with_content(/^auth_version = 1.0$/)
    }
    it { should contain_file('/etc/swift/dispersion.conf') \
      .with_content(/^auth_user = bar:foo$/)
    }
    it { should contain_file('/etc/swift/dispersion.conf') \
      .with_content(/^auth_key = dummy$/)
    }
    it { should contain_file('/etc/swift/dispersion.conf') \
      .with_content(/^swift_dir = \/usr\/local\/etc\/swift$/)
    }
    it { should contain_file('/etc/swift/dispersion.conf') \
      .with_content(/^dispersion_coverage = 42$/)
    }
    it { should contain_file('/etc/swift/dispersion.conf') \
      .with_content(/^retries = 51$/)
    }
    it { should contain_file('/etc/swift/dispersion.conf') \
      .with_content(/^concurrency = 4682$/)
    }
    it { should contain_file('/etc/swift/dispersion.conf') \
      .with_content(/^dump_json = yes$/)
    }
    it { should contain_exec('swift-dispersion-populate').with(
      :path      => ['/bin', '/usr/bin'],
      :subscribe => 'File[/etc/swift/dispersion.conf]',
      :onlyif    => "swift -A https://169.254.0.1:7000/auth/v8.0/ -U bar:foo -K dummy -V 1.0 stat | grep 'Account: '",
      :unless    => "swift -A https://169.254.0.1:7000/auth/v8.0/ -U bar:foo -K dummy -V 1.0 list | grep dispersion_"
    )}
  end
end
