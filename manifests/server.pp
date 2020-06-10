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
  String  $major_version   = '3.3',
  String  $package_version = '3.3.0',
  Boolean $manage_java     = true,
  Boolean $manage_monngodb = true,
  Boolean $manage_elastic  = true,
  Optional[Integer[0,1]]
          $repo_sslverify  = undef,
)
{
  if $manage_java {
    include grayloginstall::java
  }
  if $manage_monngodb {
    class { 'grayloginstall::mongodb':
      repo_sslverify => $repo_sslverify,
    }
  }
  if $manage_elastic {
    include grayloginstall::elastic
  }

  # https://docs.graylog.org/en/3.3/pages/installation/os/centos.html
  class { 'graylog::repository':
    url     => "https://packages.graylog2.org/repo/el/stable/${major_version}/\$basearch/",
    version => $major_version,
  }

  if $repo_sslverify {
    Yumrepo <| title == 'graylog' |> {
      sslverify => $repo_sslverify,
    }
  }

  # file resource to not purge repo in case if /etc/yum.repos.d are managed with purge => true
  file { '/etc/yum.repos.d/graylog.repo':
    mode => '0600',
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
