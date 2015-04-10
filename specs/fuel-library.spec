Summary: Fuel-Library: a set of deployment manifests of Fuel for OpenStack 
Name: fuel-library6.1
Version: 6.1
Release: 1
Group: System Environment/Libraries
License: GPLv2
URL: http://github.com/stackforge/fuel-library
Source0: %{name}-%{version}-%{release}.tar.gz
Provides: fuel-library
BuildArch: noarch
BuildRoot: %{_tmppath}/fuel-library-%{version}-%{release}

%define files_source %{_builddir}/%{name}-%{version}/files
%define dockerctl_source %{files_source}/fuel-docker-utils

%description

Fuel is the Ultimate Do-it-Yourself Kit for OpenStack
Purpose built to assimilate the hard-won experience of our services team, it contains the tooling, information, and support you need to accelerate time to production with OpenStack cloud. OpenStack is a very versatile and flexible cloud management platform. By exposing its portfolio of cloud infrastructure services – compute, storage, networking and other core resources — through ReST APIs, it enables a wide range of control over these services, both from the perspective of an integrated Infrastructure as a Service (IaaS) controlled by applications, as well as automated manipulation of the infrastructure itself. This architectural flexibility doesn’t set itself up magically; it asks you, the user and cloud administrator, to organize and manage a large array of configuration options. Consequently, getting the most out of your OpenStack cloud over time – in terms of flexibility, scalability, and manageability – requires a thoughtful combination of automation and configuration choices.

This package contains deployment manifests and code to execute provisioning of master and slave nodes.

%prep
%setup -cq

