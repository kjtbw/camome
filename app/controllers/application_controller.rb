class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  prepend_before_action :login_state_setup
  before_filter :authenticate

  def login_state_setup
    if session[:user_id]
      User.current = User.find(session[:user_id]) rescue nil
    else
      User.current = nil
    end
    return true
  end

  def authenticate
    return true if User.current

    session[:jumpto] = request.parameters
    redirect_to :controller => "gate", :action => "login"
    return false
  end

  def set_current_user(user)
    session[:user_id] = user.id
    User.current = user
  end

  def reset_current_user
    session[:user_id] = nil
    User.current = nil
  end

  def reset_session_expires
    Rails.application.config.session_options[:session_expires] = 1.month.from_now
  end

end
