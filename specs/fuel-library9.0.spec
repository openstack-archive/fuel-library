%define name fuel-library9.0
%{!?version: %define version 9.0.0}
%{!?fuel_release: %define fuel_release 9.0}
%{!?release: %define release 1}
%{!?rhel: %define rhel 7}

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
%if 0%{rhel} < 7
BuildRequires: ruby21-rubygem-librarian-puppet-simple
%else
BuildRequires: rubygem-librarian-puppet-simple
%endif
Requires: fuel-misc python-fuelclient

%define files_source %{_builddir}/%{name}-%{version}/files
%define fuel_utils_source %{files_source}/fuel-utils
%define openstack_version mitaka-%{fuel_release}
%define predefined_upstream_modules  %{_sourcedir}/upstream_modules.tar.gz

%description

Fuel is the Ultimate Do-it-Yourself Kit for OpenStack
Purpose built to assimilate the hard-won experience of our services team, it contains the tooling, information, and support you need to accelerate time to production with OpenStack cloud. OpenStack is a very versatile and flexible cloud management platform. By exposing its portfolio of cloud infrastructure services – compute, storage, networking and other core resources — through ReST APIs, it enables a wide range of control over these services, both from the perspective of an integrated Infrastructure as a Service (IaaS) controlled by applications, as well as automated manipulation of the infrastructure itself. This architectural flexibility doesn’t set itself up magically; it asks you, the user and cloud administrator, to organize and manage a large array of configuration options. Consequently, getting the most out of your OpenStack cloud over time – in terms of flexibility, scalability, and manageability – requires a thoughtful combination of automation and configuration choices.

This package contains deployment manifests and code to execute provisioning of master and slave nodes.

%prep
%setup -cq

%build
if test -s %{predefined_upstream_modules}; then
   tar xzvf  %{predefined_upstream_modules} -C %{_builddir}/%{name}-%{version}/deployment/puppet/
else
   if test -x %{_builddir}/%{name}-%{version}/deployment/update_modules.sh; then
      bash -x %{_builddir}/%{name}-%{version}/deployment/update_modules.sh
   fi
fi

