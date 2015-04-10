Summary: Fuel-Library: a set of deployment manifests of Fuel for OpenStack 
Name: fuel-library-6.1
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

%package -n fuel-docker-utils
Summary: Fuel project utilities for Docker container management tool
Version: 6.1
Release: 1
Group: System Environment/Libraries
License: GPLv2
URL: http://github.com/stackforge/fuel-library
BuildArch: noarch
BuildRoot: %{_tmppath}/fuel-library-%{version}-%{release}

%description -n fuel-docker-utils
This package contains a set of helpers to manage docker containers
during Fuel All-in-One deployment toolkit installation

%files -n fuel-docker-utils
/etc/profile.d/dockerctl-alias.sh
/usr/bin/dockerctl
/usr/bin/get_service_credentials.py
/usr/share/dockerctl/functions.sh
%config(noreplace) /etc/dockerctl/config



%clean
rm -rf ${buildroot}

%changelog
* Tue Sep 10 2013 Vladimir Kuklin <vkuklin@mirantis.com> - 6.1
- Create spec
