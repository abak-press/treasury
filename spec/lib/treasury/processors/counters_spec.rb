describe ::Treasury::Processors::Counters do
  let(:queue) { build 'denormalization/queue' }
  let(:processor) { processor_class.new(build('denormalization/processor', queue: queue)) }

  let(:processor_class) do
    Class.new(::Treasury::Processors::Base) do
      include ::Treasury::Processors::Counters
      counters :count

      def count?(data)
        data.fetch(:state) == 'satisfied'
      end
    end
  end

  let(:satisfied) do
    {data: {state: 'satisfied'}}
  end

  let(:not_satisfied) do
    {data: {state: 'not_satisfied'}}
  end

  let(:counted) do
    {prev_data: {state: 'satisfied'}}
  end

  let(:not_counted) do
    {prev_data: {state: 'not_satisfied'}}
  end

  shared_examples 'do nothing' do
    it do
      expect(processor).not_to receive(:incremented_current_value)
      expect(processor).not_to receive(:decremented_current_value)
      expect(result).to be_nil
    end
  end

  before do
    allow(processor).to receive(:incremented_current_value)
    allow(processor).to receive(:decremented_current_value)

    processor.instance_variable_set :@event, event
  end

  describe '#satisfied?' do
    context 'when event is satisfied' do
      let(:event) { double satisfied }
      it { expect(processor.count_satisfied?).to eq true }
    end

    context 'when event is not satisfied' do
      let(:event) { double not_satisfied }
      it { expect(processor.count_satisfied?).to eq false }
    end
  end

  describe '#was_counted?' do
    context 'when event was counted' do
      let(:event) { double counted }
      it { expect(processor.count_was_counted?).to eq true }
    end

    context "when event wasn't counted" do
      let(:event) { double not_counted }
      it { expect(processor.count_was_counted?).to eq false }
    end
  end

  context 'using raw data' do
    let(:processor_class) do
      Class.new(::Treasury::Processors::Base) do
        include ::Treasury::Processors::Counters
        counters :count, fast_parsing: true

        def count?(data)
          data.fetch(:state) == 'satisfied'
        end
      end
    end

    describe '#satisfied?' do
      context 'when event is satisfied' do
        let(:event) { double raw_data: {state: 'satisfied'} }
        it { expect(processor.count_satisfied?).to eq true }
      end

      context 'when event is not satisfied' do
        let(:event) { double raw_data: {state: 'not_satisfied'} }
        it { expect(processor.count_satisfied?).to eq false }
      end
    end

    describe '#was_counted?' do
      context 'when event was counted' do
        let(:event) { double raw_prev_data: {state: 'satisfied'} }
        it { expect(processor.count_was_counted?).to eq true }
      end

      context "when event wasn't counted" do
        let(:event) { double raw_prev_data: {state: 'not_satisfied'} }
        it { expect(processor.count_was_counted?).to eq false }
      end
    end
  end

  describe "#process_insert" do
    let(:result) { processor.process_insert }

    context "when event is satisfied" do
      let(:event) { double satisfied }
      it { expect(processor).to receive(:incremented_current_value).with(:count) }
    end

    context "when event is not satisfied" do
      let(:event) { double not_satisfied }
      it_behaves_like 'do nothing'
    end

    after { processor.send :process_insert }
  end

  describe "#process_update" do
    let(:result) { processor.process_update }

    context "when event is satisfied and wasn't counted" do
      let(:event) { double satisfied.merge(not_counted) }
      it { expect(processor).to receive(:incremented_current_value).with(:count) }
    end

    context "when event is satisfied and was counted" do
      let(:event) { double satisfied.merge(counted) }
      it_behaves_like 'do nothing'
    end

    context "when event is not satisfied and was counted" do
      let(:event) { double not_satisfied.merge(counted) }
      it { expect(processor).to receive(:decremented_current_value).with(:count) }
    end

    context "when event is not satisfied and wasn't counted" do
      let(:event) { double not_satisfied.merge(not_counted) }
      it_behaves_like 'do nothing'
    end

    after { processor.send :process_update }
  end

  describe "#process_delete" do
    let(:result) { processor.process_delete }

    context "when event was counted" do
      let(:event) { double counted }
      it { expect(processor).to receive(:decremented_current_value).with(:count) }
    end

    context "when event wasn't counted" do
      let(:event) { double not_counted }
      it_behaves_like 'do nothing'
    end

    after { processor.send :process_delete }
  end
end