%install
mkdir -p %{buildroot}/etc/puppet/%{openstack_version}/modules/
mkdir -p %{buildroot}/etc/puppet/%{openstack_version}/manifests/
mkdir -p %{buildroot}/etc/fuel/
mkdir -p %{buildroot}/etc/monit.d/
mkdir -p %{buildroot}/etc/profile.d/
mkdir -p %{buildroot}/etc/init.d/
mkdir -p %{buildroot}/etc/fuel-utils
mkdir -p %{buildroot}/usr/bin/
mkdir -p %{buildroot}/usr/sbin/
mkdir -p %{buildroot}/usr/lib/
mkdir -p %{buildroot}/usr/share/fuel-utils
mkdir -p %{buildroot}/sbin/
mkdir -p %{buildroot}/sbin/
cp -fr %{_builddir}/%{name}-%{version}/deployment/puppet/* %{buildroot}/etc/puppet/%{openstack_version}/modules/
#LP1515988
find %{buildroot}/etc/puppet/%{openstack_version}/modules -maxdepth 2 -type d \( -name .git -or -name spec \) -exec rm -rf '{}' +
cp -f %{_builddir}/%{name}-%{version}/deployment/Puppetfile %{buildroot}/etc/puppet/%{openstack_version}/modules/
#fuel-utils
install -m 0755 %{fuel_utils_source}/fuel-utils %{buildroot}/usr/bin
install -m 0755 %{fuel_utils_source}/dockerctl %{buildroot}/usr/bin
install -m 0755 %{fuel_utils_source}/flat_yaml.py %{buildroot}/usr/bin
install -m 0644 %{fuel_utils_source}/config %{buildroot}/etc/fuel-utils/config
install -m 0644 %{fuel_utils_source}/functions.sh %{buildroot}/usr/share/fuel-utils/functions.sh
#fuel-misc
install -m 0755 %{files_source}/fuel-misc/centos_ifdown-local %{buildroot}/sbin/ifup-local
install -m 0755 %{files_source}/fuel-misc/logrotate %{buildroot}/usr/bin/fuel-logrotate
install -m 0755 %{files_source}/fuel-misc/centos_ifup-local  %{buildroot}/sbin/ifdown-local
install -m 0755 %{files_source}/fuel-misc/haproxy-status.sh %{buildroot}/usr/bin/haproxy-status
install -m 0755 %{files_source}/fuel-misc/generate_vms.sh %{buildroot}/usr/bin/generate_vms.sh
#fuel-ha-utils
install -d -m 0755 %{buildroot}/usr/lib/ocf/resource.d/fuel
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ns_haproxy %{buildroot}/usr/lib/ocf/resource.d/fuel/ns_haproxy
install -m 0755 %{files_source}/fuel-ha-utils/ocf/mysql-wss %{buildroot}/usr/lib/ocf/resource.d/fuel/mysql-wss
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ns_dns %{buildroot}/usr/lib/ocf/resource.d/fuel/ns_dns
install -m 0755 %{files_source}/fuel-ha-utils/ocf/heat-engine %{buildroot}/usr/lib/ocf/resource.d/fuel/heat-engine
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ns_ntp %{buildroot}/usr/lib/ocf/resource.d/fuel/ns_ntp
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ns_vrouter %{buildroot}/usr/lib/ocf/resource.d/fuel/ns_vrouter
install -m 0755 %{files_source}/fuel-ha-utils/ocf/neutron-ovs-agent %{buildroot}/usr/lib/ocf/resource.d/fuel/neutron-ovs-agent
install -m 0755 %{files_source}/fuel-ha-utils/ocf/neutron-metadata-agent %{buildroot}/usr/lib/ocf/resource.d/fuel/neutron-metadata-agent
install -m 0755 %{files_source}/fuel-ha-utils/ocf/neutron-dhcp-agent %{buildroot}/usr/lib/ocf/resource.d/fuel/neutron-dhcp-agent
install -m 0755 %{files_source}/fuel-ha-utils/ocf/neutron-l3-agent %{buildroot}/usr/lib/ocf/resource.d/fuel/neutron-l3-agent
#TODO(dmitryme): remove rabbitmq-server-upstream once we switch to rabbitmq-3.5.7, as it will be included here
install -m 0755 %{files_source}/fuel-ha-utils/ocf/rabbitmq %{buildroot}/usr/lib/ocf/resource.d/fuel/rabbitmq-server-upstream
install -m 0755 %{files_source}/fuel-ha-utils/ocf/rabbitmq-fuel %{buildroot}/usr/lib/ocf/resource.d/fuel/rabbitmq-server
install -m 0755 %{files_source}/fuel-ha-utils/policy/set_rabbitmq_policy %{buildroot}/usr/sbin/set_rabbitmq_policy
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ns_IPaddr2 %{buildroot}/usr/lib/ocf/resource.d/fuel/ns_IPaddr2
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ceilometer-agent-central %{buildroot}/usr/lib/ocf/resource.d/fuel/ceilometer-agent-central
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ceilometer-alarm-evaluator %{buildroot}/usr/lib/ocf/resource.d/fuel/ceilometer-alarm-evaluator
install -m 0755 %{files_source}/fuel-ha-utils/ocf/aodh-evaluator %{buildroot}/usr/lib/ocf/resource.d/fuel/aodh-evaluator
install -m 0755 %{files_source}/fuel-ha-utils/ocf/nova-compute %{buildroot}/usr/lib/ocf/resource.d/fuel/nova-compute
install -m 0755 %{files_source}/fuel-ha-utils/ocf/nova-network %{buildroot}/usr/lib/ocf/resource.d/fuel/nova-network
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ceilometer-agent-compute %{buildroot}/usr/lib/ocf/resource.d/fuel/ceilometer-agent-compute
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ocf-fuel-funcs %{buildroot}/usr/lib/ocf/resource.d/fuel/ocf-fuel-funcs
install -m 0755 %{files_source}/fuel-ha-utils/tools/galeracheck %{buildroot}/usr/bin/galeracheck
install -m 0755 %{files_source}/fuel-ha-utils/tools/swiftcheck %{buildroot}/usr/bin/swiftcheck
install -m 0644 %{files_source}/fuel-ha-utils/tools/wsrepclustercheckrc %{buildroot}/etc/wsrepclustercheckrc
install -m 0755 %{files_source}/fuel-ha-utils/tools/rabbitmq-dump-clean.py %{buildroot}/usr/sbin/rabbitmq-dump-clean.py
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
#fuel-migrate
mkdir -p %{buildroot}/etc/systemd/system
mkdir -p %{buildroot}/usr/bin
install -m 0755 %{files_source}/fuel-migrate/fuel-migrate %{buildroot}/usr/bin/fuel-migrate
install -m 0644 %{files_source}/fuel-migrate/umm-mg.service %{buildroot}/etc/systemd/system/umm-mg.service
install -m 0644 %{files_source}/fuel-migrate/umm-mg.target %{buildroot}/etc/systemd/system/umm-mg.target
#UMM
mkdir -p %{buildroot}/usr/lib/systemd/system/
cp -r %{files_source}/fuel-umm/root/* %{buildroot}/
cp -r %{files_source}/fuel-umm/systemd/* %{buildroot}/usr/lib/systemd/system/
cp -r %{files_source}/fuel-umm/rh7/* %{buildroot}/usr/lib/umm/


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

if [ "$1" = 2 ]; then
  #Try to sync deployment tasks or notify user on upgrade
  taskdir=/etc/puppet/%{openstack_version}/
  fuel rel --sync-deployment-tasks --dir "$taskdir" || \
    echo "Unable to sync tasks. Run `fuel rel --sync-deployment-tasks --dir $taskdir` to finish install." 1>&2
fi

%files
/etc/puppet/%{openstack_version}/modules/
/etc/puppet/%{openstack_version}/manifests/

%package -n fuel-utils
Summary: Fuel project utilities
Version: %{version}
Release: %{release}
Group: System Environment/Libraries
License: GPLv2
Obsoletes: fuel-dockerctl <= %{version}
Provides: fuel-utils = %{version}
URL: http://github.com/openstack/fuel-library
BuildArch: noarch
BuildRoot: %{_tmppath}/fuel-library-%{version}-%{release}

%description -n fuel-utils
This package contains a set of helpers to maintain Fuel services

%files -n fuel-utils
/usr/bin/dockerctl
/usr/bin/fuel-utils
/usr/bin/flat_yaml.py
/usr/share/fuel-utils/functions.sh

%config(noreplace) /etc/fuel-utils/config

%package -n fuel-misc
Summary: Fuel project misc utilities
Version: %{version}
Release: %{release}
Group: System Environment/Libraries
License: Apache 2.0
URL: http://github.com/openstack/fuel-library
BuildArch: noarch
BuildRoot: %{_tmppath}/fuel-library-%{version}-%{release}
Requires: socat xmlstarlet

%description -n fuel-misc
A set of scripts for Fuel deployment utility
For further information go to http://wiki.openstack.org/Fuel

%files -n fuel-misc

#fuel-misc
%defattr(-,root,root)
/sbin/ifup-local
/sbin/ifdown-local
/usr/bin/haproxy-status
/usr/bin/generate_vms.sh
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
/usr/bin/galeracheck
/usr/bin/swiftcheck
/usr/sbin/rabbitmq-dump-clean.py
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

%package -n fuel-migrate
Summary: Fuel migrate utility
Version: %{version}
Release: %{release}
Group: System Environment/Libraries
# FIXME(aglarendil): mixed license actually - need to figure out the best option
License: Apache 2.0
URL: http://github.com/openstack/fuel-library
BuildArch: noarch
Requires: libvirt-client
BuildRoot: %{_tmppath}/fuel-library-%{version}-%{release}

%description -n fuel-migrate
Script for migrate Fuel master into vm

%files -n fuel-migrate
%defattr(-,root,root)
/usr/bin/fuel-migrate
/etc/systemd/system/umm-mg.service
/etc/systemd/system/umm-mg.target
#


%package -n fuel-umm
Summary: Unified maintenance mode
Version: %{version}
Release: %{release}
Group: System Environment/Libraries
License: Apache 2.0
# Requires: upstart
URL: http://github.com/openstack/fuel-library
BuildArch: noarch
BuildRoot: %{_tmppath}/fuel-library-%{version}-%{release}

%description -n fuel-umm
Packet provide posibility to put operation system in the state when it has only
critical set of working services which are needed for basic network and disk
operations. Also node in MM state is reachable with ssh from network.

For further information go to:
https://www.mirantis.com/products/mirantis-openstack-software/documentation/

%post -n fuel-umm
/usr/lib/umm/umm-install add
%preun -n fuel-umm
/usr/lib/umm/umm-install del

%files -n fuel-umm
/etc/issue.mm
/etc/profile.d/umm.sh
#/etc/init/umm-*
/usr/lib/systemd/system/umm*
/usr/lib/umm/*
/usr/bin/umm
/var/lib/umm/.gitkeep
%config(noreplace) /etc/umm.conf

%package -n fuel-notify
Summary: Fuel disk space monitor
Version: %{version}
Release: %{release}
Group: System Environment/Libraries
# FIXME(aglarendil): mixed license actually - need to figure out the best option
License: GPLv2
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
