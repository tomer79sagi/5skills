class AddBookmarkletSessionTokenToPerson < ActiveRecord::Migration
  def self.up
    add_column :people, :bookmarklet_session_token, :string
  end

  def self.down
    remove_column :people, :bookmarklet_session_token
  end
end
