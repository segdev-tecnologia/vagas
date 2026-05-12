class NukeController < ApplicationController
  def destroy
    deleted_fixtures = clear_fixtures
    deleted_policies = Policy.delete_all

    render json: {
      status: "nuked",
      deleted_policies: deleted_policies,
      deleted_fixtures: deleted_fixtures
    }
  end

  private

  def clear_fixtures
    paths = Dir.glob(Rails.root.join("fixtures/data/*.json"))
    paths.each { |path| File.delete(path) }
    paths.size
  end
end
