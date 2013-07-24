class PhotosController < ApplicationController

  # GET /photos/new
  # GET /photos/new.json
  def new
    @photo = Photo.new
    @place_id = params[:place_id]

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @photo }
    end
  end

  # GET /photos/1/edit
  def edit
    @photo = Photo.find(params[:id])
    @place_id = @photo.place_id
  end

  # POST /photos
  # POST /photos.json
  def create
    @photo = Photo.new(params[:photo])
    @photo.place_id = params[:photo][:place_id]

    respond_to do |format|
      if @photo.save
        format.html { redirect_to edit_place_path(@photo.place), notice: 'Photo was successfully created.' }
        format.json { render json: @photo, status: :created, location: @photo }
      else
        format.html { render action: "new" }
        format.json { render json: @photo.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /photos/1
  # PUT /photos/1.json
  def update
    @photo = Photo.find(params[:id])

    respond_to do |format|
      if @photo.update_attributes(params[:photo])
        format.html { redirect_to edit_place_path(@photo.place), notice: 'Photo was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @photo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /photos/1
  # DELETE /photos/1.json
  def destroy
    @photo = Photo.find(params[:id])
    @place = @photo.place
    @photo.destroy

    respond_to do |format|
      format.html { redirect_to edit_place_path(@place) }
      format.json { head :no_content }
    end
  end
end