class CreateThemes < ActiveRecord::Migration
  def change
    create_table :themes do |t|
      t.string :title
      t.text :url
      t.string :author
      t.text :author_url
      t.text :description
      t.string :version
      t.string :cms

      t.timestamps
    end
  end
end
