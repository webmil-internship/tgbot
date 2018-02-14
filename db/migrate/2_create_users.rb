Sequel.migration do
  change do
    create_table(:users) do
      Integer :id
      String :user_name
    end
  end
end
