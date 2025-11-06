# frozen_string_literal: true

# Query object for filtering portfolios by asset type
module Portfolios
  class ByAssetTypeQuery
    def initialize(user, asset_type: nil)
      @user = user
      @asset_type = asset_type
    end
    
    def call
      relation = @user.portfolios
      relation = relation.where(asset_type: @asset_type) if @asset_type.present?
      relation
    end
  end
  
  # Query object for calculating portfolio values efficiently
  class ValueQuery
    def initialize(user)
      @user = user
    end
    
    def call
      @user.portfolios
        .select('portfolios.*, (COALESCE(portfolios.purchase_price, 0) * COALESCE(portfolios.quantity, 0)) as calculated_value')
    end
    
    def total_value
      @user.portfolios.sum do |p|
        (p.purchase_price || 0) * (p.quantity || 0)
      end
    end
  end
  
  # Query object for active portfolios
  class ActiveQuery
    def initialize(user)
      @user = user
    end
    
    def call
      @user.portfolios.where(status: 'active')
    end
  end
end

