class SimulationsController < ApplicationController
  def show
    render json: Simulator.instance.status
  end

  def create
    policy_holder = params[:policy_holder].to_s.strip
    raise ArgumentError, "policy_holder is required" if policy_holder.empty?

    if Simulator.instance.start(policy_holder)
      render json: { status: "started", policy_holder: policy_holder }, status: :accepted
    else
      render json: { status: "already_running" }, status: :conflict
    end
  rescue ArgumentError => e
    render json: { status: "error", message: e.message }, status: :unprocessable_entity
  end

  def destroy
    if Simulator.instance.stop
      render json: { status: "stopping" }
    else
      render json: { status: "not_running" }, status: :conflict
    end
  end
end
