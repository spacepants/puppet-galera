# == Class: galera::status
#
# Configures a script that will check the status of the galera cluster,
#
class galera::clustercheck {
  $status_password                = $galera::status_password
  $status_host                    = $galera::status_host
  $status_user                    = $galera::status_user
  $port                           = $galera::status_port
  $available_when_donor           = $galera::status_available_when_donor
  $available_when_readonly        = $galera::status_available_when_readonly
  $status_log_on_success_operator = $galera::status_log_on_success_operator
  $status_log_on_success          = $galera::status_log_on_success
  $status_log_on_failure          = $galera::status_log_on_failure

  if ! $status_password {
    fail('galera::status_password unset. Please specify a password for the clustercheck MySQL user.')
  }

  group { 'clustercheck':
    ensure => present,
    system => true,
  }

  user { 'clustercheck':
    shell  => '/bin/false',
    home   => '/var/empty',
    gid    => 'clustercheck',
    system => true,
    before => File['/usr/local/bin/clustercheck'],
  }

  file { '/usr/local/bin/clustercheck':
    content => template('galera/clustercheck.erb'),
    owner   => 'clustercheck',
    group   => 'clustercheck',
    mode    => '0500',
    before  => Anchor['mysql::server::end'],
  }

  augeas { 'mysqlchk':
    context => '/files/etc/services',
    changes => [
      "rm /files/etc/services/service-name[port = '${port}']",
      "set /files/etc/services/service-name[port = '${port}']/port ${port}",
      "set /files/etc/services/service-name[port = '${port}'] mysqlchk",
      "set /files/etc/services/service-name[port = '${port}']/protocol tcp",
    ],
    onlyif  => "match service-name[. = 'mysqlchk'] size == 0",
    before  => Anchor['mysql::server::end'],
  }

  xinetd::service { 'mysqlchk':
    server                  => '/usr/local/bin/clustercheck',
    port                    => $port,
    user                    => 'clustercheck',
    flags                   => 'REUSE',
    log_on_success          => $status_log_on_success,
    log_on_success_operator => $status_log_on_success_operator,
    log_on_failure          => $status_log_on_failure,
    require                 => [
      File['/usr/local/bin/clustercheck'],
      User['clustercheck'],
      Class['mysql::server::install']],
    before                  => Anchor['mysql::server::end'],
  }
}
