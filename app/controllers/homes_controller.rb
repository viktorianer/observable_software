class HomesController < ApplicationController
  def index
    response = Net::HTTP.get(URI("http://chrome:9222/json/list"))
    @tabs = JSON.parse(response)
    render :index
  end
end
