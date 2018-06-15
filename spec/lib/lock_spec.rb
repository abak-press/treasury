require 'spec_helper'

RSpec.describe Treasury::Lock do
  let(:blocker) { described_class.new(:foo) }
  let(:redis) { Treasury.configuration.redis }

  after { redis.srem(described_class::KEY, :foo) }

  describe '#lock' do
    before { blocker.lock }

    it { expect(redis.sismembers(described_class::KEY, :foo)).to be_truthy }
  end

  describe '#locked?' do
    it do
      expect(blocker.locked?).to be_falsy

      blocker.lock

      expect(blocker.locked?).to be_truthy
    end
  end

  describe '#with_lock' do
    context 'when not locked' do
      it do
        expect { blocker.with_lock { puts 'hello' } }.not_to raise_error
      end
    end

    context 'when already locked' do
      it do
        blocker.lock

        expect { blocker.with_lock { puts 'hello' } }.to raise_error(StandardError, /failed to acqure lock foo/)
      end
    end
  end

  describe '#lock!' do
    context 'when already locked' do
      before { blocker.lock }

      it { expect { blocker.lock! }.to raise_error(StandardError, /failed to acqure lock foo/) }
    end

    context 'when does not locked' do
      it do
        blocker.lock!
        expect(redis.sismembers(described_class::KEY, :foo)).to be_truthy
      end
    end
  end

  describe '#unlock' do
    it do
      blocker.lock
      expect(redis.sismembers(described_class::KEY, :foo)).to be_truthy

      blocker.unlock
      expect(redis.sismembers(described_class::KEY, :foo)).to be_falsy
    end
  end
end
