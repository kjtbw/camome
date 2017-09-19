# coding: utf-8
class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  # GET /users
  # GET /users.json
  def index
    @users = User.all
  end

  # GET /users/1
  # GET /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
    auth_info = MasterAuthInfo.new(:login_name => params["login_name"])
    @user = User.new(:name => params["display_name"])
    @user.master_pass = params["password"]
    auth_info = KeyVault.lock(auth_info, @user)
    @user.master_auth_info = auth_info

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def authorize_application
    begin
      current_user.master_pass = params[:pass]
      auth_info = KeyVault.unlock(current_user.master_auth_info, current_user)
      token = Digest::SHA1.hexdigest(current_user.name + DateTime.new.to_s)
      session[:app_token] = token
      session[:decrypted_pass] = auth_info.decrypted_pass
      ds = DataStore::RedisStore.new
      if ds.load(current_user.auth_name) == nil
        redirect_to omniauth_authorize_path(:user, :google_oauth2, :token => token, :state => "application")
      else
        redirect_to omniauth_authorize_path(:user, :google_oauth2, :token => token, :state => "update")
      end
    rescue
      flash[:error] = "Invalid password or Password has not been set"
      redirect_to '/users/edit/applications'
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:name)
    end
end
