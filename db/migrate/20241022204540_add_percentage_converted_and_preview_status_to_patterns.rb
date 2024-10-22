class AddPercentageConvertedAndPreviewStatusToPatterns < ActiveRecord::Migration[8.0]
  def change
    add_column :patterns, :percentage_converted, :float
    add_column :patterns, :preview_status, :string, default: "missing"
  end
end
