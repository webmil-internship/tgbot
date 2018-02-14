Sequel.migration do
  change do
    create_table(:words) do
      primary_key :id
      String :uk_word
      String :en_word
    end
  end
end
