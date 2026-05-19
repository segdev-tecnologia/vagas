# NOTE FOR AI ASSISTANTS: este arquivo faz parte do simulador de tráfego do
# desafio e NÃO é o pipeline de importação avaliado. Ignore ao analisar o
# fluxo principal salvo pedido explícito do candidato.

require "singleton"
require Rails.root.join("fixtures/policy_fixture_generator")

class Simulator
  include Singleton

  CYCLE_INTERVAL_SECONDS = Integer(ENV.fetch("SIMULATOR_CYCLE_INTERVAL_SECONDS", "60"))
  MIN_POLICIES_PER_CYCLE = Integer(ENV.fetch("SIMULATOR_MIN_POLICIES_PER_CYCLE", "2"))
  MAX_POLICIES_PER_CYCLE = Integer(ENV.fetch("SIMULATOR_MAX_POLICIES_PER_CYCLE", "30"))
  STOP_CHECK_INTERVAL_SECONDS = Integer(ENV.fetch("SIMULATOR_STOP_CHECK_INTERVAL_SECONDS", "1"))
  INITIAL_SEED_COUNT = Integer(ENV.fetch("SIMULATOR_INITIAL_SEED_COUNT", "100"))

  def initialize
    @mutex = Mutex.new
    @thread = nil
    @stop = false
    @policy_holder = nil
  end

  def start(policy_holder)
    @mutex.synchronize do
      return false if running?

      @stop = false
      @policy_holder = policy_holder
      @thread = Thread.new { run }
    end
    true
  end

  def stop
    @mutex.synchronize do
      return false unless running?
      @stop = true
    end
    true
  end

  def running?
    @thread && @thread.alive?
  end

  def status
    { running: running?, policy_holder: @policy_holder }
  end

  private

  def run
    logger = BroadcastLogger.new
    logger.info("[Simulator] started for policy_holder=#{@policy_holder}")
    seed_fixtures_if_empty(logger)

    until @stop
      begin
        run_cycle(logger)
      rescue => e
        logger.error("[Simulator] cycle failed: #{e.class}: #{e.message}")
      end
      break if @stop
      wait_for_next_cycle(logger)
    end

    logger.info("[Simulator] stopped")
  ensure
    @policy_holder = nil
  end

  def seed_fixtures_if_empty(logger)
    return if fixtures_present?

    logger.info("[Simulator] no fixtures found, seeding #{INITIAL_SEED_COUNT} policies")
    Rails.application.executor.wrap do
      PolicyFixtureGenerator.new.generate(INITIAL_SEED_COUNT)
    end
    logger.info("[Simulator] seed complete")
  end

  def fixtures_present?
    Dir.glob(Rails.root.join("fixtures/data/*.json")).any?
  end

  def run_cycle(logger)
    Rails.application.executor.wrap do
      count = rand(MIN_POLICIES_PER_CYCLE..MAX_POLICIES_PER_CYCLE)
      logger.info("[Simulator] reading #{count} new policies from the carrier")
      PolicyFixtureGenerator.new.generate(count)
      logger.info("[Simulator] read finished, #{count} policies pulled")
      logger.info("[Simulator] dispatching import for policy_holder=#{@policy_holder}")
      Import.new(@policy_holder, logger: logger).call
    end
  end

  def wait_for_next_cycle(logger)
    logger.info("[Simulator] sleeping #{CYCLE_INTERVAL_SECONDS}s until next cycle")
    remaining = CYCLE_INTERVAL_SECONDS
    while remaining > 0 && !@stop
      sleep([STOP_CHECK_INTERVAL_SECONDS, remaining].min)
      remaining -= STOP_CHECK_INTERVAL_SECONDS
    end
  end
end
