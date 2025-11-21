class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    handle_auth "Google"
  end

  def github
    handle_auth "GitHub"
  end

  def bitbucket
    handle_auth "Bitbucket"
  end

  def handle_auth(kind)
    auth = request.env["omniauth.auth"]
    Rails.logger.info "OmniAuth Auth Hash: #{auth.inspect}"
    Rails.logger.info "OmniAuth Error: #{request.env['omniauth.error'].inspect}"
    
    if auth.nil?
      Rails.logger.error "OmniAuth auth hash is nil!"
      flash[:alert] = "Authentication failed. Please try again."
      redirect_to new_user_session_path
      return
    end

    @user = User.from_omniauth(auth)

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: kind) if is_navigational_format?
    else
      session["devise.#{kind.downcase}_data"] = request.env["omniauth.auth"].except(:extra)
      redirect_to new_user_registration_url
    end
  end

  def failure
    redirect_to root_path
  end
end
