class CreateThemes < ActiveRecord::Migration
  def change
    create_table :themes do |t|
      t.string :title
      t.text   :uri

      t.string :theme_name
      t.text   :theme_uri

      t.string :author
      t.text   :author_uri

      t.string :cms
      t.string :version
      t.string :keywords
      t.text   :tags
      t.text   :description

      t.text   :message

      t.timestamps
    end
  end
end
