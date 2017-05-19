class SepaDirectDebit < ActiveRecord::Migration
  def up
    add_column :maksuehto, :directdebit_id, :integer, limit: 4, after: :factoring_id
  end

  def down
    remove_column :maksuehto, :directdebit_id
  end
end
