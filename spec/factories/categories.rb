FactoryGirl.define do
  factory :nature, class: Category do
    id 1
    name "Nature"
  end
  factory :adventure, class: Category do
    id 2
    name "Adventure"
  end
  factory :city, class: Category do
    id 3
    name "City"
  end
  factory :food, class: Category do
    id 4
    name "Food"
  end
  factory :nightlife, class: Category do
    id 5
    name "Nightlife"
  end
  factory :sports, class: Category do
    id 6
    name "Sports"
  end
  factory :junk, class: Category do
    id 7
    name "Junk"
  end
end