%install
mkdir -p %{buildroot}/etc/puppet/2014.2-%{version}/modules/
mkdir -p %{buildroot}/etc/puppet/2014.2-%{version}/manifests/
mkdir -p %{buildroot}/etc/profile.d/
mkdir -p %{buildroot}/etc/dockerctl
mkdir -p %{buildroot}/usr/local/bin/
mkdir -p %{buildroot}/usr/bin/
mkdir -p %{buildroot}/usr/lib/
mkdir -p %{buildroot}/usr/share/dockerctl
mkdir -p %{buildroot}/sbin/
cp -fr %{_builddir}/%{name}-%{version}/deployment/puppet/* %{buildroot}/etc/puppet/2014.2-%{version}/modules/
#FUEL DOCKERCTL UTILITY
install -m 0644 %{dockerctl_source}/dockerctl-alias.sh %{buildroot}/etc/profile.d/
install -m 0755 %{dockerctl_source}/dockerctl %{buildroot}/usr/bin
install -m 0755 %{dockerctl_source}/get_service_credentials.py %{buildroot}/usr/bin
install -m 0644 %{dockerctl_source}/dockerctl_config %{buildroot}/etc/dockerctl/config
install -m 0644 %{dockerctl_source}/functions.sh %{buildroot}/usr/share/dockerctl/
#fuel-misc
install -m 0755 %{files_source}/fuel-misc/centos_ifdown-local %{buildroot}/sbin/ifup-local
install -m 0755 %{files_source}/fuel-misc/centos_ifup-local  %{buildroot}/sbin/ifdown-local
install -m 0755 %{files_source}/fuel-misc/haproxy-status.sh %{buildroot}/usr/local/bin/haproxy-status
#fuel-ha-utils
install -d -m 0755 %{buildroot}/usr/lib/ocf/resource.d/fuel
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ns_haproxy %{buildroot}/usr/lib/ocf/resource.d/fuel/ns_haproxy
install -m 0755 %{files_source}/fuel-ha-utils/ocf/mysql-wss %{buildroot}/usr/lib/ocf/resource.d/fuel/mysql-wss
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ns_dns %{buildroot}/usr/lib/ocf/resource.d/fuel/ns_dns
install -m 0755 %{files_source}/fuel-ha-utils/ocf/heat_engine_centos %{buildroot}/usr/lib/ocf/resource.d/fuel/heat-engine
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ns_ntp %{buildroot}/usr/lib/ocf/resource.d/fuel/ns_ntp
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ocf-neutron-ovs-agent %{buildroot}/usr/lib/ocf/resource.d/fuel/ocf-neutron-ovs-agent
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ocf-neutron-metadata-agent %{buildroot}/usr/lib/ocf/resource.d/fuel/ocf-neutron-metadata-agent
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ocf-neutron-dhcp-agent %{buildroot}/usr/lib/ocf/resource.d/fuel/ocf-neutron-dhcp-agent
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ocf-neutron-l3-agent %{buildroot}/usr/lib/ocf/resource.d/fuel/ocf-neutron-l3-agent
install -m 0755 %{files_source}/fuel-ha-utils/ocf/rabbitmq %{buildroot}/usr/lib/ocf/resource.d/fuel/rabbitmq-server
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ns_IPaddr2 %{buildroot}/usr/lib/ocf/resource.d/fuel/ns_IPaddr2
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ceilometer-agent-central %{buildroot}/usr/lib/ocf/resource.d/fuel/ceilometer-agent-central
install -m 0755 %{files_source}/fuel-ha-utils/ocf/ceilometer-alarm-evaluator %{buildroot}/usr/lib/ocf/resource.d/fuel/ceilometer-alarm-evaluator
install -m 0755 %{files_source}/fuel-ha-utils/tools/q-agent-cleanup.py %{buildroot}/usr/bin/q-agent-cleanup.py
install -m 0755 %{files_source}/fuel-ha-utils/tools/clustercheck %{buildroot}/usr/local/bin/clustercheck
install -m 0644 %{files_source}/fuel-ha-utils/tools/wsrepclustercheckrc %{buildroot}/etc/wsrepclustercheckrc
#FIXME - may be we need to put this also into packages
#install -m 0755 TEMPLATE /usr/local/bin/puppet-pull
#install -m 0755 -d deployment/puppet/sahara/templates /usr/share/sahara/templates
#install -m 0755 deployment/puppet/sahara/create_templates.sh /usr/share/sahara/templates/create_templates.sh
#install -m 0755 TEMPLATE /usr/local/bin/swift-rings-rebalance.sh
#install -m 0755 TEMPLATE /usr/local/bin/swift-rings-sync.sh

%post
#!/bin/bash
for i in modules manifests
do
  if [ -L /etc/puppet/${i} ]
  then
     unlink /etc/puppet/${i}
  elif  [ -d /etc/puppet/${i} ]
  then
     mv /etc/puppet/${i} /etc/puppet/${i}.old
  fi
ln -s /etc/puppet/2014.2-%{version}/${i} /etc/puppet/${i}
done

%files
/etc/puppet/2014.2-%{version}/modules/
/etc/puppet/2014.2-%{version}/manifests/

%package -n fuel-docker-utils6.1
Summary: Fuel project utilities for Docker container management tool
Version: 6.1
Release: 1
Group: System Environment/Libraries
License: GPLv2
Provides: fuel-docker-utils
URL: http://github.com/stackforge/fuel-library
BuildArch: noarch
BuildRoot: %{_tmppath}/fuel-library-%{version}-%{release}

%description -n fuel-docker-utils6.1
This package contains a set of helpers to manage docker containers
during Fuel All-in-One deployment toolkit installation

%files -n fuel-docker-utils6.1
/etc/profile.d/dockerctl-alias.sh
/usr/bin/dockerctl
/usr/bin/get_service_credentials.py
/usr/share/dockerctl/functions.sh
%config(noreplace) /etc/dockerctl/config

%package -n fuel-misc6.1
Summary: Fuel project misc utilities
Version: 6.1
Release: 1
Group: System Environment/Libraries
License: Apache 2.0
URL: http://github.com/stackforge/fuel-library
BuildArch: noarch
Provides: fuel-misc
BuildRoot: %{_tmppath}/fuel-library-%{version}-%{release}

%description -n fuel-misc6.1
A set of scripts for Fuel deployment utility
For further information go to http://wiki.openstack.org/Fuel

%files -n fuel-misc6.1

#fuel-misc
%defattr(-,root,root)
/sbin/ifup-local
/sbin/ifdown-local
/usr/local/bin/haproxy-status

%package -n fuel-ha-utils6.1
Summary: Fuel project HA utilities
Version: 6.1
Release: 1
Group: System Environment/Libraries
# FIXME(aglarendil): mixed license actually - need to figure out the best option
License: GPLv2
URL: http://github.com/stackforge/fuel-library
BuildArch: noarch
Provides: fuel-ha-utils
BuildRoot: %{_tmppath}/fuel-library-%{version}-%{release}

%description -n fuel-ha-utils6.1
A set of scripts for Fuel deployment utility HA deployment
For further information go to http://wiki.openstack.org/Fuel

%files -n fuel-ha-utils6.1
%defattr(-,root,root)
/usr/lib/ocf/resource.d/fuel
/usr/bin/q-agent-cleanup.py
/usr/local/bin/clustercheck
%config(noreplace) /etc/wsrepclustercheckrc
#




%clean
rm -rf ${buildroot}

%changelog
* Tue Sep 10 2013 Vladimir Kuklin <vkuklin@mirantis.com> - 6.1
- Create spec
