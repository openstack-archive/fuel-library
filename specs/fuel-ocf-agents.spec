ummary: Galera: a synchronous multi-master wsrep provider (replication engine)
Name: galera
Version: 23.2.2
Release: 6%{?dist}
Group: System Environment/Libraries
License: GPLv3
URL: http://www.codership.com/
Source0: %{name}-%{version}.tar.bz2
Requires: rubygem(netaddr)
BuildArch: x86_64
Provides: galera
Provides: config(galera)
Provides: libgalera_smm.so()(64bit)
Provides: wsrep
Provides: galera
BuildRoot: %{_tmppath}/galera-%{version}

Requires: config(galera) = 23.2.2-1.rhel5
Requires: libc.so.6()(64bit)
Requires: libc.so.6(GLIBC_2.2.5)(64bit)
Requires: libc.so.6(GLIBC_2.3.2)(64bit)
Requires: libc.so.6(GLIBC_2.3.4)(64bit)
Requires: libc.so.6(GLIBC_2.4)(64bit)
Requires: libcrypto.so.6()(64bit)
Requires: libgcc_s.so.1()(64bit)
Requires: libgcc_s.so.1(GCC_3.0)(64bit)
Requires: libm.so.6()(64bit)
Requires: libm.so.6(GLIBC_2.2.5)(64bit)
Requires: libpthread.so.0()(64bit)
Requires: libpthread.so.0(GLIBC_2.2.5)(64bit)
Requires: libpthread.so.0(GLIBC_2.3.2)(64bit)
Requires: librt.so.1()(64bit)
Requires: librt.so.1(GLIBC_2.2.5)(64bit)
Requires: libssl.so.6()(64bit)
Requires: libstdc++.so.6()(64bit)
Requires: libstdc++.so.6(CXXABI_1.3)(64bit)
Requires: libstdc++.so.6(GLIBCXX_3.4)(64bit)
Requires: rpmlib(CompressedFileNames) <= 3.0.4-1
Requires: rpmlib(PayloadFilesHavePrefix) <= 4.0-1
Requires: rtld(GNU_HASH)


%description

Galera is a fast synchronous multimaster wsrep provider (replication engine)
for transactional databases and similar applications. For more information
about wsrep API see http://launchpad.net/wsrep. For a description of Galera
replication engine see http://www.codership.com.

#%package doc
#Summary: Documentation for %{name}
#Group: Documentation
#Requires: %{name} = %{version}-%{release}
#BuildArch: noarch
#
#%description doc
#Documentation for %{name}

%prep
%setup -q


%install
mkdir -p %{buildroot}/etc/
mkdir -p %{buildroot}/usr/
#install -d etc/* %{buildroot}/usr/
pwd
cp -fr etc/* %{buildroot}/etc/
cp -fr usr/* %{buildroot}/usr/



%files
/etc/init.d/garb
/etc/sysconfig/garb
/usr/share/doc/galera/*
/usr/bin/garbd
/usr/lib64/galera/libgalera_smm.so


%changelog
* Tue Sep 10 2013 rvyalov <rvyalov@mirantis.com> - 23.2.2-5
- Create spec
