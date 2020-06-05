# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include grayloginstall::mongodb
class grayloginstall::mongodb (
  Boolean $manage_open_files_limit = true,
  Boolean $manage_selinux          = false,
  String  $version                 = '4.3',
  Array[Stdlib::IP::Address]
          $bind_ip                 = ['127.0.0.1'],
)
{
  # https://docs.mongodb.com/master/tutorial/install-mongodb-on-red-hat/
  #
  # https://docs.mongodb.com/master/reference/ulimit/
  if $manage_open_files_limit {
    rlimit { '*/nofile':
      ensure => present,
      value  => 65535,
    }
  }

  # if $manage_selinux and $::facts['selinux'] {
  # TODO: https://docs.mongodb.com/master/tutorial/install-mongodb-on-red-hat/#configure-selinux
  # }

  class { 'mongodb::globals':
    version             => $version,
    manage_package_repo => true,
    manage_package      => true,
    use_enterprise_repo => false,
  }

  systemd::dropin_file { 'mongod.service.d/limits.conf':
    filename => 'limits.conf',
    unit     => 'mongod.service',
    content  => file('grayloginstall/system/etc/systemd/system/mongod.service.limits'),
    before   => Class['mongodb::server'],
  }

  class { 'mongodb::server':
    bind_ip => $bind_ip,
  }

  # TODO: systemd service drop-in file for MongoDB service
  Class['mongodb::globals'] -> Class['mongodb::server']
}
