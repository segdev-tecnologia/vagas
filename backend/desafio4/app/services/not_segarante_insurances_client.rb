class NotSegaranteInsurancesClient
  PAGE_SIZE = Integer(ENV.fetch("EXTERNAL_PAGE_SIZE", "10"))
  FIXTURES_DIR = Rails.root.join("fixtures", "data")

  def fetch_policies(policy_holder:, offset: 0, limit: PAGE_SIZE)
    all_policies = load_fixture(policy_holder)
    window = all_policies.slice(offset, limit) || []

    {
      policies: window,
      offset: offset,
      limit: limit,
      total: all_policies.size,
      has_more: (offset + window.size) < all_policies.size
    }
  end

  private

  def load_fixture(policy_holder)
    path = FIXTURES_DIR.join("#{policy_holder}.json")
    return [] unless File.exist?(path)

    JSON.parse(File.read(path))
  end
end
