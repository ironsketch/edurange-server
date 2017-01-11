require 'rails_helper'

describe Scenario do
  describe "validations" do
    it "has a valid factory" do
      expect(build(:scenario)).to be_valid
    end

    it "is invalid without a valid user" do
      expect(build(:scenario, user: nil)).to be_invalid
    end

    it "is invalid when the path doesn't exist" do
      expect(build(:scenario, name: "nonexistant")).to be_invalid
      expect(build(:scenario, location: :production)).to be_invalid
    end

    describe "#name" do
      it "is invalid when blank" do
        expect(build(:scenario, name: "")).to be_invalid
      end

      it "is invalid when containing only underscores" do
        expect(build(:scenario, name: "____")).to be_invalid
      end
    end
  end

  describe "#load" do
    describe "with valid YAML" do
      before :all do
        @scenario = create(:scenario, name: "Test1", location: :test)
      end

      it "to be valid" do
        expect(@scenario).to be_valid
      end

      it "creates roles" do
        expect(@scenario.roles.count).to be(1)
        expect(@scenario.roles.first).to be_valid
        expect(@scenario.roles.first.packages.count).to be(2)
        expect(@scenario.roles.first.recipes.count).to be(2)
      end
    end
  end
end
