require 'spec_helper'

describe "places/index" do
  before(:each) do
    assign(:places, [
      stub_model(Place),
      stub_model(Place)
    ])
  end

  it "renders a list of places" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
