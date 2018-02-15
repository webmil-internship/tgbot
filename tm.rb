require_relative 'boot'

words = Word.all

words.each do |w|
	puts "#{w.en_word}, #{w.uk_word}"
end
