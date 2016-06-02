class AddScenarioIdToStatistics < ActiveRecord::Migration
  def change
    add_column :statistics, :scenario_id, :integer
  end
end
