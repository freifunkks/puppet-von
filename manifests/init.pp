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

  exec { "generate_fastd_keys":
    command => "fastd --generate-key",
    unless  => "cat /root/fastd_secret_key",
  }

  # radvd configuration
  file { '/etc/radvd.conf':
    ensure  => present,
    mode    => '0600',
    content => template('vpn/radvd.conf.erb'),
  }

  class { 'vpn::fastd':
    secret_key => file('/root/fastd_secret_key')
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

  service { 'fastd':
    ensure   => running,
    provider => init,
    enable   => true
  }
}

class vpn::icvpn() {
  package { ['bird', 'tinc']:
    ensure => installed,
  }
}
