# Encoding: utf-8

require 'json'

# Provides Etcd namespace
module Etcd
  # Represents all etcd custom errors
  class Error < StandardError
    attr_reader :cause, :error_code, :index

    def initialize(opts = {})
      super(opts['message'])
      @cause = opts['cause']
      @index = opts['index']
      @error_code = opts['errorCode']
    end

    def self.from_http_response(response)
      opts = JSON.parse(response.body)
      unless ERROR_CODE_MAPPING.key?(opts['errorCode'])
        fail "Unknown error code: #{opts['errorCode']}"
      end
      ERROR_CODE_MAPPING[opts['errorCode']].new(opts)
    end

    def inspect
      "<#{self.class}: index:#{index}, code:#{error_code}, cause:'#{cause}'>"
    end
  end

  # command related error
  class KeyNotFound < Error; end
  class TestFailed < Error; end
  class NotFile < Error; end
  class NoMorePeer < Error; end
  class NotDir < Error; end
  class NodeExist < Error; end
  class KeyIsPreserved < Error; end
  class DirNotEmpty < Error; end

  # Post form related error
  class ValueRequired < Error; end
  class PrevValueRequired < Error; end
  class TTLNaN < Error; end
  class IndexNaN < Error; end

  # Raft related error
  class RaftInternal < Error; end
  class LeaderElect < Error; end

  # Etcd related error
  class WatcherCleared < Error; end
  class EventIndexCleared < Error; end

  ERROR_CODE_MAPPING = {
    # command related error
    100 => KeyNotFound,
    101 => TestFailed,
    102 => NotFile,
    103 => NoMorePeer,
    104 => NotDir,
    105 => NodeExist,
    106 => KeyIsPreserved,
    108 => DirNotEmpty,

    # Post form related error
    200 => ValueRequired,
    201 => PrevValueRequired,
    202 => TTLNaN,
    203 => IndexNaN,

    # Raft related error
    300 => RaftInternal,
    301 => LeaderElect,

    # Etcd related error
    400 => WatcherCleared,
    401 => EventIndexCleared
  }
end
