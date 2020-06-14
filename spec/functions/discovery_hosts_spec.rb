require 'spec_helper'

describe 'grayloginstall::discovery_hosts' do
  it { is_expected.not_to eq(nil) }
  it { is_expected.to run.with_params.and_raise_error(ArgumentError, %r{expects between 1 and 2 arguments, got none}) }
  it { is_expected.to run.with_params('User').and_return([]) }

  describe 'when discovery hosts against a user resource' do
    let(:pre_condition) { 'user { "one": }' }

    it { is_expected.to run.with_params('User').and_return(['one']) }
  end

  describe 'when discovery hosts against an exported user resource' do
    let(:pre_condition) do
      <<-PRECOND
      class grayloginstall::user_export {
        @@user { 'one': }
      }

      include grayloginstall::user_export
      PRECOND
    end

    it { is_expected.to run.with_params('User').and_return([]) }
  end

  describe 'when discovery hosts against a user resource and gid param' do
    let(:pre_condition) { 'user { "one": }' }

    it { is_expected.to run.with_params('User', 'gid').and_return([]) }

    context 'when gid param is set' do
      let(:pre_condition) { 'user { "one": gid => 1000 }' }

      it { is_expected.to run.with_params('User', 'gid').and_return(['1000']) }
    end
  end
end
