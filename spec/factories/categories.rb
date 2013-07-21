FactoryGirl.define do
  factory :nature, class: Category do
    id 1
    name "nature"
  end
  factory :adventure, class: Category do
    id 2
    name "adventure"
  end
  factory :city, class: Category do
    id 3
    name "city"
  end
  factory :food, class: Category do
    id 4
    name "food"
  end
  factory :nightlife, class: Category do
    id 5
    name "nightlife"
  end
  factory :sports, class: Category do
    id 6
    name "sports"
  end
  factory :junk, class: Category do
    id 7
    name "junk"
  end
end