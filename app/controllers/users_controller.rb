class UsersController < ApplicationController
  before_action :authenticate_user!

  after_action :verify_authorized

  def index
    @model = User.all.includes(model_includes)
    authorize @model

    @new_user = User.new
  end

  def show
    @user = User.includes(model_includes).find(params[:id])
    authorize @user
  end

  def create
    @user = User.new(permitted_attributes)
    authorize @user

    if @user.save
      flash[:success] = 'Successfully created user'
    else
      flash[:error] = @user.errors.full_messages.join(', ')
    end

    redirect_to users_path
  end

  def refresh_user_list
    authorize User

    users_json.each do |user_json|
      find_or_create_user(user_json)
    end
    redirect_to users_path
  end

  def api_token
    return @token if @token
    options = { grant_type: 'client_credentials',
                client_id: Rails.application.secrets.fetch(:banana_client_id),
                client_secret: Rails.application.secrets.fetch(:banana_client_secret) }
    token_response = RestClient.post "#{Rails.application.config.x.banana_api_host}/api/oauth/token", options

    @token = JSON.parse(token_response)['access_token']
  end

  def model_class
    User
  end

  def model_includes
    [:orders, :credit_mutations, orders: :order_rows]
  end

  private

  def users_json
    JSON.parse(RestClient.get("#{Rails.application.config.x.banana_api_host}/api/users",
                              'Accept' => 'application/vnd.csvalpha.nl; version=1',
                              'Authorization' => "Bearer #{api_token}"))['data']
  end

  def find_or_create_user(user_json)
    fields = user_json['attributes']
    User.find_or_create_by(uid: user_json['id']) do |u|
      u.name = User.full_name_from_attributes(fields['first-name'],
                                              fields['last-name-prefix-name'],
                                              fields['last-name'])
      u.provider = 'banana_oauth2'
    end
  end

  def permitted_attributes
    params.require(:user).permit(%i[name])
  end
end
