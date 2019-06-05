class Mention < ApplicationRecord
  belongs_to :user
  belongs_to :mentionable, polymorphic: true

  validates :user_id, presence: true,
                      uniqueness: { scope: %i[mentionable_id
                                              mentionable_type] }
  validates :mentionable_id, presence: true
  validates :mentionable_type, presence: true
  validate :permission
  after_create :send_email_notification

  class << self
    def create_all(notifiable)
      Mentions::CreateAllJob.perform_later(notifiable.id, notifiable.class.name)
    end

    def create_all_without_delay(notifiable)
      Mentions::CreateAllJob.perform_now(notifiable.id)
    end
  end

  def send_email_notification
    Mentions::SendEmailNotificationJob.perform_later(id) if User.find(user_id).email.present? && User.find(user_id).email_mention_notifications
  end

  def send_email_notification_without_delay
    Mentions::SendEmailNotificationJob.perform_now(id) if User.find(user_id).email.present? && User.find(user_id).email_mention_notifications
  end

  def permission
    errors.add(:mentionable_id, "is not valid.") unless mentionable.valid?
  end
end
