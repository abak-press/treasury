# coding: utf-8

FactoryGirl.define do
  factory 'denormalization/field', class: 'Treasury::Models::Field' do
    sequence(:title) { |n| "title#{n}" }
    sequence(:group) { |n| "group#{n}" }
    field_class 'Treasury::Fields::Base'
    active true
    need_terminate false
    state Treasury::Fields::STATE_INITIALIZED
    sequence(:pid) { |n| n }
    sequence(:progress) { |n| "progress_#{n}" }
    snapshot_id '11:20:11,12,15'
    last_error nil
    worker_id nil
    sequence(:oid) { |n| n }
    params nil
    storage []

    trait :no_active do
      active false
    end

    trait :need_terminate do
      need_terminate true
    end

    trait :need_initialize do
      state Treasury::Fields::STATE_NEED_INITIALIZE
    end

    after(:create) do |field|
      field.field_class.constantize._instance = nil
    end
  end
end
