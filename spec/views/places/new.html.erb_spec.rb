require 'spec_helper'

describe "places/new" do
  before(:each) do
    assign(:place, stub_model(Place).as_new_record)
  end

  it "renders new place form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", places_path, "post" do
    end
  end
end
