require 'test_helper'

class GroupTest < ActiveSupport::TestCase
  test 'no variables present' do
    s = ScenarioLoader.new(user: users(:instructor1), name: 'Variables_None', location: :test).fire!
    assert s.valid?
  end

  test 'variables' do
    s = ScenarioLoader.new(user: users(:instructor1), name: 'Variables', location: :test).fire!
    assert s.valid? 

    g = s.groups.first
    assert g.variables.has_key? :instance
    assert_equal g.variables[:instance].class, Hash

    assert g.variables.has_key? :player
    assert_equal g.variables[:player].class, Hash

    assert g.variables[:player].has_key? :info
    assert_equal g.variables[:player][:info].class, Hash
    
    assert g.variables[:player].has_key? :info
    assert_equal g.variables[:player][:info].class, Hash
 
    assert g.variables[:player].has_key? :vars
    assert_equal g.variables[:player][:vars].class, Hash
    
    assert g.variables[:instance].has_key? "var1"
    assert_equal g.variables[:instance]["var1"].class, Variable
    assert g.variables[:instance].has_key? "var2"
    assert_equal g.variables[:instance]["var2"].class, Variable
    assert g.variables[:instance].has_key? "var3"
    assert_equal g.variables[:instance]["var3"].class, Variable
    
    assert g.variables[:player][:info].has_key? "vara"
    assert g.variables[:player][:info].has_key? "varb"
    assert g.variables[:player][:info].has_key? "varc"

    assert g.variables[:player][:vars].has_key? g.players.first
  end
end
