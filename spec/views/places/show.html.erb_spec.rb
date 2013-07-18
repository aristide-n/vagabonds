require 'spec_helper'

describe "places/show" do
  before(:each) do
    @place = assign(:place, stub_model(Place))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
