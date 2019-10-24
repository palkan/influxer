# frozen_string_literal: true

shared_context "precision:seconds", precision: :s do
  around do |ex|
    old_precision = Influxer.config.time_precision
    Influxer.config.time_precision = "s"
    ex.run
    Influxer.config.time_precision = old_precision
  end
end

shared_context "with_duration_suffix", duration_suffix: true do
  around do |ex|
    old_duration = Influxer.config.time_duration_suffix_enabled
    Influxer.config.time_duration_suffix_enabled = true
    ex.run
    Influxer.config.time_duration_suffix_enabled = old_duration
  end
end
