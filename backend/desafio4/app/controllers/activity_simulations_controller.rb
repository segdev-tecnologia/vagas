class ActivitySimulationsController < ApplicationController
  def show
    render json: ActivitySimulator.instance.status
  end

  def create
    if ActivitySimulator.instance.start
      render json: { status: "started" }, status: :accepted
    else
      render json: { status: "already_running" }, status: :conflict
    end
  end

  def destroy
    if ActivitySimulator.instance.stop
      render json: { status: "stopping" }
    else
      render json: { status: "not_running" }, status: :conflict
    end
  end
end
