# frozen_string_literal: true

require 'spec_helper'

local_facts = {
  'root_home' => '/root',
}

describe 'grayloginstall::mongodb' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts.merge(local_facts)
      end
      let(:params) do
        {
          'graylog_password' => 'D1fficultP@ssw:rd',
        }
      end

      it { is_expected.to compile }
    end
  end
end
