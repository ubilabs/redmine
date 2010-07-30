class AddProjectBranchesToRepositories < ActiveRecord::Migration
  def self.up
    add_column :repositories, :project_branches, :string
  end

  def self.down
    remove_column :repositories, :project_branches
  end
end
