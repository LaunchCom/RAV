class Scanner
	
	# holds current line number
	@@lineNum = 0

	# method for retrieving tokens of line
	def self.GetTokens rawCode

		# get line from file and increment line num
		line = rawCode.split("\n")[@@lineNum]
		@@lineNum += 1

		# split up each character with a delimiter
		tokenArray = line.split ""

		# set up string and array bays
		stringStack = []
		arrayStack = []
		i = 0
		while i < tokenArray.length
			fullString = ""
			fullArray = ""

			# if string is encountered, copy it to stack
			if tokenArray[i] == '"'
				tokenArray.delete_at i
				until tokenArray[i] == '"'
					fullString += tokenArray[i]
					tokenArray.delete_at i
				end

				# replace with placeholder
				tokenArray[i] = "STRING%#*#"
				stringStack.push fullString
				fullString = ""
				i = 0

			# if array is encountered, copy it to stack
			elsif tokenArray[i] == "["
				tokenArray.delete_at i
				until tokenArray[i] == "]"
					fullArray += tokenArray[i]
					tokenArray.delete_at i
				end

				# replace it with placeholder
				tokenArray[i] = "ARRAY%#*#"
				arrayStack.push fullArray
				fullArray = ""
				i = 0
			end
			i += 1
		end

		line = tokenArray.join "&##%"

		# replace set tokens with new delimiter
		tokens = ["==", "!=", ">=", "<=", "+=", "-=", "*=", "/=", "<", ">", "+", "-", "*", "/", "%", "=", " ", "(", ")", ",", ";"]
		for tok in tokens
			delimiterArray = tok.split ""
			delimiter = delimiterArray.join "&##%"
			line.gsub!("&##%" + delimiter, "¶" + tok + "¶")
		end

		# remove all old delimiters, split up into array by new delimiter
		line.gsub!("&##%", "")
		tokenArray = line.split "¶"

		# replace string and array placeholders with value
		i = tokenArray.length - 1
		while i >= 0
			if tokenArray[i] == "STRING%#*#"
				tokenArray[i] = "\"" + stringStack.pop + "\""
			end
			i -= 1
		end
		i = tokenArray.length - 1
		while i >= 0
			if tokenArray[i] == "ARRAY%#*#"
				tokenArray[i] = "[" + arrayStack.pop + "]"
			end
			i -= 1
		end

		# return after rejecting empty and whitespace values
		return tokenArray.reject {|token| token == " " || token == ""}
	end

	# method for getting the number of lines in file
	def self.NumOfLines rawCode

		# split by new line, return length
		lineArray = rawCode.split("\n")
		return lineArray.length
	end

	# method for reading entire file contents
	def self.ReadFile fileName
		fileContents = File.read(fileName)
		return fileContents
	end

	# method for external directory
	def self.Redirect rawCode
		lines = rawCode.split "\n"
		line = 0
		numOfLines = lines.length
		while line < numOfLines
			toks = lines[line].split " "
			if toks[0] == "import"
				newCode = Scanner.ReadFile toks[1]
				lines[line] = newCode
			end
			line += 1
		end
		return lines.join "\n"
	end
end