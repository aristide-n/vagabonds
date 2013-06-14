# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :place do
    permanent_id "MyString"
    name "MyString"
    reference "MyString"
    address "MyString"
    address_lat "9.99"
    address_lng "9.99"
    phone_number "MyString"
    rating "9.99"
    url "MyString"
    website "MyString"
  end
end
