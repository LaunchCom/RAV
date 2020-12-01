class Scanner
	@@lineNum = 0
	def self.GetTokens
		line = File.read("main.rav").split("\n")[@@lineNum]
		@@lineNum += 1
		tokenArray = line.split ""
		line = tokenArray.join "&##%"
		tokens = ["==", "!=", ">=", "<=", "+=", "-=", "*=", "/=", "+", "-", "*", "/", "=", " "]
		for tok in tokens
			delimiterArray = tok.split ""
			delimiter = delimiterArray.join "&##%"
			line.gsub!("&##%" + delimiter, "¶" + tok + "¶")
		end
		line.gsub!("&##%", "")
		tokenArray = line.split "¶"
		return tokenArray.reject {|token| token == " " || token == ""}
	end
	def self.NumOfLines
		lineArray = File.read("main.rav").split("\n")
		return lineArray.length
	end
end