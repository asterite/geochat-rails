module LocatableActions
  def new_custom_location
    @custom_location = locatable.custom_locations.new
  end

  def create_custom_location
    @custom_location = locatable.custom_locations.new params[:custom_location]
    if @custom_location.save
      flash[:notice] = "Custom location #{@custom_location.name} created"
      redirect_to locatable_path
    else
      render :new_custom_location
    end
  end

  def edit_custom_location
    @custom_location = locatable.custom_locations.find_by_name params[:custom_location_id]
  end

  def update_custom_location
    @custom_location = locatable.custom_locations.find_by_name params[:custom_location_id]
    @custom_location.attributes = params[:custom_location]
    if @custom_location.save
      flash[:notice] = "Custom location #{@custom_location.name} updated"
      redirect_to locatable_path
    else
      render :edit_custom_location
    end
  end

  def destroy_custom_location
    @custom_location = locatable.custom_locations.find_by_name params[:custom_location_id]
    @custom_location.destroy

    flash[:notice] = "Custom location #{@custom_location.name} deleted"
    redirect_to locatable_path
  end
end
