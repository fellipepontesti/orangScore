class AddUuidToPublicResources < ActiveRecord::Migration[7.1]
  TABLES = %i[users ligas jogos grupos].freeze

  def up
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    TABLES.each do |table|
      add_column table, :uuid, :uuid, default: -> { "gen_random_uuid()" }
      execute <<~SQL.squish
        UPDATE #{table}
        SET uuid = gen_random_uuid()
        WHERE uuid IS NULL
      SQL
      change_column_null table, :uuid, false
      add_index table, :uuid, unique: true
    end
  end

  def down
    TABLES.reverse_each do |table|
      remove_index table, :uuid
      remove_column table, :uuid
    end
  end
end
