class BroadcastLogger
  LEVELS = %i[debug info warn error fatal unknown].freeze

  def initialize(delegate: Rails.logger)
    @delegate = delegate
  end

  LEVELS.each do |level|
    define_method(level) do |message = nil, &block|
      text = (message || block&.call).to_s
      stream_line(text, level)
      @delegate.public_send(level, text)
    end
  end

  def add(severity, message = nil, progname = nil, &block)
    text = (message || (block && block.call) || progname).to_s
    level = LEVELS[severity] || :info
    stream_line(text, level)
    @delegate.add(severity, message, progname, &block)
  end

  def <<(message)
    stream_line(message.to_s, :info)
    @delegate << message
  end

  private

  def stream_line(text, level)
    text.to_s.each_line do |line|
      LogsChannel.broadcast_line(line.chomp, level: level.to_s)
    end
  end
end
