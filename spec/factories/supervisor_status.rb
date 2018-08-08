FactoryGirl.define do
  factory 'denormalization/supervisor_status', class: 'Treasury::Models::SupervisorStatus' do
    active true
    need_terminate false
    state ::Treasury::Supervisor::STATE_RUNNING
    sequence(:pid) { |n| n }
  end
end
