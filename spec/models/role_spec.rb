require 'rails_helper'

describe Role do
  before :all do
    @scenario = create(:scenario)
  end

  it "has a valid factory" do
    expect(build(:role)).to be_valid
  end

  describe "validations" do
    describe "#name" do
      it "is invalid when blank" do
        expect(build(:role, name: "")).to be_invalid
      end

      it "is invalid when not unique" do
        role = create(:role, name: "good roll", scenario: @scenario)
        expect(role).to be_valid
        expect(build(:role, name: "good roll", scenario: @scenario)).to be_invalid
        role.destroy!
      end
    end

    describe "#scenario" do
      it "is invalid when not owned by a scenario" do
        expect(build(:role, scenario: nil)).to be_invalid
      end
    end
  end
end
