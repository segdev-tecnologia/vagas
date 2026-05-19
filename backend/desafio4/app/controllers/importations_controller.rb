class ImportationsController < ApplicationController
  def create
    policy_holder = params[:policy_holder].to_s.strip
    raise ArgumentError, "policy_holder is required" if policy_holder.empty?

    Thread.new do
      Rails.application.executor.wrap do
        Import.new(policy_holder).call
      rescue => e
        BroadcastLogger.new.error("[Import] fatal: #{e.class}: #{e.message}")
      end
    end

    render json: { status: "started", policy_holder: policy_holder }, status: :accepted
  rescue ArgumentError => e
    render json: { status: "error", message: e.message }, status: :unprocessable_entity
  end
end
