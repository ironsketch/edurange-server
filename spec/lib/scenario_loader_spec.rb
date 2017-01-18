require 'rails_helper'

describe ScenarioLoader do
  describe "production scenarios" do
    let(:user) { create(:instructor) }

    YmlRecord.yml_headers('production', nil).each do |scenario|
      it "loads #{scenario[:name]}" do
        expect(
          ScenarioLoader.new(name: scenario[:name], location: :production, user: user).fire!
        ).to be_valid
      end
    end
  end

  describe "with test1.yml", :focus do
    before :all do
      @user = create(:instructor)
      @scenario = ScenarioLoader.new(name: "test1", location: :test, user: @user).fire!
    end

    it "creates a valid scenario" do
      expect(@scenario).to_not be_nil
      expect(@scenario).to be_valid
    end

    describe "roles" do
      let(:roles) { @scenario.roles }

      it("creates one") { expect(roles.count).to eq(1) }
      it("is valid") { expect(roles.first).to be_valid }
      it("sets name") { expect(roles.first.name).to eq("NAT") }
      it("adds two packages to it") { expect(roles.first.packages.count).to eq(2) }
      it("creates two recipes for it") { expect(roles.first.recipes.count).to eq(2) }
    end

    describe "clouds" do
      let(:clouds) { @scenario.clouds }

      it("creates one") { expect(clouds.count).to eq(1) }
      it("is valid") { expect(clouds.first).to be_valid }
      it("has one subnet") { expect(clouds.first.subnets.count).to eq(1) }
      it "sets name and cidr_block" do
        expect(clouds.first.name).to eq("Cloud_1")
        expect(clouds.first.cidr_block).to eq("10.0.0.0/16")
      end
    end

    describe "subnets" do
      let(:subnets) { @scenario.subnets }

      it("creates one") { expect(subnets.count).to eq(1) }
      it("is valid") { expect(subnets.first).to be_valid }
      it("has one instance") { expect(subnets.first.instances.count).to eq(1) }
      it "sets name, cidr_block, and internet_accessible" do
        expect(subnets.first.name).to eq("NAT_Subnet")
        expect(subnets.first.cidr_block).to eq("10.0.129.0/24")
        expect(subnets.first.internet_accessible).to be true
      end
    end

    describe "instances" do
      let(:instances) { @scenario.instances }

      it("creates one") { expect(instances.count).to eq(1) }
      it("is valid") { expect(instances.first).to be_valid }
      it("has one role") { expect(instances.first.roles.count).to eq(1) }
      it "sets name, os, ip_address, and internet_accessible" do
        expect(instances.first.name).to eq("NAT_Instance")
        expect(instances.first.os).to eq("ubuntu")
        expect(instances.first.ip_address).to eq("10.0.129.5")
        expect(instances.first.internet_accessible).to be true
      end
    end

    describe "groups" do
      let(:groups) { @scenario.groups }

      it("creates two") { expect(groups.count).to eq(2) }

      describe "instructor group" do
        let(:group) { groups.first }

        it "sets name" do
          expect(group.name).to eq("Instructor")
        end

        describe "users" do
          let(:users) { group.players }

          it("creates one") { expect(users.count).to eq(1) }
          it "sets login and password" do
            expect(users.first.login).to eq("instructor")
            expect(users.first.password).to eq("Clzv1aeCs1Yz")
          end
        end

        describe "access" do
          let(:instance_groups) { group.instance_groups }
          it("creates one InstanceGroup") { expect(instance_groups.count).to eq(1) }
          it "sets administrator and ip_visible" do
            expect(instance_groups.first.administrator).to be true
            expect(instance_groups.first.ip_visible).to be true
          end
        end
      end

      describe "students group" do
        let(:group) { groups.second }

        it "sets name" do
          expect(group.name).to eq("Students")
        end

        describe "users" do
          let(:users) { group.players }

          it("creates one") { expect(users.count).to eq(1) }
          it "sets login and password" do
            expect(users.first.login).to eq("student")
            expect(users.first.password).to eq("sWfwkNGblfv")
          end
        end

        describe "access" do
          let(:instance_groups) { group.instance_groups }
          it("creates one InstanceGroup") { expect(instance_groups.count).to eq(1) }
          it "sets administrator and ip_visible" do
            expect(instance_groups.first.administrator).to be false
            expect(instance_groups.first.ip_visible).to be true
          end
        end
      end
    end
  end

  describe "with total_recon" do
    before :all do
      @user = create(:instructor)
      @scenario = ScenarioLoader.new(name: "total_recon",
                                     location: :production,
                                     user: @user)
                                .fire!
    end

    it "creates a valid scenario" do
      expect(@scenario).to_not be_nil
      expect(@scenario).to be_valid
    end

    it "sets the description" do
      expect(@scenario.description).to eq("Total Recon is a progressive, story-based game"\
                                          " designed to teach nmap network reconnaissance.")
    end

    it("creates one cloud") { expect(@scenario.clouds.count).to eq(1) }
    it("creates four subnets") { expect(@scenario.subnets.count).to eq(4) }
    it("creates thirteen instances") { expect(@scenario.instances.count).to eq(13) }
    it("creates twenty-nine roles") { expect(@scenario.roles.count).to eq(29) }
    it("creates thirty-two recipes") { expect(@scenario.recipes.count).to eq(32) }
    it("creates sixteen questions") { expect(@scenario.questions.count).to eq(16) }
    it("creates two groups") { expect(@scenario.groups.count).to eq(2) }
  end
end
