describe Treasury::Storage::Redis::Base do
  let(:options) { {:key => 'key'} }
  let(:storage) { described_class.new(options) }
  let(:redis) { Treasury.configuration.redis }

  before { allow_any_instance_of(described_class).to receive(:default_id) }

  describe 'is used for writing a single connection to Redis' do
    let(:singleton_write_session) { described_class.new(options).send(:write_session) }
    let(:another_storage) { described_class.new(options) }

    subject { singleton_write_session }

    it { is_expected.to be storage.send(:write_session) }
    it { is_expected.to be another_storage.send(:write_session) }
  end

  context '#reset_data' do
    before do
      stub_const 'Treasury::Storage::Redis::Base::RESET_FIELDS_BATCH_SIZE', 2

      redis.hset 'denormalization:key:1', 'k1', 'v1'
      redis.hset 'denormalization:key:1', 'k2', 'v2'
      redis.hset 'denormalization:key:1', 'k3', 'v3'

      redis.hset 'denormalization:key:2', 'k1', 'v1'
      redis.hset 'denormalization:key:2', 'k2', 'v2'
      redis.hset 'denormalization:key:2', 'k3', 'v3'

      redis.hset 'denormalization:key:3', 'k1', 'v1'
      redis.hset 'denormalization:key:3', 'k2', 'v2'
      redis.hset 'denormalization:key:3', 'k3', 'v3'

      storage.reset_data(nil, %w(k1 k2))
    end

    it do
      expect(redis.hexists('denormalization:key:1', 'k1')).to be_falsey
      expect(redis.hexists('denormalization:key:1', 'k2')).to be_falsey

      expect(redis.hexists('denormalization:key:2', 'k1')).to be_falsey
      expect(redis.hexists('denormalization:key:2', 'k2')).to be_falsey

      expect(redis.hexists('denormalization:key:3', 'k1')).to be_falsey
      expect(redis.hexists('denormalization:key:3', 'k2')).to be_falsey

      expect(redis.hget('denormalization:key:1', 'k3')).to eq 'v3'
      expect(redis.hget('denormalization:key:2', 'k3')).to eq 'v3'
      expect(redis.hget('denormalization:key:3', 'k3')).to eq 'v3'
    end
  end
end
