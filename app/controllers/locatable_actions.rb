module LocatableActions
  def change_location
  end

  def update_location
    param_name = locatable.class.name.tableize.singularize.to_sym

    locatable.lat = params[param_name][:lat]
    locatable.lon = params[param_name][:lon]

    result = Geokit::Geocoders::GoogleGeocoder.reverse_geocode([locatable.lat, locatable.lon])
    if result.success?
      locatable.location = result.full_address
      if locatable.respond_to? :location_short_url=
        locatable.location_short_url = Googl.shorten_location locatable.coords
      end
    end

    locatable.save!

    flash[:notice] = "Location successfully updated to #{locatable.location}"
    redirect_to locatable_path
  end

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
