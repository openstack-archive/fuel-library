# $Id$

file {
    "/tmp/createatest": ensure => file, mode => 755;
    "/tmp/createbtest": ensure => file, mode => 755
}

file {
    "/tmp/createctest": ensure => file;
    "/tmp/createdtest": ensure => file;
}
