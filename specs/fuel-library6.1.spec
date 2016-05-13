%define name fuel-library6.1
%{!?version: %define version 6.1.0}
%{!?release: %define release 1}

Summary: Fuel-Library: a set of deployment manifests of Fuel for OpenStack
Name: %{name}
Version: %{version}
Release: %{release}
Group: System Environment/Libraries
License: GPLv2
URL: http://github.com/openstack/fuel-library
Source0: %{name}-%{version}.tar.gz
Provides: fuel-library
BuildArch: noarch
BuildRoot: %{_tmppath}/fuel-library-%{version}-%{release}
Requires: fuel-misc

%define files_source %{_builddir}/%{name}-%{version}/files
%define dockerctl_source %{files_source}/fuel-docker-utils
%define openstack_version 2014.2.2-6.1

%description

Fuel is the Ultimate Do-it-Yourself Kit for OpenStack
Purpose built to assimilate the hard-won experience of our services team, it contains the tooling, information, and support you need to accelerate time to production with OpenStack cloud. OpenStack is a very versatile and flexible cloud management platform. By exposing its portfolio of cloud infrastructure services – compute, storage, networking and other core resources — through ReST APIs, it enables a wide range of control over these services, both from the perspective of an integrated Infrastructure as a Service (IaaS) controlled by applications, as well as automated manipulation of the infrastructure itself. This architectural flexibility doesn’t set itself up magically; it asks you, the user and cloud administrator, to organize and manage a large array of configuration options. Consequently, getting the most out of your OpenStack cloud over time – in terms of flexibility, scalability, and manageability – requires a thoughtful combination of automation and configuration choices.

This package contains deployment manifests and code to execute provisioning of master and slave nodes.

%prep
%setup -cq

