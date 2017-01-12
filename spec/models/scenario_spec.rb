require 'rails_helper'

describe Scenario do
  describe "validations" do
    it "has a valid factory" do
      expect(build(:scenario)).to be_valid
    end

    it "is invalid without a valid user" do
      expect(build(:scenario, user: nil)).to be_invalid
    end

    describe "#path" do
      it "is invalid when it doesn't exist" do
        expect(build(:scenario, name: "nonexistant")).to be_invalid
        expect(build(:scenario, location: :production)).to be_invalid
      end
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
    describe "with scenario 'test1'" do
      before :all do
        @scenario = create(:scenario, name: "Test1", location: :test)
      end

      it "is valid" do
        expect(@scenario).to be_valid
      end

      describe "roles" do
        it "creates one 1 role" do
          expect(@scenario.roles.count).to eq(1)
        end

        it "assigns 2 packages and 2 recipes to the role" do
          expect(@scenario.roles.first.packages.count).to eq(2)
          expect(@scenario.roles.first.recipes.count).to eq(2)
        end
      end

      it "creates 2 groups" do
        expect(@scenario.groups.count).to eq(2)
      end

      it "creates 1 cloud" do
        expect(@scenario.clouds.count).to eq(1)
      end

      it "creates 1 subnet" do
        expect(@scenario.subnets.count).to eq(1)
      end

      it "creates 1 instance" do
        expect(@scenario.instances.count).to eq(1)
      end
    end
  end
end
