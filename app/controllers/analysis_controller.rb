class AnalysisController < ApplicationController

  def index
    # let's allow num_weeks to be passed in ignoring strong parameters etc for now
    @num_weeks = params[:num_weeks].to_i > 0 ? params[:num_weeks].to_i : 8

    @cohorts = Order.cohorts
  end
end
