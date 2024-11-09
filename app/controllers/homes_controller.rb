class HomesController < ApplicationController
  def index
    response = Net::HTTP.get(URI("http://chrome-accessory:9222/json/list"))
    @tabs = JSON.parse(response)
    render :index
  end
end
