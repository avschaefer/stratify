class LandingController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]
  layout false

  def index
    redirect_to dashboard_index_path if user_signed_in?
  end
end

