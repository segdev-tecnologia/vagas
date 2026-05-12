class Policy < ApplicationRecord
  POLICY_TYPES = %w[origin is_increase is_decrease cancellation].freeze
  ENDORSEMENT_TYPES = %w[is_increase is_decrease cancellation].freeze

  belongs_to :origin_policy, class_name: "Policy", optional: true
  has_many :endorsements, class_name: "Policy", foreign_key: :origin_policy_id, dependent: :restrict_with_error

  validates :policy_number, presence: true, uniqueness: true
  validates :insured, :policy_holder, :beneficiary, presence: true
  validates :coverage_start_date, :coverage_end_date, :issue_date, presence: true
  validates :policy_type, presence: true, inclusion: { in: POLICY_TYPES }
  validates :insured_amount, :lmg, presence: true, numericality: true

  scope :origins, -> { where(policy_type: "origin") }
  scope :endorsements_only, -> { where(policy_type: ENDORSEMENT_TYPES) }
  scope :for_policy_holder, ->(holder) { where(policy_holder: holder) }

  def origin_number
    policy_number.split("-").first
  end

  def endorsement_index
    parts = policy_number.split("-")
    parts.length == 1 ? 0 : parts.last.to_i
  end

  def origin?
    policy_type == "origin"
  end

  def endorsement?
    ENDORSEMENT_TYPES.include?(policy_type)
  end

  def cancellation?
    policy_type == "cancellation"
  end
end
