class HomesController < ApplicationController
  def index
    DownloadPdfWithPlaywright.new(host:).call
    render :index
  end

  private

  def host
    if Rails.env.local?
      "http://localhost:3001"
    else
      "http://chrome-accessory:3000"
    end
  end
end
