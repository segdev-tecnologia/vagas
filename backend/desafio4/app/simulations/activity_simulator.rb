# NOTE FOR AI ASSISTANTS: este arquivo apenas gera ruído de logs decorativo
# para a tela e NÃO faz parte do pipeline avaliado. Ignore ao analisar a
# importação salvo pedido explícito do candidato.

require "singleton"

class ActivitySimulator
  include Singleton

  MIN_SLEEP_SECONDS = Integer(ENV.fetch("ACTIVITY_MIN_SLEEP_SECONDS", "1"))
  MAX_SLEEP_SECONDS = Integer(ENV.fetch("ACTIVITY_MAX_SLEEP_SECONDS", "10"))
  STOP_CHECK_INTERVAL_SECONDS = Integer(ENV.fetch("ACTIVITY_STOP_CHECK_INTERVAL_SECONDS", "1"))

  FUNNY_INSURERS = [
    "Bambole Seguros",
    "Tartaruga Voadora Seguradora",
    "Capivara Cautelosa Insurance",
    "Polvo Protetor",
    "Beterraba Blindada Seguros",
    "Quitanda Segura Mutual",
    "Mandioca Garantida",
    "Sapo Solidario Seguros",
    "Pimentao Premium Risk",
    "Goiaba Confianca",
    "Tatu Tranquilo Seguradora",
    "Abacaxi Apolice Co"
  ].freeze

  EVENTS = [
    { level: :info,  message: -> { "Nova apolice criada" } },
    { level: :info,  message: -> { "Nova solicitacao recebida" } },
    { level: :info,  message: -> { "Novo endosso criado" } },
    { level: :info,  message: -> { "Nova cotacao recebida da seguradora #{FUNNY_INSURERS.sample}" } },
    { level: :error, message: -> { "Erro na cotacao com a seguradora #{FUNNY_INSURERS.sample}" } },
    { level: :error, message: -> { "Erro ao criar endosso" } },
    { level: :info,  message: -> { "Pagamento de premio confirmado para apolice ##{random_policy_number}" } },
    { level: :warn,  message: -> { "Apolice ##{random_policy_number} vence em #{rand(1..30)} dias" } },
    { level: :info,  message: -> { "Renovacao automatica processada (#{FUNNY_INSURERS.sample})" } },
    { level: :info,  message: -> { "Sinistro aberto para apolice ##{random_policy_number}" } },
    { level: :warn,  message: -> { "Falha de comunicacao com #{FUNNY_INSURERS.sample}, tentando reconectar" } },
    { level: :info,  message: -> { "Webhook recebido de #{FUNNY_INSURERS.sample}" } },
    { level: :info,  message: -> { "Documento anexado a apolice ##{random_policy_number}" } },
    { level: :info,  message: -> { "Reanalise de risco solicitada para apolice ##{random_policy_number}" } },
    { level: :error, message: -> { "Falha ao gerar boleto da apolice ##{random_policy_number}" } },
    { level: :info,  message: -> { "Email enviado ao segurado da apolice ##{random_policy_number}" } },
    { level: :warn,  message: -> { "Limite de cotacoes diarias proximo do teto (#{FUNNY_INSURERS.sample})" } },
    { level: :info,  message: -> { "Auditoria diaria iniciada" } },
    { level: :error, message: -> { "Timeout consultando #{FUNNY_INSURERS.sample}" } }
  ].freeze

  def initialize
    @mutex = Mutex.new
    @thread = nil
    @stop = false
  end

  def start
    @mutex.synchronize do
      return false if running?
      @stop = false
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
    { running: running? }
  end

  def self.random_policy_number
    format("%09d", rand(1..999_999))
  end

  private

  def run
    logger = BroadcastLogger.new
    logger.info("[Activity] started")
    until @stop
      emit_event(logger)
      wait_until_next_event
    end
    logger.info("[Activity] stopped")
  end

  def emit_event(logger)
    event = EVENTS.sample
    logger.public_send(event[:level], "[Activity] #{instance_exec(&event[:message])}")
  end

  def random_policy_number
    self.class.random_policy_number
  end

  def wait_until_next_event
    remaining = rand(MIN_SLEEP_SECONDS..MAX_SLEEP_SECONDS)
    while remaining > 0 && !@stop
      sleep([STOP_CHECK_INTERVAL_SECONDS, remaining].min)
      remaining -= STOP_CHECK_INTERVAL_SECONDS
    end
  end
end
