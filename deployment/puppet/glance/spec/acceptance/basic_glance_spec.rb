require 'spec_helper_acceptance'

describe 'glance class' do

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
        }
        default: {
          fail("Unsupported osfamily (${::osfamily})")
        }
      }

      class { '::mysql::server': }

      # Keystone resources, needed by Glance to run
      class { '::keystone::db::mysql':
        # https://bugs.launchpad.net/puppet-keystone/+bug/1446375
        collate  => 'utf8_general_ci',
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

      # Glance resources
      include ::glance
      include ::glance::client
      class { '::glance::db::mysql':
        # https://bugs.launchpad.net/puppet-glance/+bug/1446375
        collate  => 'utf8_general_ci',
        password => 'a_big_secret',
      }
      class { '::glance::keystone::auth':
        password => 'a_big_secret',
      }
      class { '::glance::api':
        database_connection => 'mysql://glance:a_big_secret@127.0.0.1/glance?charset=utf8',
        verbose             => false,
        keystone_password   => 'a_big_secret',
      }
      class { '::glance::registry':
        database_connection => 'mysql://glance:a_big_secret@127.0.0.1/glance?charset=utf8',
        verbose             => false,
        keystone_password   => 'a_big_secret',
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

  end
end
