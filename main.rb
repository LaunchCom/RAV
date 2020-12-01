require "./build/Scanner"

Scanner.NumOfLines.times do
	puts Scanner.GetTokens.join " "
	puts "------"
end