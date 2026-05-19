require "json"
require "date"
require "fileutils"

class PolicyFixtureGenerator
  INSUREDS = %w[
    acme-industries blue-river-co cobalt-foods delta-mining everglade-shipping
    fjord-energy granite-builders helios-pharma indigo-textiles jade-logistics
  ].freeze

  POLICY_HOLDERS = %w[
    nimbus-capital orion-trust pinecrest-holdings quartz-partners riverstone-group
    summit-ventures titan-finance umbra-equity vortex-asset westwind-bank
  ].freeze

  ENDORSEMENT_TYPES = %w[is_increase is_decrease cancellation].freeze
  ORIGIN_TYPE = "origin".freeze
  ALL_POLICY_TYPES = ([ORIGIN_TYPE] + ENDORSEMENT_TYPES).freeze

  POLICY_NUMBER_WIDTH = Integer(ENV.fetch("GENERATOR_POLICY_NUMBER_WIDTH", "9"))
  ENDORSEMENT_PROBABILITY = Float(ENV.fetch("GENERATOR_ENDORSEMENT_PROBABILITY", "0.6"))
  WRONG_POLICY_TYPE_PROBABILITY = Float(ENV.fetch("GENERATOR_WRONG_POLICY_TYPE_PROBABILITY", "0.1"))
  ORIGIN_ISSUE_BACKDATE_MAX_DAYS = Integer(ENV.fetch("GENERATOR_ORIGIN_ISSUE_BACKDATE_MAX_DAYS", "20"))
  ENDORSEMENT_ISSUE_GAP_MAX_DAYS = Integer(ENV.fetch("GENERATOR_ENDORSEMENT_ISSUE_GAP_MAX_DAYS", "7"))

  PT_MONTHS = %w[janeiro fevereiro marco abril maio junho julho agosto setembro outubro novembro dezembro].freeze
  PT_WEEKDAYS = %w[domingo segunda-feira terca-feira quarta-feira quinta-feira sexta-feira sabado].freeze

  TYPE_TO_PT = {
    "origin"       => "Origem",
    "is_increase"  => "Aumento",
    "is_decrease"  => "Reducao",
    "cancellation" => "Cancelamento"
  }.freeze
  PT_TO_TYPE = TYPE_TO_PT.each_with_object({}) { |(k, v), h| h[v.downcase] = k }.freeze

  def initialize(fixtures_dir: File.expand_path("data", __dir__))
    @fixtures_dir = fixtures_dir
    FileUtils.mkdir_p(@fixtures_dir)
    @policies_by_holder = load_existing_fixtures
    @last_policy_number = compute_last_origin_number
  end

  def generate(count)
    count.times { generate_one_policy }
    persist_fixtures
    shuffle_persisted_fixtures
    self
  end

  private

  def generate_one_policy
    if should_generate_endorsement?
      generate_endorsement || generate_origin_policy
    else
      generate_origin_policy
    end
  end

  def should_generate_endorsement?
    return false if eligible_policies_for_endorsement.empty?
    rand < ENDORSEMENT_PROBABILITY
  end

  def generate_origin_policy
    holder = POLICY_HOLDERS.sample
    insured = INSUREDS.sample
    amount = random_insured_amount
    start_date = random_coverage_start_date
    end_date = random_coverage_end_date(start_date)

    policy = build_policy(
      policy_number: next_origin_policy_number,
      insured: insured,
      policy_holder: holder,
      beneficiary: INSUREDS.sample,
      coverage_start_date: start_date,
      coverage_end_date: end_date,
      issue_date: random_origin_issue_date,
      policy_type: ORIGIN_TYPE,
      insured_amount: amount,
      lmg: amount
    )

    append_policy(holder, policy)
    policy
  end

  def generate_endorsement
    candidate = eligible_policies_for_endorsement.sample
    return nil unless candidate

    holder = candidate[:holder]
    origin = candidate[:origin]
    last_endorsement = candidate[:last]
    current_lmg = last_endorsement["lmg"]

    type = ENDORSEMENT_TYPES.sample
    delta = endorsement_amount_for(type, current_lmg)

    policy = build_policy(
      policy_number: next_endorsement_policy_number(holder, origin["policy_number"]),
      insured: origin["insured"],
      policy_holder: origin["policy_holder"],
      beneficiary: origin["beneficiary"],
      coverage_start_date: Date.iso8601(origin["coverage_start_date"]),
      coverage_end_date: Date.iso8601(origin["coverage_end_date"]),
      issue_date: next_endorsement_issue_date(last_endorsement),
      policy_type: maybe_corrupt_type(type),
      insured_amount: delta,
      lmg: current_lmg + delta
    )

    append_policy(holder, policy)
    policy
  end

  def build_policy(policy_number:, insured:, policy_holder:, beneficiary:,
                   coverage_start_date:, coverage_end_date:, issue_date:,
                   policy_type:, insured_amount:, lmg:)
    {
      "policy_number" => policy_number,
      "insured" => insured,
      "policy_holder" => policy_holder,
      "beneficiary" => beneficiary,
      "coverage_start_date" => coverage_start_date.iso8601,
      "coverage_end_date" => coverage_end_date.iso8601,
      "issue_date" => issue_date.iso8601,
      "policy_type" => policy_type,
      "insured_amount" => insured_amount,
      "lmg" => lmg
    }
  end

  def random_origin_issue_date
    Date.today - rand(0..ORIGIN_ISSUE_BACKDATE_MAX_DAYS)
  end

  def next_endorsement_issue_date(last_endorsement)
    Date.iso8601(last_endorsement["issue_date"]) + rand(1..ENDORSEMENT_ISSUE_GAP_MAX_DAYS)
  end

  def maybe_corrupt_type(actual_type)
    return actual_type unless rand < WRONG_POLICY_TYPE_PROBABILITY

    (ALL_POLICY_TYPES - [actual_type]).sample
  end

  def endorsement_amount_for(type, current_lmg)
    case type
    when "is_increase"   then random_insured_amount
    when "is_decrease"   then -rand(1..[current_lmg - 1, 1].max)
    when "cancellation"  then -current_lmg
    end
  end

  def eligible_policies_for_endorsement
    result = []
    @policies_by_holder.each do |holder, policies|
      group_policies_by_origin(policies).each do |_origin_number, chain|
        last = chain.last
        next if last["policy_type"] == "cancellation"
        result << { holder: holder, origin: chain.first, last: last }
      end
    end
    result
  end

  def group_policies_by_origin(policies)
    grouped = Hash.new { |h, k| h[k] = [] }
    policies.each { |p| grouped[origin_number_of(p)] << p }
    grouped.each_value { |chain| chain.sort_by! { |p| endorsement_index_of(p) } }
    grouped
  end

  def origin_number_of(policy)
    policy["policy_number"].split("-").first
  end

  def endorsement_index_of(policy)
    parts = policy["policy_number"].split("-")
    parts.length == 1 ? 0 : parts.last.to_i
  end

  def next_origin_policy_number
    @last_policy_number += 1
    format("%0#{POLICY_NUMBER_WIDTH}d", @last_policy_number)
  end

  def next_endorsement_policy_number(holder, origin_number)
    chain = @policies_by_holder[holder].select { |p| origin_number_of(p) == origin_number }
    next_index = chain.map { |p| endorsement_index_of(p) }.max + 1
    "#{origin_number}-#{next_index}"
  end

  def random_insured_amount
    rand(100..999_999)
  end

  def random_coverage_start_date
    Date.today + rand(1..30)
  end

  def random_coverage_end_date(start_date)
    start_date.next_year(rand(1..3))
  end

  def append_policy(holder, policy)
    (@policies_by_holder[holder] ||= []) << policy
  end

  def load_existing_fixtures
    fixtures = {}
    Dir.glob(File.join(@fixtures_dir, "*.json")).each do |path|
      holder = File.basename(path, ".json")
      raw = JSON.parse(File.read(path))
      fixtures[holder] = raw.map { |entry| deserialize_from_persistence(entry) }
    end
    fixtures
  end

  def compute_last_origin_number
    max = 0
    @policies_by_holder.each_value do |policies|
      policies.each do |p|
        n = origin_number_of(p).to_i
        max = n if n > max
      end
    end
    max
  end

  def persist_fixtures
    @policies_by_holder.each do |holder, policies|
      path = File.join(@fixtures_dir, "#{holder}.json")
      payload = policies.map { |p| serialize_for_persistence(p) }
      File.write(path, JSON.pretty_generate(payload))
    end
  end

  def shuffle_persisted_fixtures
    Dir.glob(File.join(@fixtures_dir, "*.json")).each do |path|
      policies = JSON.parse(File.read(path)).shuffle
      File.write(path, JSON.pretty_generate(policies))
    end
  end

  def serialize_for_persistence(policy)
    {
      "NumeroApolice"        => policy["policy_number"],
      "Segurado"             => policy["insured"],
      "Tomador"              => policy["policy_holder"],
      "Beneficiario"         => policy["beneficiary"],
      "DataInicioVigencia"   => format_date_weirdly(Date.iso8601(policy["coverage_start_date"])),
      "DataFimVigencia"      => format_date_weirdly(Date.iso8601(policy["coverage_end_date"])),
      "DataEmissao"          => format_date_weirdly(Date.iso8601(policy["issue_date"])),
      "TipoApolice"          => format_type_weirdly(policy["policy_type"]),
      "ValorSegurado"        => format_amount_weirdly(policy["insured_amount"]),
      "LimiteMaximoGarantia" => format_amount_weirdly(policy["lmg"])
    }
  end

  def deserialize_from_persistence(entry)
    {
      "policy_number"       => entry["NumeroApolice"],
      "insured"             => entry["Segurado"],
      "policy_holder"       => entry["Tomador"],
      "beneficiary"         => entry["Beneficiario"],
      "coverage_start_date" => parse_date_weird(entry["DataInicioVigencia"]).iso8601,
      "coverage_end_date"   => parse_date_weird(entry["DataFimVigencia"]).iso8601,
      "issue_date"          => parse_date_weird(entry["DataEmissao"]).iso8601,
      "policy_type"         => parse_type_weird(entry["TipoApolice"]),
      "insured_amount"      => parse_amount_weird(entry["ValorSegurado"]),
      "lmg"                 => parse_amount_weird(entry["LimiteMaximoGarantia"])
    }
  end

  def format_date_weirdly(date)
    "#{PT_WEEKDAYS[date.wday].capitalize}, #{date.day} de #{PT_MONTHS[date.month - 1].capitalize} de #{date.year}"
  end

  def parse_date_weird(value)
    return value if value.is_a?(Date)
    s = value.to_s.strip
    return Date.iso8601(s) if s.match?(/\A\d{4}-\d{2}-\d{2}\z/)
    return Date.strptime(s, "%d/%m/%Y") if s.match?(%r{\A\d{1,2}/\d{1,2}/\d{4}\z})

    cleaned = s.sub(/\A[^,]+,\s*/, "")
    if (m = cleaned.match(/(\d{1,2})\s+de\s+([\p{L}]+)\s+de\s+(\d{4})/iu))
      day = m[1].to_i
      month_name = m[2].to_s.downcase.tr("ç", "c")
      month = PT_MONTHS.index(month_name)
      raise ArgumentError, "mes invalido: #{m[2]}" unless month
      return Date.new(m[3].to_i, month + 1, day)
    end

    Date.parse(s)
  end

  def format_amount_weirdly(amount)
    whole = amount.abs
    sign = amount.negative? ? "-" : ""
    "#{sign}R$ #{thousands_pt(whole)},00"
  end

  def parse_amount_weird(value)
    return value if value.is_a?(Numeric)
    s = value.to_s.strip
    negative = s.start_with?("-")
    s = s.sub(/\A-/, "").sub(/\A\s*(R\$|BRL)\s*/i, "").strip
    if s.include?(",")
      s = s.delete(".").tr(",", ".")
    end
    num = s.to_f.round.to_i
    negative ? -num : num
  end

  def thousands_pt(n)
    n.to_s.reverse.scan(/\d{1,3}/).join(".").reverse
  end

  def format_type_weirdly(type)
    TYPE_TO_PT.fetch(type, type)
  end

  def parse_type_weird(value)
    s = value.to_s.strip.downcase
    PT_TO_TYPE[s] || (ALL_POLICY_TYPES.include?(s) ? s : s)
  end
end

if __FILE__ == $PROGRAM_NAME
  count = (ARGV.first || 10).to_i
  PolicyFixtureGenerator.new.generate(count)
  puts "Generated #{count} policies."
end
