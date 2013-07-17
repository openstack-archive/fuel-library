# Limits module for Puppet

## Description
Module for managing pam limits in /etc/security/limits.conf

## Usage

### limits::fragment

<pre>
  limits::fragment {
    "*/soft/nofile":
      value => "1024";
    "*/hard/nofile":
      value => "8192";
  }
</pre>
