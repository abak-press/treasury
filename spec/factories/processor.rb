# coding: utf-8

FactoryGirl.define do
  factory 'denormalization/processor', class: 'Treasury::Models::Processor' do
    association :queue, factory: 'denormalization/queue'
    association :field, factory: 'denormalization/field'
    processor_class 'Treasury::Processors::Base'
    sequence(:consumer_name) { |n| "consumer_name#{n}" }
  end
end
