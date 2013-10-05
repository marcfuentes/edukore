class CreateAlumns < ActiveRecord::Migration
  def change
    create_table :alumns do |t|
      t.integer :rut
      t.string :name
      t.string :matern
      t.string :patern
      t.string :picture

      t.timestamps
    end
  end
end
