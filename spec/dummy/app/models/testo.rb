class Testo < ActiveRecord::Base
  has_metrics
  has_metrics :testo_metrics, class_name: "TestoMetrics", inherits: [:receipt_id]
  has_metrics :testo2_metrics, class_name: "TestoMetrics", foreign_key: :testo
  has_metrics :custom_metrics, class_name: "TestoMetrics", foreign_key: nil
end
