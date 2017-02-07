require 'faker'

FactoryGirl.define do
  factory :phone_number do
    contact
    phone_number Faker::PhoneNumber.phone_number
    name Faker::Name.name
  end
end
