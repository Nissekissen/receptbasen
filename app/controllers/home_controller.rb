class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    redirect_to explore_path unless authenticated?
  end
end
