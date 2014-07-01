#!/bin/sh

mysql -e 'show variables where Variable_Name like "wsrep_%" and Variable_Name not like "wsrep_provider_options"'
mysql -e 'show status like "wsrep_%"'
