class vpn(
  $inet_dev='eth0',
  $ip_addr,
  $ip_mask='24',
  $ip_gtw,
  $ip_brd,
  $vpn_nr
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
  exec {
    'enable_batman_mod':
      command => 'echo batman-adv >> /etc/modules',
      unless  => 'grep -q ^batman-adv /etc/modules',
      path    => ['/bin', '/usr/sbin'],
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
    command => "install.sh",
    path    => "/home/ffks/",
  }

  class { 'vpn::fastd::mesh':
    secret_key => file('/root/fastd_secret_key')
  }

  # radvd configuration
  file { '/etc/radvd.conf':
    ensure  => present,
    mode    => '0600',
    content => template('vpn/radvd.conf.erb'),
  }

  # network configuration
  file { '/etc/network/interfaces.d/ff-vpn':
    ensure  => present,
    mode    => '0600',
    content => template('vpn/network/interfaces.erb'),
  }

  file { '/etc/network/if-up.d/tun0.post.up':
    ensure  => present,
    mode    => '0600',
    content => template('vpn/network/if-up.d/tun0.post.up.erb'),
  }

  file { '/etc/network/if-down.d/tun0.pre.down':
    ensure  => present,
    mode    => '0600',
    content => template('vpn/network/if-down.d/tun0.pre.down.erb'),
  }

  # Start services
  service { 'radvd':
    ensure   => running,
    provider => init,
    enable   => true
  }

  service { 'batmand':
    ensure   => running,
    provider => init,
    enable   => true
  }
}

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
    enable   => true
  }
}

class vpn::fastd::client() {
  exec { 'mkdir_fastd_client':
    command => 'mkdir -p /etc/fastd/client/',
  }

  exec { 'mkdir_fastd_client_peers':
    command => 'mkdir -p /etc/fastd/client/peers',
  }

  # fastd configuration
  file { '/etc/fastd/client/fastd.conf':
    ensure  => present,
    mode    => '0600',
    content => template('vpn/fastd/client/fastd.conf.erb'),
  }

  file { '/etc/fastd/client/peers/vpn1':
    ensure  => present,
    mode    => '0600',
    content => template('vpn/fastd/client/vpn1.erb'),
  }
}

class vpn::fastd::mesh() {
  exec { 'mkdir_fastd_mesh':
    command => 'mkdir -p /etc/fastd/mesh/',
  }

  exec { 'mkdir_fastd_mesh_peers':
    command => 'mkdir -p /etc/fastd/mesh/peers',
  }

  # fastd configuration
  file { '/etc/fastd/mesh/fastd.conf':
    ensure  => present,
    mode    => '0600',
    content => template('vpn/fastd/mesh/fastd.conf.erb'),
  }
}

class vpn::icvpn() {
  package { ['bird', 'tinc']:
    ensure => installed,
  }
}
