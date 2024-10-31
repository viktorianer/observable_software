class AddOrientationToPatterns < ActiveRecord::Migration[8.0]
  def change
    add_column :patterns, :orientation, :string, default: "portrait"
  end
end
