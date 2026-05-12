require Rails.root.join("fixtures/policy_fixture_generator")

class FixturesController < ApplicationController
  def generate_policies
    count = Integer(params[:count])
    raise ArgumentError, "count must be greater than 0" unless count.positive?

    PolicyFixtureGenerator.new.generate(count)

    render json: { status: "success", generated: count }, status: :created
  rescue ArgumentError, TypeError => e
    render json: { status: "error", message: e.message }, status: :unprocessable_entity
  end

  def policy_holders
    render json: { policy_holders: PolicyFixtureGenerator::POLICY_HOLDERS.sort }
  end
end
