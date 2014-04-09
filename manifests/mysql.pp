# Public: Install the powerdns mysql backend
#
# package  - which package to install
# ensure   - ensure postgres backend to be present or absent
# source   - where to get the package from
# user     - which user powerdns should connect as
# password - which password to use with user
# host     - host to connect to
# port     - port to connect to
# dbname   - which database to use
# dnssec   - enable or disable dnssec either yes or no
#
class powerdns::mysql(
  $package  = $powerdns::params::package_mysql,
  $ensure   = 'present',
  $source   = '',
  $user     = '',
  $password = '',
  $host     = 'localhost',
  $port     = '3306',
  $dbname   = 'pdns',
  $dnssec   = 'yes'
) inherits powerdns::params {

  $package_source = $source ? {
    ''      => undef,
    default => $source
  }

  $package_provider = $source ? {
    ''      => undef,
    default => $powerdns::params::package_provider
  }

  package { $package:
    ensure   => $ensure,
    require  => Package[$powerdns::params::package],
    provider => $package_provider,
    source   => $package_source
  }

  file { $powerdns::params::mysql_cfg_path:
    ensure  => $ensure,
    owner   => root,
    group   => root,
    mode    => '0600',
    content => template('powerdns/pdns.mysql.local.erb'),
    notify  => Service['pdns'],
    require => [ Package[$powerdns::params::package], Package[$package] ]
  }
  
  $mysql_schema = $dnssec ? {
    /(yes|true)/ => 'puppet:///modules/powerdns/mysql_schema.dnssec.sql',
    default      => 'puppet:///modules/powerdns/mysql_schema.sql'
  }

  file { '/tmp/pdns_mysql_schema.sql': 
    ensure => $ensure,
    source => $mysql_schema,
    notify => Exec['load pdns mysql schema'],
  }
  
  exec { 'load pdns mysql schema': 
    command => "/usr/bin/mysql -u${user} -p${password} -h${host} ${dbname} < /tmp/pdns_mysql_schema.sql",
    onlyif  => "/usr/bin/test $(mysql -u${user} -p${password} -h${host} ${dbname} -e 'show tables' | wc -l ) -gt 0 "
  }

}
