class CreateFeedbacks < ActiveRecord::Migration[8.0]
  def change
    create_table :feedbacks do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :rating_net_promoter  # 0-10 NPS score
      t.text :message  # user feedback text

      t.timestamps
    end
  end
end

