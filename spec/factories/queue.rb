# coding: utf-8

FactoryGirl.define do
  factory 'denormalization/queue', class: 'Treasury::Models::Queue' do
    sequence(:name) { |n| "name#{n}" }
    sequence(:table_name) { |n| "table_name#{n}" }
    sequence(:trigger_code) { |n| "trigger_code#{n}" }
  end
end
