# == Class: galera::status
#
# Configures a user that will check the status of the galera cluster,
#
class galera::status {
  $status_password                = $galera::status_password
  $status_allow                   = $galera::status_allow
  $status_user                    = $galera::status_user

  if ! $status_password {
    fail('galera::status_password unset. Please specify a password for the clustercheck MySQL user.')
  }

  if $status_allow != 'localhost' {
    mysql_user { "${status_user}@${status_allow}":
      ensure        => 'present',
      password_hash => mysql_password($status_password),
      require       => [File['/root/.my.cnf'],Service['mysqld']]
    } ->
    mysql_grant { "${status_user}@${status_allow}/*.*":
      ensure     => 'present',
      options    => [ 'GRANT' ],
      privileges => [ 'USAGE' ],
      table      => '*.*',
      user       => "${status_user}@${status_allow}",
      before     => Anchor['mysql::server::end']
    }
  }

  mysql_user { "${status_user}@localhost":
    ensure        => 'present',
    password_hash => mysql_password($status_password),
    require       => [File['/root/.my.cnf'],Service['mysqld']]
  } ->
  mysql_grant { "${status_user}@localhost/*.*":
    ensure     => 'present',
    options    => [ 'GRANT' ],
    privileges => [ 'USAGE' ],
    table      => '*.*',
    user       => "${status_user}@localhost",
    before     => Anchor['mysql::server::end']
  }
}
