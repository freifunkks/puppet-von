########
# Base #
########
class vpn(
  $inet_dev='eth0',
  $ip_addr,
  $ip_mask='24',
  $ip_gtw,
  $ip_brd,
  $vpn_nr,
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
  package { ['bridge-utils', 'fastd', 'openvpn', 'radvd']:
    ensure => installed,
  }

  # Build batman-adv, batctl and alfred
  package { ['build-essential', 'pkg-config', 'libnl-3-dev']:
    ensure => installed,
  }
  file { '/home/ffks/install.sh':
    ensure  => present,
    content => template('vpn/install.sh'),
    mode    => 755,
  }
  exec { "install_batman":
    command => "bash /home/ffks/install.sh",
    path    => "/home/ffks/",
  }

  class { 'vpn::fastd':
    secret_key => file('/root/fastd_secret_key')
  }

  class { 'vpn::dnsmasq': }

  # network configuration
  file { '/etc/sysctl.conf':
    ensure  => present,
    mode    => '0600',
    content => template('vpn/sysctl.conf'),
  }

  file { '/etc/network/interfaces.d/ff-vpn':
    ensure  => present,
    mode    => '0600',
    content => template('vpn/network/interfaces.erb'),
  }

  file { '/etc/iproute2/rt_tables':
    ensure  => present,
    mode    => 755,
    content => template('vpn/iproute2/rt_tables'),
  }


  file { '/etc/sysctl.conf':
    ensure  => present,
    content => template('vpn/sysctl.conf'),
    mode    => 755,
  }

  # alfred configuration
  file { '/etc/default/alfred':
    ensure  => present,
    mode    => 755,
    content => template('vpn/default/alfred'),
  }

  # radvd configuration
  file { '/etc/radvd.conf':
    ensure  => present,
    mode    => '0600',
    content => template('vpn/radvd.conf.erb'),
  }

  # Start services
  service { 'radvd':
    ensure   => running,
    provider => init,
    enable   => true,
  }
}

#########
# fastd #
#########
class vpn::fastd(
  $secret_key
) {
  file { '/etc/fastd/secret.conf':
    ensure  => present,
    mode    => '0600',
    content => inline_template('secret "<%= @secret_key.chomp %>";');
  }

  class { 'vpn::fastd::client': }

  class { 'vpn::fastd::mesh': }

  service { 'fastd':
    ensure   => running,
    provider => init,
    enable   => true,
  }
}

class vpn::fastd::client() {
  file { "/etc/fastd/client/" :
    ensure => directory,
  }

  file { "/etc/fastd/client/peers" :
    ensure => directory,
  }

  file { '/etc/fastd/client/fastd.conf':
    ensure  => present,
    mode    => '0600',
    content => template('vpn/fastd/client/fastd.conf.erb'),
  }

  file { '/etc/fastd/client/peers/vpn1':
    ensure  => present,
    mode    => '0600',
    content => template('vpn/fastd/client/vpn1'),
  }
}

class vpn::fastd::mesh() {
  file { "/etc/fastd/mesh/" :
    ensure => directory,
  }

  file { "/etc/fastd/mesh/peers" :
    ensure => directory,
  }

  file { '/etc/fastd/mesh/fastd.conf':
    ensure  => present,
    mode    => '0600',
    content => template('vpn/fastd/mesh/fastd.conf.erb'),
  }
}

###########
# OpenVPN #
###########
class vpn::openvpn() {
  file { '/etc/openvpn/uplink/up.sh':
    ensure  => present,
    mode    => 755,
    content => template('vpn/openvpn/up.sh.erb'),
  }

  file { '/etc/openvpn/uplink/down.sh':
    ensure  => present,
    mode    => 755,
    content => template('vpn/openvpn/down.sh.erb'),
  }
}

##############
# DNS & DHCP #
##############
class vpn::dns() {
  package { ['bind9']:
    ensure => installed,
  }

  file { '/etc/bind/named.conf.options':
    ensure  => present,
    content => template('vpn/bind/named.conf.options'),
    mode    => 755,
  }

  service { 'bind9':
    ensure   => running,
    provider => init,
    enable   => true,
  }
}

class vpn::dhcp() {
  package { ['isc-dhcp-server']:
    ensure => installed,
  }

  file { '/etc/dhcp/dhcpd.conf':
    ensure  => present,
    content => template('vpn/dhcp/dhcpd.conf.erb'),
    mode    => 755,
  }

  service { 'bind9':
    ensure   => running,
    provider => init,
    enable   => true,
  }
}

class vpn::dnsmasq() {
  package { ['dnsmasq']:
    ensure => installed,
  }

  file { '/etc/dnsmasq.d/shared':
    ensure  => present,
    content => template('vpn/dnsmasq.d/shared'),
    mode    => 755,
  }

  file { '/etc/dnsmasq.d/dhcp':
    ensure  => present,
    content => template('vpn/dnsmasq.d/dhcp.erb'),
    mode    => 755,
  }

  file { '/etc/dnsmasq.d/dns':
    ensure  => present,
    content => template('vpn/dnsmasq.d/dns'),
    mode    => 755,
  }

  file { '/etc/hosts':
    ensure  => present,
    content => template('hosts'),
    mode    => 755,
  }

  service { 'dnsmasq':
    ensure    => running,
    provider  => init,
    enable    => true,
  }
}

#########
# ICVPN #
#########
class vpn::icvpn() {
  package { ['bird', 'tinc']:
    ensure => installed,
  }
}
