class ActivitySimulationsController < ApplicationController
  def show
    render json: Simulations::ActivitySimulator.instance.status
  end

  def create
    if Simulations::ActivitySimulator.instance.start
      render json: { status: "started" }, status: :accepted
    else
      render json: { status: "already_running" }, status: :conflict
    end
  end

  def destroy
    if Simulations::ActivitySimulator.instance.stop
      render json: { status: "stopping" }
    else
      render json: { status: "not_running" }, status: :conflict
    end
  end
end
