describe Treasury::Fields::HashOperations do
  let(:hash_field_class) do
    Class.new do
      include Treasury::Fields::HashOperations
      extend Treasury::HashSerializer
    end
  end

  describe "#value_as_hash" do
    let(:value_as_hash) { hash_field_class.value_as_hash(object: 123, field: :count) }
    before do
      allow(hash_field_class).to receive(:value).and_return(value)
    end

    context 'when values is ints' do
      let(:value) { '10:100,20:200' }

      it do
        expect(hash_field_class).to receive(:init_accessor).with(object: 123, field: :count)
        expect(value_as_hash).to eq('10' => 100, '20' => 200)
      end
    end

    context 'when values is dates' do
      let(:value) { '10:2019-12-31,20:1999-10-01,21:2020-01-20' }

      it do
        expect(hash_field_class).to receive(:init_accessor).with(object: 123, field: :count)
        expect(value_as_hash).to eq(
          '10' => Date.parse('2019-12-31'),
          '20' => Date.parse('1999-10-01'),
          '21' => Date.parse('2020-01-20')
        )
      end
    end

    context 'when values is strings' do
      let(:value) { '10:8888-12-31,20:foobar' }

      it do
        expect(hash_field_class).to receive(:init_accessor).with(object: 123, field: :count)
        expect(value_as_hash).to eq('10' => '8888-12-31', '20' => 'foobar')
      end
    end
  end
end
