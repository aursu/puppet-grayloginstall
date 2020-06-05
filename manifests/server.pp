# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include grayloginstall::server
class grayloginstall::server (
  String  $root_password,
  String[64]
          $password_secret,
  Boolean $manage_java     = true,
  Boolean $manage_monngodb = true,
  Boolean $manage_elastic  = true,
  String  $major_version   = '3.3',
  String  $package_version = '3.3.0',
)
{
  if $manage_java {
    include grayloginstall::java
  }
  if $manage_monngodb {
    include grayloginstall::mongodb
  }
  if $manage_elastic {
    include grayloginstall::elastic
  }

  # https://docs.graylog.org/en/3.3/pages/installation/os/centos.html
  class { 'graylog::repository':
    url     => "https://packages.graylog2.org/el/stable/${major_version}/\$basearch/",
    version => $major_version,
  }

  class { 'graylog::server':
    package_version => $package_version,
    # https://docs.graylog.org/en/3.2/pages/getting_started/configure.html
    config          => {
      'password_secret'    => $password_secret,       # Fill in your password secret
      'root_password_sha2' => sha256($root_password), # Fill in your root password hash
    }
  }
}
