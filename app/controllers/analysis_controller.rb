class AnalysisController < ApplicationController

  def index
    # let's allow num_weeks to be passed in ignoring strong parameters etc for now
    @num_weeks = params[:num_weeks] || 8

    # fetch cohort data and pass to view
    @cohorts = Order.cohorts
  end
end
