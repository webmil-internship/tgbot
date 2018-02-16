Sequel.migration do
  change do
    create_table(:tasks) do
      String :date
      String :en_word
      String :uk_word
    end
  end
end
