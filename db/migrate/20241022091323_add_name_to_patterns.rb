class AddNameToPatterns < ActiveRecord::Migration[8.0]
  def change
    add_column :patterns, :name, :string
  end
end
