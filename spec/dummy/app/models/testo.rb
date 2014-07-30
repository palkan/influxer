class Testo < ActiveRecord::Base
  has_metrics
  has_metrics :testo_metrics, as: :stats
end