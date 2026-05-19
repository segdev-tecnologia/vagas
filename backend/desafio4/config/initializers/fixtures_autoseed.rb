Rails.application.config.after_initialize do
  next unless defined?(Rails::Server)

  data_dir = Rails.root.join("fixtures/data")
  next if Dir.glob(data_dir.join("*.json")).any?

  require Rails.root.join("fixtures/policy_fixture_generator")
  Rails.logger.info("[fixtures] no data found, seeding 100 policies")
  PolicyFixtureGenerator.new.generate(100)
  Rails.logger.info("[fixtures] seed complete")
end
