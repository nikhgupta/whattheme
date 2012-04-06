# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :theme do
    title "MyString"
    url "MyText"
    author "MyString"
    author_url "MyText"
    description "MyText"
    version "MyString"
    cms "MyString"
  end
end
