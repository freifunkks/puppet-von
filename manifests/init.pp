class vpn(
  $inet_dev='eth0',
  $ip_addr,
  $vpn_nr
) {
  apt::source { 'universe-factory':
    comment  => 'This repo includes a fastd release',
    location => 'http://repo.universe-factory.net/debian/',
    release  => 'jessie',
    repos    => 'main',
  }

  # install gateway packages
  package { ['bridge-utils', 'fastd', 'openvpn', 'batctl']:
    ensure => installed,
  }

  # fastd configuration
  file { '/etc/fastd/fastd.conf':
    ensure  => present,
    content => template('vpn/fastd.conf.erb'),
    mode    => 755,
  }
}