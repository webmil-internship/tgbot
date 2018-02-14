Sequel.migration do
  change do
    create_table(:tasks) do
      String :date
      Integer :id_word
    end
  end
end
