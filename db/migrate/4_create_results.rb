Sequel.migration do
  change do
    create_table(:results) do
      Integer :id_user
      String  :date_task
      String  :tag        # тег ідентифікації
      Float   :confidence # точність тега
    end
  end
end
