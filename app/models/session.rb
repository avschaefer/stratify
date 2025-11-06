class Session < ApplicationRecord
  belongs_to :user

  before_create :generate_token, :set_expiration

  def expired?
    return true if expires_at.nil?
    expires_at < Time.current
  end

  def self.cleanup_expired
    where('expires_at < ?', Time.current).delete_all
  end

  private

  def generate_token
    self.token = SecureRandom.hex(32)
  end

  def set_expiration
    self.expires_at = 30.days.from_now
  end
end

