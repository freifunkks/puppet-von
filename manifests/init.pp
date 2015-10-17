class vpn(
  $inet_dev='eth0',
  $ip_addr,
  $ip_base,
  $ip_mask='24',
  $vpn_nr,
  $secret_key
) {
  apt::source { 'universe-factory':
    comment  => 'This repo includes a fastd release',
    location => 'http://repo.universe-factory.net/debian/',
    release  => 'sid',
    repos    => 'main',
  }

  Package {
    install_options => ['--no-install-recommends', '--force-yes'],
  }

  # install gateway packages
  package { ['bridge-utils', 'fastd', 'openvpn', 'batctl', 'batman-adv-dkms', 'radvd', 'tayga']:
    ensure => installed,
  }
  exec {
    'enable_batman_mod':
      command => 'echo batman-adv >> /etc/modules',
      unless  => 'grep -q ^batman-adv /etc/modules',
      path    => ['/bin', '/usr/sbin'],
  }

  # script we use to change the NAT mapping
  file { '/etc/cron.daily/roulette':
    ensure  => present,
    content => template('vpn/roulette.erb'),
    mode    => 755,
  }

  # ipfilter commands and e.g. NAT configuration
  file { '/etc/rc.local':
    ensure  => present,
    content => template('vpn/rc.local.erb'),
    mode    => 755,
  }

  # add reverseroute table
  file { '/etc/iproute2/rt_tables':
    ensure => present,
    content => template('vpn/rt_tables.erb'),
    mode    => 755,
  }

  # radvd configuration
  file { '/etc/radvd.conf':
    ensure  => present,
    mode    => '0600',
    content => template('vpn/radvd.conf.erb'),
  }

  # tayga configuration
  file { '/etc/tayga.conf':
    ensure  => present,
    mode    => '0600',
    content => template('vpn/tayga.conf.erb'),
  }

  # fastd configuration
  file { '/etc/fastd/vpn/fastd.conf':
    ensure  => present,
    mode    => '0600',
    content => template('vpn/fastd/fastd.conf.erb'),
  }

  file { '/etc/fastd/vpn/secret.conf':
    ensure  => present,
    mode    => '0600',
    content => inline_template('secret "<%= @secret_key.chomp %>";');
  }

  file { '/etc/fastd/vpn/peers/vpn1':
    ensure  => present,
    mode    => '0600',
    content => template('vpn/fastd/peers/vpn1.erb'),
  }

  # openvpn configuration
  file { '/etc/openvpn/uplink/up.sh':
    ensure  => present,
    mode    => '0600',
    content => template('vpn/openvpn/up.sh.erb'),
  }

  file { '/etc/openvpn/uplink/routeup.sh':
    ensure  => present,
    mode    => '0600',
    content => template('vpn/openvpn/routeup.sh.erb'),
  }

  file { '/etc/openvpn/uplink/down.sh':
    ensure  => present,
    mode    => '0600',
    content => template('vpn/openvpn/down.sh.erb'),
  }

  # Start services
  service { 'radvd':
    ensure   => running,
    provider => init,
    enable   => true
  }

  service { 'tayga':
    ensure   => running,
    provider => init,
    enable   => true
  }

  service { 'fastd':
    ensure   => running,
    provider => init,
    enable   => true
  }

  service { 'batmand':
    ensure   => running,
    provider => init,
    enable   => true
  }

  sysctl { 'net.ipv4.ip_forward': value => '1' }

  # change conntrack timeouts to prevent droped packages
  sysctl { 'net.netfilter.nf_conntrack_generic_timeout': value => '120' }
  sysctl { 'net.ipv4.netfilter.ip_conntrack_generic_timeout': value => '120' }
  # double nf_conntrack_max default value
  sysctl { 'net.netfilter.nf_conntrack_max': value => '65536' }
  sysctl { 'net.nf_conntrack_max': value => '65536' }
}