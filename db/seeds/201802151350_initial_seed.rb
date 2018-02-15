Sequel.seed do # Wildcard Seed; applies to every environment
  def run
    [
      ['tree', 'дерево'],
      ['car', 'автомобіль'],
      ['bus', 'автобус'],
      ['cup', 'чашка'],
      ['table', 'стіл']
    ].each do |e, u|
      Word.create en_word: e, uk_word: u
    end
  end
end
