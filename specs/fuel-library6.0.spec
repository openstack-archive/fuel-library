%define name fuel-library6.0
%{!?version: %define version 6.0.0}
%{!?release: %define release 2}

Summary: Fuel-Library: a set of deployment manifests of Fuel for OpenStack
Name: %{name}
Version: %{version}
Release: %{release}
Group: System Environment/Libraries
License: GPLv2
URL: http://github.com/stackforge/fuel-library
Source0: %{name}-%{version}.tar.gz
Provides: fuel-library
BuildArch: noarch
BuildRoot: %{_tmppath}/fuel-library-%{version}-%{release}

%define files_source %{_builddir}/%{name}-%{version}/deployment/puppet

%define openstack_version 2014.2-6.0

%description

Fuel is the Ultimate Do-it-Yourself Kit for OpenStack
Purpose built to assimilate the hard-won experience of our services team, it contains the tooling, information, and support you need to accelerate time to production with OpenStack cloud. OpenStack is a very versatile and flexible cloud management platform. By exposing its portfolio of cloud infrastructure services – compute, storage, networking and other core resources — through ReST APIs, it enables a wide range of control over these services, both from the perspective of an integrated Infrastructure as a Service (IaaS) controlled by applications, as well as automated manipulation of the infrastructure itself. This architectural flexibility doesn’t set itself up magically; it asks you, the user and cloud administrator, to organize and manage a large array of configuration options. Consequently, getting the most out of your OpenStack cloud over time – in terms of flexibility, scalability, and manageability – requires a thoughtful combination of automation and configuration choices.

This package contains deployment manifests and code to execute provisioning of master and slave nodes.

%prep
%setup -cq

%install
mkdir -p %{buildroot}/etc/puppet/%{openstack_version}/modules/
mkdir -p %{buildroot}/etc/puppet/%{openstack_version}/manifests/
mkdir -p %{buildroot}/usr/bin/
mkdir -p %{buildroot}/usr/lib/
cp -fr %{_builddir}/%{name}-%{version}/deployment/puppet/* %{buildroot}/etc/puppet/%{openstack_version}/modules/

#fuel-ha-utils
install -d -m 0755 %{buildroot}/usr/lib/ocf/resource.d/mirantis
install -m 0755 %{files_source}/cluster/files/ns_haproxy %{buildroot}/usr/lib/ocf/resource.d/mirantis/ns_haproxy
install -m 0755 %{files_source}/cluster/files/ns_IPaddr2 %{buildroot}/usr/lib/ocf/resource.d/mirantis/ns_IPaddr2
install -m 0755 %{files_source}/cluster/files/ocf/neutron-agent-ovs %{buildroot}/usr/lib/ocf/resource.d/mirantis/neutron-agent-ovs
install -m 0755 %{files_source}/cluster/files/ocf/neutron-agent-metadata %{buildroot}/usr/lib/ocf/resource.d/mirantis/neutron-agent-metadata
install -m 0755 %{files_source}/cluster/files/ocf/neutron-agent-dhcp %{buildroot}/usr/lib/ocf/resource.d/mirantis/neutron-agent-dhcp
install -m 0755 %{files_source}/cluster/files/ocf/neutron-agent-l3 %{buildroot}/usr/lib/ocf/resource.d/mirantis/neutron-agent-l3

install -m 0755 %{files_source}/cluster/files/q-agent-cleanup.py %{buildroot}/usr/bin/q-agent-cleanup.py

install -m 0755 %{files_source}/galera/files/ocf/mysql-wss %{buildroot}/usr/lib/ocf/resource.d/mirantis/mysql-wss

install -m 0755 %{files_source}/heat/templates/heat_engine_centos.ocf.erb %{buildroot}/usr/lib/ocf/resource.d/mirantis/heat-engine

install -m 0755 %{files_source}/nova/files/ocf/rabbitmq %{buildroot}/usr/lib/ocf/resource.d/mirantis/rabbitmq-server

install -m 0755 %{files_source}/cluster/files/ocf/ceilometer-agent-central %{buildroot}/usr/lib/ocf/resource.d/mirantis/ceilometer-agent-central
install -m 0755 %{files_source}/cluster/files/ocf/ceilometer-alarm-evaluator %{buildroot}/usr/lib/ocf/resource.d/mirantis/ceilometer-alarm-evaluator

%files
/etc/puppet/%{openstack_version}/modules/
/etc/puppet/%{openstack_version}/manifests/

%package -n fuel-ha-utils6.0
Summary: Fuel project HA utilities
Version: %{version}
Release: %{release}
Group: System Environment/Libraries
# FIXME(aglarendil): mixed license actually - need to figure out the best option
License: GPLv2
Requires: python-keystoneclient
Requires: python-neutronclient
URL: http://github.com/stackforge/fuel-library
BuildArch: noarch
BuildRoot: %{_tmppath}/fuel-library-%{version}-%{release}

%description -n fuel-ha-utils6.0
A set of scripts for Fuel deployment utility HA deployment
For further information go to http://wiki.openstack.org/Fuel

%files -n fuel-ha-utils6.0
%defattr(-,root,root)
/usr/lib/ocf/resource.d/mirantis
/usr/bin/q-agent-cleanup.py

%clean
rm -rf ${buildroot}

%changelog
* Wed Jun 28 2015 Alexander Nevenchannyy <anevenchannyy@mirantis.com> - 6.0
- MOS-6.0-MU1

* Wed Jun 17 2015 Alexander Nevenchannyy <anevenchannyy@mirantis.com> - 6.0
- Create spec
