require 'spec_helper_acceptance'

describe 'ceilometer with mysql' do

  context 'default parameters' do

    it 'should work with no errors' do
      pp= <<-EOS
      Exec { logoutput => 'on_failure' }

      # Common resources
      case $::osfamily {
        'Debian': {
          include ::apt
          class { '::openstack_extras::repo::debian::ubuntu':
            release         => 'kilo',
            package_require => true,
          }
          $package_provider = 'apt'
        }
        'RedHat': {
          class { '::openstack_extras::repo::redhat::redhat':
            release => 'kilo',
          }
          package { 'openstack-selinux': ensure => 'latest' }
          $package_provider = 'yum'
        }
        default: {
          fail("Unsupported osfamily (${::osfamily})")
        }
      }

      class { '::mysql::server': }

      class { '::rabbitmq':
        delete_guest_user => true,
        package_provider  => $package_provider,
      }

      rabbitmq_vhost { '/':
        provider => 'rabbitmqctl',
        require  => Class['rabbitmq'],
      }

      rabbitmq_user { 'ceilometer':
        admin    => true,
        password => 'an_even_bigger_secret',
        provider => 'rabbitmqctl',
        require  => Class['rabbitmq'],
      }

      rabbitmq_user_permissions { 'ceilometer@/':
        configure_permission => '.*',
        write_permission     => '.*',
        read_permission      => '.*',
        provider             => 'rabbitmqctl',
        require              => Class['rabbitmq'],
      }


      # Keystone resources, needed by Ceilometer to run
      class { '::keystone::db::mysql':
        password => 'keystone',
      }
      class { '::keystone':
        verbose             => true,
        debug               => true,
        database_connection => 'mysql://keystone:keystone@127.0.0.1/keystone',
        admin_token         => 'admin_token',
        enabled             => true,
      }
      class { '::keystone::roles::admin':
        email    => 'test@example.tld',
        password => 'a_big_secret',
      }
      class { '::keystone::endpoint':
        public_url => "https://${::fqdn}:5000/",
        admin_url  => "https://${::fqdn}:35357/",
      }

      # Ceilometer resources
      class { '::ceilometer':
        metering_secret     => 'secrete',
        rabbit_userid       => 'ceilometer',
        rabbit_password     => 'an_even_bigger_secret',
        rabbit_host         => '127.0.0.1',
      }
      # Until https://review.openstack.org/177593 is merged:
      Package<| title == 'python-mysqldb' |> -> Class['ceilometer::db']
      class { '::ceilometer::db::mysql':
        password => 'a_big_secret',
      }
      class { '::ceilometer::db':
        database_connection => 'mysql://ceilometer:a_big_secret@127.0.0.1/ceilometer?charset=utf8',
      }
      class { '::ceilometer::keystone::auth':
        password => 'a_big_secret',
      }
      class { '::ceilometer::client': }
      class { '::ceilometer::collector': }
      class { '::ceilometer::expirer': }
      class { '::ceilometer::alarm::evaluator': }
      class { '::ceilometer::alarm::notifier': }
      class { '::ceilometer::agent::central': }
      class { '::ceilometer::agent::notification': }
      class { '::ceilometer::api':
        enabled               => true,
        keystone_password     => 'a_big_secret',
        keystone_identity_uri => 'http://127.0.0.1:35357/',
      }
      EOS


      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    describe port(8777) do
      it { is_expected.to be_listening.with('tcp') }
    end

    describe cron do
      it { should have_entry('1 0 * * * ceilometer-expirer').with_user('ceilometer') }
    end

  end
end
