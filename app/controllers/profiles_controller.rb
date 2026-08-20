class ProfilesController < ApplicationController
  def show
    @user = Current.user
  end

  def update
    @user = Current.user

    if @user.update(user_params)
      redirect_back fallback_location: profile_path, notice: "Användarnamnet ändrades."
    else
      redirect_back fallback_location: profile_path, alert: "Det gick inte att byta användarnamnet."
    end
  end

  private

  def user_params
    params.expect(user: [ :username ])
  end
end
