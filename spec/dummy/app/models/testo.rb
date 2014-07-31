class Testo < ActiveRecord::Base
  has_metrics
  has_metrics :testo_metrics, class_name: "TestoMetrics", inherits: [:receipt_id]
end