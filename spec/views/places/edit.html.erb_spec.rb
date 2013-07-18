require 'spec_helper'

describe "places/edit" do
  before(:each) do
    @place = assign(:place, stub_model(Place))
  end

  it "renders the edit place form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", place_path(@place), "post" do
    end
  end
end
