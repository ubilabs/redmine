class AddGithubUrlToRepositories < ActiveRecord::Migration
  def self.up
    add_column :repositories, :github_url, :string
  end

  def self.down
    remove_column :repositories, :github_url
  end
end
