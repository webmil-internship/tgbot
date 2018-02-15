Sequel.migration do
  change do
    create_table(:tasks) do
      String :date
      String :en_word
    end
  end
end
