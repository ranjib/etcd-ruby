# Encoding: utf-8

require 'net/http'

unless ::URI.respond_to?(:encode_www_form)
  # Monkey-patch Ruby 1.8.7 to minimize impact on etcd-ruby codebase.
  module URI
    # rubocop:disable MethodLength
    def self.encode_www_form(enum)
      enum.map do |k, v|
        if v.nil?
          encode(k.to_s)
        elsif v.respond_to?(:to_ary)
          v.to_ary.map do |w|
            str = encode(k.to_s)
            unless w.nil?
              str << '='
              str << encode(w.to_s)
            end
          end.join('&')
        else
          str = encode(k.to_s)
          str << '='
          str << encode(v.to_s)
        end
      end.join('&')
    end
    # rubocop:enable MethodLength
  end
end
