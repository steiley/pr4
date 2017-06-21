class SessionContoller < ApplicationController
  def create
    Rails.logger.info(params)

    render status: 200
  end

end
