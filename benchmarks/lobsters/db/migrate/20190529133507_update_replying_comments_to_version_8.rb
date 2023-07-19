class UpdateReplyingCommentsToVersion8 < ActiveRecord::Migration[5.2]
  def change
    update_view :replying_comments, version: 8, revert_to_version: 7
  end
end
