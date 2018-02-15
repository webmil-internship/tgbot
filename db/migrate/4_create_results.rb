Sequel.migration do
  change do
    create_table(:results) do
      Integer :id_user
      String  :date
      String  :en_word
      String  :tag        # тег ідентифікації
      Float   :confidence # точність тега
    end
  end
end
