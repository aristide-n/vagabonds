require 'spec_helper'

describe Place do
  before do

    @category_nature = FactoryGirl.create(:nature)
    @category_city = FactoryGirl.create(:city)
    @category_food = FactoryGirl.create(:food)
    @category_junk = FactoryGirl.create(:junk)
    @category_nightlife = FactoryGirl.create(:nightlife)
    @category_sports = FactoryGirl.create(:sports)
    @category_adventure = FactoryGirl.create(:adventure)

    @golden_gate = FactoryGirl.create(:golden_gate)
    @muir_woods =  FactoryGirl.create(:muir_woods)
    @steakhouse =  FactoryGirl.create(:steakhouse)
    @walgreens =  FactoryGirl.create(:walgreens)
    @bubble_lounge =  FactoryGirl.create(:bubble_lounge)
    @redwood_trail = FactoryGirl.create(:redwood_trail)
    @rock_climb =  FactoryGirl.create(:rock_climb)
    @sf_moma =  FactoryGirl.create(:sf_moma)
    @twin_peak =  FactoryGirl.create(:twin_peak)
    @chaat_cafe =  FactoryGirl.create(:chaat_cafe)
    @z_lounge = FactoryGirl.create(:z_lounge)
    @discovery_kingdom =  FactoryGirl.create(:discovery_kingdom)
    @bay_kayak =  FactoryGirl.create(:bay_kayak)
    @alcatraz =  FactoryGirl.create(:alcatraz)
    @mission_peak =  FactoryGirl.create(:mission_peak)
    @pakwan = FactoryGirl.create(:pakwan)
    @casanova_lounge =  FactoryGirl.create(:casanova_lounge)
    @aqua_adventure =  FactoryGirl.create(:aqua_adventure)
    @laser_tag =  FactoryGirl.create(:laser_tag)
    @fineart_palace =  FactoryGirl.create(:fineart_palace)
    @half_moon =  FactoryGirl.create(:half_moon)
    @ananda_fuara = FactoryGirl.create(:ananda_fuara)
    @isotpoe_lounge =  FactoryGirl.create(:isotpoe_lounge)
    @angel_island =  FactoryGirl.create(:angel_island)
    @paintball_jungle =  FactoryGirl.create(:paintball_jungle)
    @academy_sciences =  FactoryGirl.create(:academy_sciences)
    @tomales_bay = FactoryGirl.create(:tomales_bay)
    @great_america =  FactoryGirl.create(:great_america)
    @oxygen_paragliding = FactoryGirl.create(:oxygen_paragliding)
    @coit_tower =  FactoryGirl.create(:coit_tower)
    @asian_museum = FactoryGirl.create(:asian_museum)
  end

  context "recommend places" do

    it "should give only places with matching categories" do
        params = {"start_date" => "07/06/2013","end_date" => "07/07/2013", "budget" => 5, "categories" => ["Nightlife", "City", "Nature"] }
        Place.recommendations(params).should_not include(@muir_woods)
    end

  end
end
