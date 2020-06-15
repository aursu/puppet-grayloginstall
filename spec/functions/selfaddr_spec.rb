require 'spec_helper'

local_facts = {
  'networking' => {
    'domain' => 'corpdldomain.tld',
    'fqdn' => 'logger.corpdldomain.tld',
    'hostname' => 'logger',
    'interfaces' => {
      'bond0' => {
        'mac' => 'f2:df:d3:61:5d:e9',
        'mtu' => 1500,
      },
      'dummy0' => {
        'mac' => 'ba:aa:05:75:69:34',
        'mtu' => 1500,
      },
      'eth0' => {
        'bindings' => [
          {
            'address' => '104.134.88.225',
            'netmask' => '255.255.255.0',
            'network' => '104.134.88.0',
          },
        ],
        'bindings6' => [
          {
            'address' => 'fe80::c252:fce7:8638:1604',
            'netmask' => 'ffff:ffff:ffff:ffff::',
            'network' => 'fe80::',
          },
        ],
        'ip' => '104.134.88.225',
        'ip6' => 'fe80::c252:fce7:8638:1604',
        'mac' => '00:50:56:b9:fe:f3',
        'mtu' => 1500,
        'netmask' => '255.255.255.0',
        'netmask6' => 'ffff:ffff:ffff:ffff::',
        'network' => '104.134.88.0',
        'network6' => 'fe80::',
      },
      'eth1' => {
        'bindings' => [
          {
            'address' => '192.168.200.225',
            'netmask' => '255.255.255.0',
            'network' => '192.168.200.0',
          },
        ],
        'bindings6' => [
          {
            'address' => 'fe80::fe97:cbdf:da6a:f003',
            'netmask' => 'ffff:ffff:ffff:ffff::',
            'network' => 'fe80::',
          },
        ],
        'ip' => '192.168.200.225',
        'ip6' => 'fe80::fe97:cbdf:da6a:f003',
        'mac' => '00:50:56:b9:80:76',
        'mtu' => 1500,
        'netmask' => '255.255.255.0',
        'netmask6' => 'ffff:ffff:ffff:ffff::',
        'network' => '192.168.200.0',
        'network6' => 'fe80::',
      },
      'lo' => {
        'bindings' => [
          {
            'address' => '127.0.0.1',
            'netmask' => '255.0.0.0',
            'network' => '127.0.0.0',
          },
        ],
        'bindings6' => [
          {
            'address' => '::1',
            'netmask' => 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
            'network' => '::1',
          },
        ],
        'ip' => '127.0.0.1',
        'ip6' => '::1',
        'mtu' => 65536,
        'netmask' => '255.0.0.0',
        'netmask6' => 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
        'network' => '127.0.0.0',
        'network6' => '::1',
      },
    },
    'ip' => '104.134.88.225',
    'ip6' => 'fe80::c252:fce7:8638:1604',
    'mac' => '00:50:56:b9:fe:f3',
    'mtu' => 1500,
    'netmask' => '255.255.255.0',
    'netmask6' => 'ffff:ffff:ffff:ffff::',
    'network' => '104.134.88.0',
    'network6' => 'fe80::',
    'primary' => 'eth0',
  },
}

describe 'grayloginstall::selfaddr' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts.merge(local_facts)
      end

      it {
        is_expected.to run.with_params('2001:1810:1040:3::26').and_return(false)
      }

      it {
        is_expected.to run.with_params('104.134.91.209').and_return(false)
      }

      it {
        is_expected.to run.with_params('104.134.91.400').and_raise_error(%r{expects a Stdlib::IP::Address})
      }

      it {
        is_expected.to run.with_params('192.168.200.225').and_return(true)
      }

      it {
        is_expected.to run.with_params('104.134.88.225').and_return(true)
      }

      it {
        is_expected.to run.with_params('fe80::c252:fce7:8638:1604').and_return(true)
      }

      it {
        is_expected.to run.with_params('::1').and_return(true)
      }

      it {
        is_expected.to run.with_params('127.0.0.2').and_return(true)
      }
    end
  end
end
