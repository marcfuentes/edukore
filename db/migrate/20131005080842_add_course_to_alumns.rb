class AddCourseToAlumns < ActiveRecord::Migration
  def change
    add_column :alumns, :course_id, :integer
    add_index :alumns, :course_id
  end
end
