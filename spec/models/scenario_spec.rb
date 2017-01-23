require 'rails_helper'

describe Scenario do
  describe "validations" do
    it "has a valid factory" do
      expect(build(:scenario)).to be_valid
    end

    it "is invalid without a valid user" do
      expect(build(:scenario, user: nil)).to be_invalid
    end

    it "is invalid when #path doesn't exist" do
      expect(build(:scenario, name: "nonexistant")).to be_invalid
      expect(build(:scenario, location: :production)).to be_invalid
    end

    it "is invalid when nested resources are invalid" do
      scenario = create(:scenario)
      role = scenario.roles.new(name: "")
      expect(role).to be_invalid
      expect(scenario).to be_invalid
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

  describe "#clone" do
    let(:scenario) { build(:scenario.clone) }

    it "returns a valid custom scenario" do
      expect(scenario).to be_valid
      expect(scenario.location).to eq(:custom)
    end

    it "creates a new yml file" do
      expect(File.exists?(scenario.path_yml)).to eq(true)
    end
  end
end
