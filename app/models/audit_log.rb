class AuditLog < ApplicationRecord
  ACTIONS = %w[fetch create update login invalid touch].freeze
  MERGE_STATUS_TO_ACTION = {
    invalid: 'invalid',
    new: 'create',
    updated: 'update',
    old: 'touch'
  }.freeze

  belongs_to :user
  belongs_to :auditable, polymorphic: true

  validates :action, presence: true
  validates :auditable_type, presence: true
  validates :auditable_id, presence: true

  def self.merge_log(user, record)
    return unless user.present?
    write_audit_log(
      { user: user.id,
        auditable_type: record.class.to_s,
        auditable_id: record.id,
        action: MERGE_STATUS_TO_ACTION[record.merge_status],
        time: Time.current }
    )
  end

  def self.fetch_log(user, record)
    return unless user.present?
    write_audit_log(
      { user: user.id,
        auditable_type: record.class.to_s,
        auditable_id: record.id,
        action: 'fetch',
        time: Time.current }
    )
  end

  def self.login_log(user)
    return unless user.present?
    write_audit_log(
      { user: user.id,
        auditable_type: 'User',
        auditable_id: user.id,
        action: 'login',
        time: Time.current }
    )
  end

  # ActiveRecord callbacks will not be run (if any)
  def self.create_logs_async(user, records, action, time)
    records_by_class = records.group_by { |record| record.class.to_s }

    records_by_class.each do |record_class, records_for_class|
      CreateAuditLogsWorker.perform_async({ user_id: user.id,
                                            record_class: record_class,
                                            record_ids: records_for_class.map(&:id),
                                            action: action,
                                            time: time }.to_json)
    end
  end

  def self.write_audit_log(log)
    AuditLogger.info(log.to_json)
  end
end
