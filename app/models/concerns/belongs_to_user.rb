# frozen_string_literal: true

# Concern for models that belong to a user
# Provides validation and scoping methods
module BelongsToUser
  extend ActiveSupport::Concern
  
  included do
    belongs_to :user
    
    # Validate user ownership
    validate :user_present
  end
  
  # Check if record belongs to a specific user
  def belongs_to_user?(user)
    user_id == user.id
  end
  
  private
  
  def user_present
    errors.add(:user, "must be present") unless user_id.present?
  end
end

