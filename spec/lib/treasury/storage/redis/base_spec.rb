# coding: utf-8

describe Treasury::Storage::Redis::Base do
  let(:options) { {:key => 'key'} }
  let(:singleton_write_session) { described_class.new(options).send(:write_session) }
  let(:storage) { described_class.new(options) }
  let(:another_storage) { described_class.new(options) }

  before { allow_any_instance_of(described_class).to receive(:default_id) }
  before { allow(described_class).to receive(:new_redis_session) { MockRedis.new } }

  describe 'is used for writing a single connection to Redis' do
    subject { singleton_write_session }

    it { is_expected.to be storage.send(:write_session) }
    it { is_expected.to be another_storage.send(:write_session) }
  end

  describe '#rollback_transaction' do
    let(:write_session) { storage.send(:write_session) }

    before do
      storage.start_transaction
      write_session.set('key', 'value')
    end

    after { storage.rollback_transaction }

    it { expect(write_session.exists('key')).to be_truthy }

    it do
      storage.rollback_transaction
      expect(write_session.exists('key')).to be_falsey
    end
  end
end
