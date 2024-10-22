class CreatePatterns < ActiveRecord::Migration[8.0]
  def change
    create_table :patterns do |t|
      t.json :definition

      t.timestamps
    end
  end
end
