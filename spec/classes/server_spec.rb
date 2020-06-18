# frozen_string_literal: true

require 'spec_helper'
require 'digest'

local_facts = {
  'root_home' => '/root',
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

describe 'grayloginstall::server' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts.merge(local_facts) }
      let(:params) do
        {
          'root_password' => 'secret',
          'password_secret' => '1H3RGlH5vNZUYgLAD7hDya74PmsioxpJZIIIjiEHySOF68ozxxaIUbJSygIDGvMKAGvaVfYgbqDxk2Cji3sLqQ9MncSSE73o',
        }
      end

      it { is_expected.to compile }

      context 'when elastic_seed_hosts provided' do
        let(:params) do
          super().merge(
            elastic_seed_hosts: ['192.168.200.225', '192.168.200.226', '192.168.200.192'],
          )
        end

        it {
          is_expected.to contain_class('graylog::server')
            .with_config(
              'password_secret'     => '1H3RGlH5vNZUYgLAD7hDya74PmsioxpJZIIIjiEHySOF68ozxxaIUbJSygIDGvMKAGvaVfYgbqDxk2Cji3sLqQ9MncSSE73o',
              'root_password_sha2'  => Digest::SHA256.hexdigest('secret'),
              'is_master'           => false,
              'http_bind_address'   => '104.134.88.225:9000',
              'elasticsearch_hosts' => 'http://192.168.200.225:9200,http://192.168.200.226:9200,http://192.168.200.192:9200',
            )
        }
      end
    end
  end
end
