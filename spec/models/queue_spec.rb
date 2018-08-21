# coding: utf-8

describe Treasury::Models::Queue, type: :model do
  context 'when check db structure' do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(limit: 128, null: false) }
    it { is_expected.to have_db_column(:table_name).of_type(:string).with_options(limit: 256, null: true) }
    it { is_expected.to have_db_column(:trigger_code).of_type(:string).with_options(limit: 2000, null: true) }
    it { is_expected.to have_db_column(:db_link_class).of_type(:string).with_options(limit: 256) }
  end

  context 'when check associations' do
    it { is_expected.to have_many(:processors) }
  end

  describe '.generate_trigger' do
    let(:trigger_params) { {} }
    subject { described_class.generate_trigger(trigger_params) }

    context 'without conditions' do
      it { expect(subject).not_to include_text 'WHEN' }
    end

    context 'with conditions' do
      let(:trigger_params) { {conditions: 'one condition AND another condition'} }
      it { expect(subject).to include_text 'WHEN (one condition AND another condition)' }
    end

    context 'with specified columns' do
      let(:trigger_params) { {of_columns: [:user_id, :state]} }

      it do
        expect(subject.gsub(/\s/, '')).to eq(<<-SQL.gsub(/\s/, ''))
          CREATE TRIGGER %{trigger_name}
          AFTER insert OR delete OR update
          OF user_id,state
          ON %{table_name}
          FOR EACH ROW
          EXECUTE PROCEDURE pgq.logutriga(%{queue_name}, 'backup');
        SQL
      end

      context 'when not all events' do
        let(:trigger_params) { {events: [:update, :insert], of_columns: [:user_id, :state]} }

        it do
          expect(subject.gsub(/\s/, '')).to eq(<<-SQL.gsub(/\s/, ''))
            CREATE TRIGGER %{trigger_name}
            AFTER insert OR update
            OF user_id,state
            ON %{table_name}
            FOR EACH ROW
            EXECUTE PROCEDURE pgq.logutriga(%{queue_name}, 'backup');
          SQL
        end
      end
    end
  end
end
