require 'spec_helper_acceptance'

describe 'horizon class' do

  context 'default parameters' do

    it 'should work with no errors' do
      pp= <<-EOS
      Exec { logoutput => 'on_failure' }

      case $::osfamily {
        'Debian': {
          include ::apt
          class { '::openstack_extras::repo::debian::ubuntu':
            release         => 'kilo',
            package_require => true,
          }
        }
        'RedHat': {
          class { '::openstack_extras::repo::redhat::redhat':
            release => 'kilo',
          }
          package { 'openstack-selinux': ensure => 'latest' }
        }
        default: {
          fail("Unsupported osfamily (${::osfamily})")
        }
      }

      class { '::horizon':
        secret_key       => 'big_secret',
        # need to disable offline compression due to
        # https://bugs.launchpad.net/ubuntu/+source/horizon/+bug/1424042
        compress_offline => false,
        allowed_hosts    => 'localhost',
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    # basic test for now, to make sure Apache serve /horizon dashboard
    if os[:family] == 'Debian'
      describe command('curl --connect-timeout 5 -sL -w "%{http_code} %{url_effective}\n" http://localhost/horizon/ -o /dev/null') do
        it { should return_exit_status 0 }
      end
    elsif os[:family] == 'RedHat'
      describe command('curl --connect-timeout 5 -sL -w "%{http_code} %{url_effective}\n" http://localhost/dashboard/ -o /dev/null') do
        it { should return_exit_status 0 }
      end
    end

  end

end
