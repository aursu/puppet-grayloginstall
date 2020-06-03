# frozen_string_literal: true

require 'spec_helper'

local_facts = {
  'root_home' => '/root',
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
    end
  end
end
