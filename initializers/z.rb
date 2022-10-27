# frozen_string_literal: true

# This is a Rails initializer with various patches/utilities that improve the Rails development
# experience. It's called `z.rb` so that it runs after all other initializers (since they are
# executed alphatebically).

# :nocov:
# rubocop:disable Style/TopLevelMethodDefinition
module Runger
end

# Flipper features to always enable (since Flipper features sometimes get cleared by flushing Redis)
if Rails.env.development?
  %i[disable_prerendering].each do |feature|
    Flipper.enable(feature)
  end
end

$runger_redis = Redis.new(db: 2)

class Runger::RungerConfig
  include Singleton

  CONFIG_KEYS = %w[log_ar_trace log_expensive_queries].map(&:freeze).freeze

  CONFIG_KEYS.each do |config_key|
    define_method("#{config_key}?") do
      unless $runger_config_last_memoized_at && $runger_config_last_memoized_at >= 1.second.ago
        memoize_settings_from_redis
      end
      instance_variable_get("@#{config_key}")
    end
  end

  def memoize_settings_from_redis
    $runger_config_last_memoized_at = Time.current
    CONFIG_KEYS.each do |config_key|
      instance_variable_set("@#{config_key}", setting_in_redis(config_key))
    end
  end

  def setting_in_redis(setting_name)
    JSON($runger_redis.get(setting_name) || 'false')
  end

  def set_in_redis(key, value, clear_memo: false)
    $runger_redis.set(key, value)
    $runger_config_last_memoized_at = nil if clear_memo
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

  define_method("with_#{runger_config_key}") do |&block|
    original_value = Runger.config.setting_in_redis(runger_config_key)
    Runger.config.set_in_redis(runger_config_key, true, clear_memo: true)

    block.call
  ensure
    Runger.config.set_in_redis(runger_config_key, original_value, clear_memo: true)
  end
end

ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, start, finish, _id, payload|
  log_expensive_queries = Runger.config.log_expensive_queries? && defined?(Rails::Server)
  log_ar_trace = Runger.config.log_ar_trace?

  if log_expensive_queries || log_ar_trace
    david_runger_caller_lines =
      caller.select { |filename| filename.include?('/david_runger/') }.presence || caller
    david_runger_caller_lines_until_logging =
      david_runger_caller_lines.
        take_while { |line| line.exclude?('config/initializers/z.rb') }.
        presence || david_runger_caller_lines
  end

  if log_expensive_queries
    time = finish - start
    $runger_expensive_queries ||= {}
    $runger_expensive_queries[time] = [
      "#{payload[:sql]} #{payload[:binds].map { |b| [b.name, b.value] }}",
      david_runger_caller_lines_until_logging,
    ]
  end

  if log_ar_trace
    puts
    puts("#{payload[:sql]} #{payload[:binds].map { |b| [b.name, b.value] }}".blue)
    puts(<<~LOG.squish)
      ^ the above query (took #{(finish - start).round(3).to_s.red} sec)
      was triggered by the below stack trace \\/
    LOG
    puts(david_runger_caller_lines_until_logging.map(&:yellow))
    puts("#{'-' * 100}\n")
  end
end

ActiveSupport::Notifications.subscribe('process_action.action_controller') do |*args|
  next unless Runger.config.log_expensive_queries?

  payload = args.extract_options!

  controller_name = payload[:controller]
  next if controller_name == 'AnonymousController' # this occurs in tests

  puts("\nMost expensive queries:")
  $runger_expensive_queries.sort.last(3).each do |time, (query, backtrace)|
    puts("#{time.round(3).to_s.red} seconds")
    puts(query.blue)
    puts(backtrace.map(&:yellow))
    puts
  end

  $runger_expensive_queries = {}
end

# This creates duplicate logs in sidekiq. Figure out a better way to show ActiveRecord queries.
# if ::Rails.env.development? && $PROGRAM_NAME.include?('sidekiq')
#   puts('setting Sidekiq logging to aggressive mode')
#   logger = ::Logger.new($stdout, formatter: Logger::Formatter.new)
#   ::Rails.logger.extend(::ActiveSupport::Logger.broadcast(logger))
# end

def skip_for!(seconds) ;
  $stop_skipping_at = seconds.seconds.from_now ;
end

def d ;
  system('clear') ;
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

      header =
        case
        when exception.present?
          exception.inspect
        when error_class.present? && error_message.present?
          "#{error_class}: #{error_message}"
        else
          message || 'NO MESSAGE'
        end

      if extra.present?
        header << "\n#{extra}"
      end

      if context.present?
        header << "\n#{context}"
      end

      message = header.public_send(color(level))

      if exception.present?
        message << "\n#{(exception.backtrace || []).join("\n")}"
      end

      message
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
