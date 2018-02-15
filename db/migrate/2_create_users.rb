Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id
      Integer :user_id
      String :user_name
      Boolean :is_active
    end
  end
end
