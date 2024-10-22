require 'rails_helper'

RSpec.describe "Patterns", type: :request do
  describe "POST /patterns" do
    xit "creates a pattern with a preview image from FCJSON" do
      fcjson_data = {
        "type": "pattern",
        "version": "1.0",
        "name": "Test Pattern",
        "rows": [
          [ 1, 0, 1 ],
          [ 0, 1, 0 ],
          [ 1, 0, 1 ]
        ]
      }.to_json

      post "/patterns", params: { pattern: { fcjson: fcjson_data } }

      expect(Pattern.count).to eq(1)
      expect(response).to have_http_status(:created)
      created_pattern = Pattern.last
      expect(created_pattern.preview).to be_attached
      expect(created_pattern.preview.content_type).to start_with("image/")
    end
  end
end
