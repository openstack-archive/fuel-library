require 'spec_helper_acceptance'

describe 'basic nova' do

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
            # Kilo is not GA yet, so let's use the testing repo
            manage_rdo => false,
            repo_hash  => {
              'rdo-kilo-testing' => {
                'baseurl'  => 'https://repos.fedorapeople.org/repos/openstack/openstack-kilo/testing/el7/',
                # packages are not GA so not signed
                'gpgcheck' => '0',
                'priority' => 97,
              },
            },
          }
          $package_provider = 'yum'
        }
        default: {
          fail("Unsupported osfamily (${::osfamily})")
        }
      }

      class { '::mysql::server': }

      class { '::rabbitmq':
        delete_guest_user => true,
        erlang_cookie     => 'secrete',
        package_provider  => $package_provider,
      }

      rabbitmq_vhost { '/':
        provider => 'rabbitmqctl',
        require  => Class['rabbitmq'],
      }

      rabbitmq_user { 'nova':
        admin    => true,
        password => 'an_even_bigger_secret',
        provider => 'rabbitmqctl',
        require  => Class['rabbitmq'],
      }

      rabbitmq_user_permissions { 'nova@/':
        configure_permission => '.*',
        write_permission     => '.*',
        read_permission      => '.*',
        provider             => 'rabbitmqctl',
        require              => Class['rabbitmq'],
      }

      # Keystone resources, needed by Nova to run
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

      # Nova resources
      class { '::nova':
        database_connection => 'mysql://nova:a_big_secret@127.0.0.1/nova?charset=utf8',
        rabbit_userid       => 'nova',
        rabbit_password     => 'an_even_bigger_secret',
        image_service       => 'nova.image.glance.GlanceImageService',
        glance_api_servers  => 'localhost:9292',
        verbose             => false,
        rabbit_host         => '127.0.0.1',
      }
      class { '::nova::db::mysql':
        password => 'a_big_secret',
      }
      class { '::nova::keystone::auth':
        password => 'a_big_secret',
      }
      class { '::nova::api':
        enabled        => true,
        admin_password => 'a_big_secret',
        identity_uri   => 'http://127.0.0.1:35357/',
        osapi_v3       => true,
      }
      class { '::nova::cert': enabled => true }
      class { '::nova::client': }
      class { '::nova::conductor': enabled => true }
      class { '::nova::consoleauth': enabled => true }
      class { '::nova::cron::archive_deleted_rows': }
      class { '::nova::compute':
        enabled     => true,
        vnc_enabled => true,
      }
      class { '::nova::compute::libvirt':
        migration_support => true,
        vncserver_listen  => '0.0.0.0',
      }
      class { '::nova::scheduler': enabled => true }
      class { '::nova::vncproxy': enabled => true }
      # TODO: networking with neutron
      EOS


      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    describe port(8773) do
      it { is_expected.to be_listening.with('tcp') }
    end

    describe port(8774) do
      it { is_expected.to be_listening.with('tcp') }
    end

    describe port(8775) do
      it { is_expected.to be_listening.with('tcp') }
    end

    describe port(6080) do
      it { is_expected.to be_listening.with('tcp') }
    end

    describe cron do
      it { should have_entry('1 0 * * * nova-manage db archive_deleted_rows --max_rows 100 >>/var/log/nova/nova-rowsflush.log 2>&1').with_user('nova') }
    end

  end
end
