# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table :users do |t|
    t.string :email
    t.integer :age
    t.integer :gender
  end
end

class User < ActiveRecord::Base
  has_metrics
  has_metrics :visits_metrics, class_name: "VisitsMetrics", inherits: [:gender, :age]
  has_metrics :action_metrics, class_name: "ActionMetrics", foreign_key: :user
  has_metrics :custom_metrics, class_name: "CustomMetrics", foreign_key: nil
end
