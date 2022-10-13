# frozen_string_literal: true

# :nocov:
# rubocop:disable Style/TopLevelMethodDefinition
module Runger
end

$runger_redis = Redis.new(db: 2)

class Runger::RungerConfig
  include Singleton

  CONFIG_KEYS = %w[log_ar_trace log_expensive_queries pause_sidekiq].map(&:freeze).freeze

  CONFIG_KEYS.each do |config_key|
    define_method("#{config_key}?") do
      memoize_settings_from_redis
      instance_variable_get("@#{config_key}")
    end
  end

  def memoize_settings_from_redis
    CONFIG_KEYS.each do |config_key|
      instance_variable_set("@#{config_key}", setting_in_redis(config_key))
    end
  end

  def setting_in_redis(setting_name)
    JSON($runger_redis.get(setting_name) || 'false')
  end

  def set_in_redis(key, value)
    $runger_redis.set(key, value)
    true
  end

  def as_json
    CONFIG_KEYS.index_with do |key|
      setting(key)
    end
  end

  def setting(key)
    instance_variable_get("@#{key}")
  end

  def print_config
    max_key_length = CONFIG_KEYS.map(&:size).max
    CONFIG_KEYS.sort.map do |key|
      value = setting_in_redis(key)
      puts("#{key.ljust(max_key_length + 1).yellow}: #{value ? value.to_s.green : value.to_s.red}")
    end
    nil
  end
end

module Runger
  def self.config
    @config ||= Runger::RungerConfig.instance
  end
end

def show_runger_config
  Runger.config.print_config
end

Runger::RungerConfig::CONFIG_KEYS.each do |runger_config_key|
  define_method("#{runger_config_key}!") do
    Runger.config.set_in_redis(runger_config_key, true)
    show_runger_config
    true
  end

  define_method("un#{runger_config_key}!") do
    Runger.config.set_in_redis(runger_config_key, false)
    show_runger_config
    true
  end
end

# rubocop:disable Layout/LineLength
# ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, start, finish, _id, payload|
#   if (
#     (Runger.config.log_expensive_queries? && defined?(Rails::Server)) ||
#       Runger.config.log_ar_trace?
#   )
#     david_runger_caller_lines =
#       caller.select { |filename| filename.include?('/david_runger/') }.presence || caller
#     david_runger_caller_lines_until_logging =
#       david_runger_caller_lines.
#         take_while { |line| line.exclude?('config/initializers/logging.rb') }.
#         presence || david_runger_caller_lines
#   end

#   if Runger.config.log_expensive_queries? && defined?(Rails::Server)
#     time = finish - start
#     $runger_expensive_queries ||= {}
#     $runger_expensive_queries[time] = [
#       "#{payload[:sql]} #{payload[:binds].map { |b| [b.name, b.value] }}",
#       david_runger_caller_lines_until_logging,
#       time,
#     ]
#   end

#   # log_ar_trace!
#   if Runger.config.log_ar_trace?
#     puts
#     puts "#{payload[:sql]} #{payload[:binds].map { |b| [b.name, b.value] }}"
#     # puts "#{finish - start} sec"
#     puts
#     puts '^ the above query was triggered by the below stack trace \/'
#     puts
#     # puts caller
#     puts david_runger_caller_lines_until_logging
#     puts
#     puts "#{'*' * 50}\n"
#   end
# end
# rubocop:enable Layout/LineLength

if ::Rails.env.development? && $PROGRAM_NAME.include?('sidekiq')
  puts('setting Sidekiq logging to aggressive mode')
  logger = ::Logger.new($stdout, formatter: Logger::Formatter.new)
  ::Rails.logger.extend(::ActiveSupport::Logger.broadcast(logger))
end

def long_skip! ;
  $stop_skipping_at = 20.seconds.from_now ;
end

def skip_for!(seconds) ;
  $stop_skipping_at = seconds.seconds.from_now ;
end

def d ;
  system('clear') ;
end

def ume
  User.find(1)
end

module FixtureBuilder
  class Builder
    module RungerPatches
      protected

      def dump_tables
        puts
        super
      end
    end
    prepend RungerPatches
  end

  class Namer
    module RungerPatches
      def name(custom_name, *model_objects)
        print "#{custom_name} "
        super
      end
    end
    prepend RungerPatches
  end
end

class Array
  def rgc
    each_with_object(Hash.new(0)) { |e, h| h[e] += 1 ; h }.sort_by { |key, _value| key }.to_h
  end

  def rgcb
    each_with_object(Hash.new(0)) { |e, h| h[e] += 1 ; h }.sort_by { |_key, value| -1 * value }.to_h
  end
end

def jpf(file)
  JSON.parse(File.read(file))
end

if Rails.env.test?
  class ActiveRecord::Base
    module RungerPatches
      def inspect
        original = super
        (original.size > 200) ? "#{self.class.name}:#{id}" : original
      end
    end
    prepend RungerPatches
  end

  class RSpec::Core::Metadata::HashPopulator
    private

    def description_separator(parent_part, child_part)
      if parent_part.is_a?(Module) && child_part =~ /^(#|::|\.)/
        ''
      else
        ' / '
      end
    end
  end
end

class Rollbar::Notifier
  module RungerPatch
    def color(level)
      case level
      when 'info', 'debug' then :blue
      when 'warn', 'warning' then :yellow
      else :red
      end
    end

    def header(level)
      color = color(level)
      "Rollbar #{level}:".public_send(color)
    end

    def error_log(level, args)
      message, exception, extra, context = extract_arguments(args)
      item = build_item(level, message, exception, extra, context)
      error_class, error_message =
        item.build_data.dig(:body, :trace, :exception).presence&.values_at(:class, :message)

      case
      when exception.present?
        ([exception.inspect.public_send(color(level))] + (exception.backtrace || [])).join("\n")
      when error_class.present? && error_message.present?
        "#{error_class}: #{error_message}"
      else
        message || 'NO MESSAGE'
      end
    end

    def log(level, *args)
      super_result = super

      if super_result == 'disabled'
        puts(<<~LOG)

          #{'▽  ▽  ▽  ▽  ▽  ▽  ▽  ▽  ▽  ▽  ▽  ▽'.public_send(color(level))}
          #{header(level)}
          #{error_log(level, args)}
          #{'△  △  △  △  △  △  △  △  △  △  △  △'.public_send(color(level))}

        LOG

      end

      super_result
    end
  end

  prepend(RungerPatch) if Rails.env.development?
end
# rubocop:enable Style/TopLevelMethodDefinition
# :nocov:
