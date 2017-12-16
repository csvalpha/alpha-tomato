class ActivitiesController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def index
    @activities = Activity.includes(model_includes)
    authorize @activities

    @activity = Activity.new(
      start_time: (Time.zone.now + 2.hours).beginning_of_hour,
      end_time: (Time.zone.now + 6.hours).beginning_of_hour
    )
  end

  def create
    @activity = Activity.new(permitted_attributes)
    authorize @activity

    if @activity.save
      flash[:success] = 'Successfully created activity'
    else
      flash[:error] = @activity.errors.full_messages.join(', ')
    end

    redirect_to activities_url
  end

  def show
    @activity = Activity.includes(model_includes).find(params[:id])

    authorize @activity
  end

  def model_includes
    [:price_list, orders: %i[user order_rows]]
  end

  private

  def permitted_attributes
    params.require(:activity).permit(%i[title start_time end_time price_list_id])
  end
end
