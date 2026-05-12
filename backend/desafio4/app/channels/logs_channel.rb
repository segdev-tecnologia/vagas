class LogsChannel < ApplicationCable::Channel
  STREAM_NAME = "logs".freeze

  def subscribed
    stream_from STREAM_NAME
  end

  def unsubscribed
  end

  def self.broadcast_line(line, level: "info")
    ActionCable.server.broadcast(STREAM_NAME, { line: line, level: level, timestamp: Time.now.iso8601 })
  end
end
