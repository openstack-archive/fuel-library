INSERT INTO `regexps` (`regexpid`,`name`,`test_string`) values ('10','Block devices for discovery','vda');
INSERT INTO `expressions` (`expressionid`,`regexpid`,`expression`,`expression_type`,`exp_delimiter`,`case_sensitive`) values ('10','10','^(vd.|sd.)$','3',',','0');
