class ContentsController < ApplicationController
  # GET / - the page with the idea box
  def new
  end

  # POST /generate - run the 6 steps and show the results on the same page
  def create
    @idea = params[:idea].to_s.strip

    if @idea.empty?
      @error = "Please type an idea first."
      return render :new, status: :unprocessable_entity
    end

    @results = ContentPipeline.run(@idea)
    render :new
  rescue => error
    @error = "Something went wrong: #{error.message}"
    render :new, status: :internal_server_error
  end
end
