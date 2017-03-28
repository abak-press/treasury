# coding: utf-8

describe Treasury::Models::Field, type: :model do
  context 'when check db structure' do
    it { is_expected.to have_db_column(:title).of_type(:string).with_options(limit: 128, null: false) }
    it { is_expected.to have_db_column(:group).of_type(:string).with_options(limit: 128, null: false) }
    it { is_expected.to have_db_column(:field_class).of_type(:string).with_options(limit: 128, null: false) }
    it { is_expected.to have_db_column(:active).of_type(:boolean).with_options(default: false, null: false) }
    it { is_expected.to have_db_column(:need_terminate).of_type(:boolean).with_options(default: false, null: false) }
    it { is_expected.to have_db_column(:state).of_type(:string).with_options(limit: 128, null: false) }
    it { is_expected.to have_db_column(:pid).of_type(:integer) }
    it { is_expected.to have_db_column(:progress).of_type(:string).with_options(limit: 128) }
    it { is_expected.to have_db_column(:snapshot_id).of_type(:string).with_options(limit: 4000) }
    it { is_expected.to have_db_column(:last_error).of_type(:string).with_options(limit: 4000) }
    it { is_expected.to have_db_column(:worker_id).of_type(:integer) }
    it { is_expected.to have_db_column(:oid).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:params).of_type(:string).with_options(limit: 4000) }
    it { is_expected.to have_db_column(:storage).of_type(:string).with_options(limit: 4000) }
  end

  context 'when check associations' do
    it { is_expected.to have_many(:processors) }
    it { is_expected.to belong_to(:worker) }
  end
end