%install
mkdir -p %{buildroot}/etc/puppet/%{openstack_version}/modules/
mkdir -p %{buildroot}/etc/puppet/%{openstack_version}/manifests/
mkdir -p %{buildroot}/etc/fuel/
mkdir -p %{buildroot}/etc/monit.d/
mkdir -p %{buildroot}/etc/profile.d/
mkdir -p %{buildroot}/etc/init.d/
mkdir -p %{buildroot}/etc/dockerctl
mkdir -p %{buildroot}/usr/bin/
mkdir -p %{buildroot}/usr/lib/
mkdir -p %{buildroot}/usr/share/dockerctl
mkdir -p %{buildroot}/sbin/
mkdir -p %{buildroot}/sbin/
cp -fr %{_builddir}/%{name}-%{version}/deployment/puppet/* %{buildroot}/etc/puppet/%{openstack_version}/modules/
#FUEL DOCKERCTL UTILITY
install -m 0644 %{dockerctl_source}/dockerctl-alias.sh %{buildroot}/etc/profile.d/dockerctl.sh
install -m 0755 %{dockerctl_source}/dockerctl %{buildroot}/usr/bin
install -m 0755 %{dockerctl_source}/get_service_credentials.py %{buildroot}/usr/bin
install -m 0644 %{dockerctl_source}/dockerctl_config %{buildroot}/etc/dockerctl/config
install -m 0644 %{dockerctl_source}/functions.sh %{buildroot}/usr/share/dockerctl/functions
#fuel-misc
install -m 0755 %{files_source}/fuel-misc/centos_ifdown-local %{buildroot}/sbin/ifup-local
install -m 0755 %{files_source}/fuel-misc/logrotate %{buildroot}/usr/bin/fuel-logrotate
install -m 0755 %{files_source}/fuel-misc/centos_ifup-local  %{buildroot}/sbin/ifdown-local
install -m 0755 %{files_source}/fuel-misc/haproxy-status.sh %{buildroot}/usr/bin/haproxy-status
#fuel-ha-utils
install -d -m 0755 %{buildroot}/usr/lib/ocf/resource.d/fuel
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ns_haproxy %{buildroot}/usr/lib/ocf/resource.d/fuel/ns_haproxy
install -m 0755 %{files_source}/fuel-ha-utils/ocf/mysql-wss %{buildroot}/usr/lib/ocf/resource.d/fuel/mysql-wss
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ns_dns %{buildroot}/usr/lib/ocf/resource.d/fuel/ns_dns
install -m 0755 %{files_source}/fuel-ha-utils/ocf/heat_engine_centos %{buildroot}/usr/lib/ocf/resource.d/fuel/heat-engine
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ns_ntp %{buildroot}/usr/lib/ocf/resource.d/fuel/ns_ntp
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ns_vrouter %{buildroot}/usr/lib/ocf/resource.d/fuel/ns_vrouter
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ocf-neutron-ovs-agent %{buildroot}/usr/lib/ocf/resource.d/fuel/ocf-neutron-ovs-agent
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ocf-neutron-metadata-agent %{buildroot}/usr/lib/ocf/resource.d/fuel/ocf-neutron-metadata-agent
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ocf-neutron-dhcp-agent %{buildroot}/usr/lib/ocf/resource.d/fuel/ocf-neutron-dhcp-agent
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ocf-neutron-l3-agent %{buildroot}/usr/lib/ocf/resource.d/fuel/ocf-neutron-l3-agent
install -m 0755 %{files_source}/fuel-ha-utils/ocf/rabbitmq %{buildroot}/usr/lib/ocf/resource.d/fuel/rabbitmq-server-upstream
install -m 0755 %{files_source}/fuel-ha-utils/ocf/rabbitmq-fuel %{buildroot}/usr/lib/ocf/resource.d/fuel/rabbitmq-server
install -m 0755 %{files_source}/fuel-ha-utils/policy/set_rabbitmq_policy.sh %{buildroot}/usr/sbin/set_rabbitmq_policy
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ns_IPaddr2 %{buildroot}/usr/lib/ocf/resource.d/fuel/ns_IPaddr2
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ceilometer-agent-central %{buildroot}/usr/lib/ocf/resource.d/fuel/ceilometer-agent-central
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ceilometer-alarm-evaluator %{buildroot}/usr/lib/ocf/resource.d/fuel/ceilometer-alarm-evaluator
install -m 0755 %{files_source}/fuel-ha-utils/tools/q-agent-cleanup.py %{buildroot}/usr/bin/q-agent-cleanup.py
install -m 0755 %{files_source}/fuel-ha-utils/tools/clustercheck %{buildroot}/usr/bin/clustercheck
install -m 0755 %{files_source}/fuel-ha-utils/tools/swiftcheck %{buildroot}/usr/bin/swiftcheck
install -m 0644 %{files_source}/fuel-ha-utils/tools/wsrepclustercheckrc %{buildroot}/etc/wsrepclustercheckrc
install -m 0755 %{files_source}/rabbit-fence/rabbit-fence.py %{buildroot}/usr/bin/rabbit-fence.py
install -m 0755 %{files_source}/rabbit-fence/rabbit-fence.init %{buildroot}/etc/init.d/rabbit-fence
#FIXME - may be we need to put this also into packages
#install -m 0755 TEMPLATE /usr/local/bin/puppet-pull
#install -m 0755 -d deployment/puppet/sahara/templates /usr/share/sahara/templates
#install -m 0755 deployment/puppet/sahara/create_templates.sh /usr/share/sahara/templates/create_templates.sh
#install -m 0755 TEMPLATE /usr/local/bin/swift-rings-rebalance.sh
#install -m 0755 TEMPLATE /usr/local/bin/swift-rings-sync.sh
#fuel-notify
install -m 0644 %{files_source}/fuel-notify/monit-free-space.conf %{buildroot}/etc/monit.d/monit-free-space.conf
install -m 0644 %{files_source}/fuel-notify/free_disk_space_check.yaml %{buildroot}/etc/fuel/free_disk_space_check.yaml
install -m 0755 %{files_source}/fuel-notify/fuel_notify.py %{buildroot}/usr/bin/fuel_notify.py

%post -p /bin/bash
#Update puppet manifests symlinks to the latest version
for i in modules manifests
do
  if [ -L /etc/puppet/${i} ]
  then
     unlink /etc/puppet/${i}
  elif  [ -d /etc/puppet/${i} ]
  then
     mv /etc/puppet/${i} /etc/puppet/${i}.old
  fi
  ln -s /etc/puppet/%{openstack_version}/${i} /etc/puppet/${i}
done

%files
/etc/puppet/%{openstack_version}/modules/
/etc/puppet/%{openstack_version}/manifests/

%package -n fuel-dockerctl
Summary: Fuel project utilities for Docker container management tool
Version: %{version}
Release: %{release}
Group: System Environment/Libraries
License: GPLv2
Provides: fuel-docker-utils
URL: http://github.com/openstack/fuel-library
BuildArch: noarch
BuildRoot: %{_tmppath}/fuel-library-%{version}-%{release}

%description -n fuel-dockerctl
This package contains a set of helpers to manage docker containers
during Fuel All-in-One deployment toolkit installation

%files -n fuel-dockerctl
/etc/profile.d/dockerctl.sh
/usr/bin/dockerctl
/usr/bin/get_service_credentials.py
/usr/share/dockerctl/functions

%config(noreplace) /etc/dockerctl/config

%package -n fuel-misc
Summary: Fuel project misc utilities
Version: %{version}
Release: %{release}
Group: System Environment/Libraries
License: Apache 2.0
URL: http://github.com/openstack/fuel-library
BuildArch: noarch
BuildRoot: %{_tmppath}/fuel-library-%{version}-%{release}

%description -n fuel-misc
A set of scripts for Fuel deployment utility
For further information go to http://wiki.openstack.org/Fuel

%files -n fuel-misc

#fuel-misc
%defattr(-,root,root)
/sbin/ifup-local
/sbin/ifdown-local
/usr/bin/haproxy-status
/usr/bin/fuel-logrotate
%package -n fuel-ha-utils
Summary: Fuel project HA utilities
Version: %{version}
Release: %{release}
Group: System Environment/Libraries
# FIXME(aglarendil): mixed license actually - need to figure out the best option
License: GPLv2
Requires: python-keystoneclient
Requires: python-neutronclient
URL: http://github.com/openstack/fuel-library
BuildArch: noarch
BuildRoot: %{_tmppath}/fuel-library-%{version}-%{release}

%description -n fuel-ha-utils
A set of scripts for Fuel deployment utility HA deployment
For further information go to http://wiki.openstack.org/Fuel

%files -n fuel-ha-utils
%defattr(-,root,root)
/usr/lib/ocf/resource.d/fuel
/usr/bin/q-agent-cleanup.py
/usr/bin/clustercheck
/usr/bin/swiftcheck
/usr/sbin/set_rabbitmq_policy
%config(noreplace) /etc/wsrepclustercheckrc
#

%package -n fuel-rabbit-fence
Summary: Fuel project RabbitMQ fencing utility
Version: %{version}
Release: %{release}
Group: System Environment/Libraries
# FIXME(aglarendil): mixed license actually - need to figure out the best option
License: Apache 2.0
URL: http://github.com/openstack/fuel-library
BuildArch: noarch
Requires: dbus
Requires: dbus-python
Requires: pygobject2
Requires: python-daemon
BuildRoot: %{_tmppath}/fuel-library-%{version}-%{release}

%description -n fuel-rabbit-fence
A set of scripts for Fuel deployment utility HA RabbitMQ deployment
For further information go to http://wiki.openstack.org/Fuel

%files -n fuel-rabbit-fence
%defattr(-,root,root)
/usr/bin/rabbit-fence.py
/etc/init.d/rabbit-fence
#

%package -n fuel-notify
Summary: Fuel disk space monitor
Version: %{version}
Release: %{release}
Group: System Environment/Libraries
# FIXME(aglarendil): mixed license actually - need to figure out the best option
License: GPLv2
Requires: monit
Requires: python-six
Requires: PyYAML
Requires: python-fuelclient
URL: http://github.com/openstack/fuel-library
BuildArch: noarch
BuildRoot: %{_tmppath}/fuel-library-%{version}-%{release}

%description -n fuel-notify
Disk space monitoring and notification for Fuel
based on monit.

For further information go to http://wiki.openstack.org/Fuel

%files -n fuel-notify

#fuel-misc
%defattr(-,root,root)
/usr/bin/fuel_notify.py
%config(noreplace) /etc/fuel/free_disk_space_check.yaml
%config(noreplace) /etc/monit.d/monit-free-space.conf

%clean
rm -rf ${buildroot}

%changelog
* Tue Sep 10 2013 Vladimir Kuklin <vkuklin@mirantis.com> - 6.1
- Create spec
