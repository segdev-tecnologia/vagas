module Importations
  class Import
    BATCH_SIZE = Integer(ENV.fetch("IMPORT_BATCH_SIZE", "10"))
    SIMULATED_LATENCY_SECONDS = Float(ENV.fetch("IMPORT_PAGE_LATENCY_SECONDS", "5"))
    SIMULATED_POLICY_LATENCY_SECONDS = Float(ENV.fetch("IMPORT_POLICY_LATENCY_SECONDS", "2"))

    POLICY_ATTRIBUTES = %w[
      policy_number insured policy_holder beneficiary
      coverage_start_date coverage_end_date issue_date
      policy_type insured_amount lmg
    ].freeze

    def initialize(policy_holder, client: External::NotSegaranteInsurancesClient.new, logger: BroadcastLogger.new)
      @policy_holder = policy_holder
      @client = client
      @logger = logger
      @offset = 0
      @stats = { imported: 0, duplicated: 0, errors: 0 }
    end

    def call
      log_start
      loop do
        page = fetch_next_page
        log_page(page)
        process_batch(page[:policies])
        break unless page[:has_more]

        @offset += BATCH_SIZE
      end
      log_finish
      @stats
    end

    private

    def fetch_next_page
      # Artificial 5-second delay to simulate the latency of a real remote API call.
      sleep(SIMULATED_LATENCY_SECONDS)
      @client.fetch_policies(policy_holder: @policy_holder, offset: @offset, limit: BATCH_SIZE)
    end

    def process_batch(policies)
      policies.each { |attrs| process_policy(attrs) }
    end

    def process_policy(attrs)
      @logger.info("[Import] importando nova apolice #{attrs["policy_number"]}")
      # Artificial per-policy delay to simulate processing latency.
      sleep(SIMULATED_POLICY_LATENCY_SECONDS)

      if endorsement_payload?(attrs)
        import_endorsement(attrs)
      else
        import_origin(attrs)
      end
    end

    def endorsement_payload?(attrs)
      attrs["policy_number"].include?("-")
    end

    def import_origin(attrs)
      number = attrs["policy_number"]

      if Policy.exists?(policy_number: number)
        log_duplicate(number)
        return
      end

      Policy.create!(sanitize(attrs))
      @stats[:imported] += 1
      @logger.info("[Import] origin #{number} imported")
    end

    def import_endorsement(attrs)
      number = attrs["policy_number"]
      origin_number = number.split("-").first
      origin = Policy.find_by(policy_number: origin_number)

      return log_missing_origin(number) unless origin
      return log_duplicate(number) if Policy.exists?(policy_number: number)
      return log_missing_previous_endorsements(number) unless previous_endorsements_present?(origin, number)

      Policy.create!(sanitize(attrs).merge(origin_policy_id: origin.id))
      @stats[:imported] += 1
      @logger.info("[Import] endorsement #{number} imported (origin #{origin_number})")
    end

    def previous_endorsements_present?(origin, current_number)
      current_index = current_number.split("-").last.to_i
      return true if current_index <= 1

      existing_indexes = origin.endorsements.pluck(:policy_number).map do |n|
        n.split("-").last.to_i
      end

      (1...current_index).all? { |idx| existing_indexes.include?(idx) }
    end

    def sanitize(attrs)
      attrs.slice(*POLICY_ATTRIBUTES)
    end

    def log_start
      @logger.info("[Import] starting import for policy_holder=#{@policy_holder}")
    end

    def log_finish
      @logger.info("[Import] done: imported=#{@stats[:imported]} duplicated=#{@stats[:duplicated]} errors=#{@stats[:errors]}")
    end

    def log_page(page)
      @logger.info("[Import] fetched page offset=#{page[:offset]} size=#{page[:policies].size} total=#{page[:total]}")
    end

    def log_duplicate(number)
      @stats[:duplicated] += 1
      @logger.warn("[Import] policy #{number} already imported (duplicated)")
    end

    def log_missing_origin(number)
      @stats[:errors] += 1
      @logger.error("[Import] endorsement #{number}: apolice original nao existe no sistema")
    end

    def log_missing_previous_endorsements(number)
      @stats[:errors] += 1
      @logger.error("[Import] endorsement #{number}: previous endorsements have not been imported")
    end
  end
end
