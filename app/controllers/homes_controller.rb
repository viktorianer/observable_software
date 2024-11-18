class HomesController < ApplicationController
  def index
    response = HTTParty.get("#{pdf_service_host}/download_pdf")

    if response.success?
      send_data response.body,
                filename: "pattern.pdf",
                type: "application/pdf",
                disposition: "inline"
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

  def pdf_service_host
    if Rails.env.development?
      "http://localhost:3002"
    else
      "http://pdf-service:3000"
    end
  end
end
