class Scanner
	
	#holds current line number
	@@lineNum = 0

	#method for retrieving tokens of line
	def self.GetTokens

		#get line from file and increment line num
		line = File.read("main.rav").split("\n")[@@lineNum]
		@@lineNum += 1

		#split up each character with a delimiter
		tokenArray = line.split ""

		#string handling
		stringStack = []
		i = 0
		while i < tokenArray.length
			fullString = ""
			if tokenArray[i] == '"'
				tokenArray.delete_at i
				until tokenArray[i] == '"'
					fullString += tokenArray[i]
					tokenArray.delete_at i
				end
				tokenArray[i] = "STRING%#*#"
				stringStack.push fullString
				fullString = ""
				i = 0
			end
			i += 1
		end

		line = tokenArray.join "&##%"

		#replace set tokens with new delimiter
		tokens = ["==", "!=", ">=", "<=", "+=", "-=", "*=", "/=", "<", ">", "+", "-", "*", "/", "%", "=", " ", "(", ")"]
		for tok in tokens
			delimiterArray = tok.split ""
			delimiter = delimiterArray.join "&##%"
			line.gsub!("&##%" + delimiter, "¶" + tok + "¶")
		end

		#remove all old delimiters, split up into array by new delimiter
		line.gsub!("&##%", "")
		tokenArray = line.split "¶"

		#string handling
		i = tokenArray.length - 1
		while i >= 0
			if tokenArray[i] == "STRING%#*#"
				tokenArray[i] = "\"" + stringStack.pop + "\""
			end
			i -= 1
		end

		#return after rejecting empty and whitespace values
		return tokenArray.reject {|token| token == " " || token == ""}
	end

	#method for getting the number of lines in file
	def self.NumOfLines

		#split by new line, return length
		lineArray = File.read("main.rav").split("\n")
		return lineArray.length
	end
end