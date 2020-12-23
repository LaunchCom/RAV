require "./build/Env"

class Parser

	# init instruction code array, stack pointer, instruction pointer, labels
	@@instructions = []
	@@sp = 0
	@@ip = 0
	@@startLbl = 0
	@@endLbl = -1

	# method for parsing through operators
	def self.Operator opType, instrArray

		# get both operands
		opA = instrArray[@@ip - 1].strip
		opB = instrArray[@@ip + 1].strip

		if opType != "="
			# determine if operand is immediate, register, or address
			if opA !~ /\D/
				@@instructions.push "MOV %a $" + opA
			elsif opA =~ /%r\d+/ || opB =~ /".*"/
				@@instructions.push "MOV %a " + opA
			elsif opA =~ /.+\.\d+/
				address = opA.delete("^0-9")
				identifier = opA.delete(".0-9")
				@@instructions.push "LOD %a " + (Env.Hash(identifier) + address.to_i).to_s
			else
				@@instructions.push "LOD %a " + (Env.Hash opA).to_s
			end
			if opB !~ /\D/
				@@instructions.push "MOV %b $" + opB
			elsif opB =~ /%r\d+/ || opB =~ /".*"/
				@@instructions.push "MOV %b " + opB
			elsif opB =~ /.+\.\d+/
				address = opB.delete("^0-9")
				identifier = opB.delete(".0-9")
				@@instructions.push "LOD %b " + (Env.Hash(identifier) + address.to_i).to_s
			else
				@@instructions.push "LOD %b " + (Env.Hash opB).to_s
			end
		else
			if opB !~ /\D/
				@@instructions.push "MOV %a $" + opB
			elsif opB =~ /%r\d+/ || opB =~ /".*"/
				@@instructions.push "MOV %a " + opB
			elsif opB =~ /.+\.\d+/
				address = opB.delete("^0-9")
				identifier = opB.delete(".0-9")
				@@instructions.push "LOD %a " + (Env.Hash(identifier) + address.to_i).to_s
			else
				@@instructions.push "LOD %a " + (Env.Hash opB).to_s
			end
		end
		
		# determine the operator instruction
		case opType
			when "*"
				@@instructions.push "MUL %r" + @@sp.to_s
			when "/"
				@@instructions.push "DIV %r" + @@sp.to_s
			when "%"
				@@instructions.push "MOD %r" + @@sp.to_s
			when "+"
				@@instructions.push "ADD %r" + @@sp.to_s
			when "-"
				@@instructions.push "SUB %r" + @@sp.to_s
			when "=="
				@@instructions.push "CE %r" + @@sp.to_s
			when "!="
				@@instructions.push "CNE %r" + @@sp.to_s
			when ">"
				@@instructions.push "CG %r" + @@sp.to_s
			when ">="
				@@instructions.push "CGE %r" + @@sp.to_s
			when "<"
				@@instructions.push "CL %r" + @@sp.to_s
			when "<="
				@@instructions.push "CLE %r" + @@sp.to_s
			when "="
				if opA =~ /.+\.\d+/
					address = opA.delete("^0-9")
					identifier = opA.delete(".0-9")
					@@instructions.push "STR " + (Env.Hash(identifier) + address.to_i).to_s + " %a"
				else
					@@instructions.push "STR " + (Env.Hash opA).to_s + " %a"
				end
		end

		# delete finished operator and operands, replace with result
		instrArray.delete_at @@ip - 1
		instrArray.delete_at @@ip
		instrArray[@@ip - 1] = "%r" + @@sp.to_s

		# reset instruction pointer, increment stack pointer
		@@sp += 1
		@@ip = 0
	end

	# method for evaluating expressions
	def self.ExpEval instrArray

		if instrArray.length == 1 && instrArray[0] != "}"
			opA = instrArray[0]
			if opA !~ /\D/
				@@instructions.push "MOV %r" + @@sp.to_s + " $" + opA
			elsif opA =~ /.+\.\d+/
				address = opA.delete("^0-9")
				identifier = opA.delete(".0-9")
				@@instructions.push "LOD %r" + @@sp.to_s + " " + (Env.Hash(identifier) + address.to_i).to_s
			else
				@@instructions.push "LOD %r" + @@sp.to_s + " " + (Env.Hash opA).to_s
			end
			@@sp += 1
		end

		# parse through tokens
		while @@ip < instrArray.length

			# evaluate multiplicative operators
			if instrArray[@@ip] == "*"
				Parser.Operator "*", instrArray
			elsif instrArray[@@ip] == "/"
				Parser.Operator "/", instrArray
			elsif instrArray[@@ip] == "%"
				Parser.Operator "%", instrArray
			end
			@@ip += 1
		end

		# reset instruction pointer, evaluate additive operators
		@@ip = 0
		while @@ip < instrArray.length
			if instrArray[@@ip] == "+"
				Parser.Operator "+", instrArray
			elsif instrArray[@@ip] == "-"
				Parser.Operator "-", instrArray
			end
			@@ip += 1
		end

		# reset instruction pointer, evaluate comparative operators
		@@ip = 0
		while @@ip < instrArray.length
			if instrArray[@@ip] == "=="
				Parser.Operator "==", instrArray
			elsif instrArray[@@ip] == "!="
				Parser.Operator "!=", instrArray
			elsif instrArray[@@ip] == ">"
				Parser.Operator ">", instrArray
			elsif instrArray[@@ip] == ">="
				Parser.Operator ">=", instrArray
			elsif instrArray[@@ip] == "<"
				Parser.Operator "<", instrArray
			elsif instrArray[@@ip] == "<="
				Parser.Operator "<=", instrArray
			end
			@@ip += 1
		end

		# reset instruction pointer, evaluate assignment operators
		@@ip = 0
		while @@ip < instrArray.length
			if instrArray[@@ip] == "="
				Parser.Operator "=", instrArray
			end
			@@ip += 1
		end
	end

	# method for evaluating each full line
	def self.Evaluate instrArray

		# initialize tokens, template strand, indices
		tokens = instrArray
		template = []
		index = 0
		paranIndex = -1

		# remove unnecessary whitespace
		for tok in tokens
			tok.strip!
		end

		# insert labels at control structures
		if tokens[0] == "while"
			@@instructions.push ".strt" + @@startLbl.to_s
			@@startLbl += 1
			@@endLbl += 1
		elsif tokens[0] == "if"
			@@startLbl += 1
			@@endLbl += 1
		elsif tokens[0] == "fn"
			@@startLbl += 1
			@@endLbl += 1
			@@instructions.push ".fn" + tokens[1]
			parameterIndex = tokens.length - 3
			while tokens[parameterIndex] != "("
				if tokens[parameterIndex] != ","
					@@instructions.push "POP " + Env.Hash(tokens[parameterIndex]).to_s
				end
				parameterIndex -= 1
			end

		elsif tokens[0] == "asm"
			externalInstruction = tokens[1][1...tokens[1].length - 1]
			@@instructions.push externalInstruction

		# insert end labels at closing structures
		elsif tokens[0] == "}"
			@@instructions.push ".end" + @@endLbl.to_s
			@@startLbl -= 1
			@@endLbl -= 1
		end

		# handle else structures
		if tokens[0] == "else" || tokens[1] == "else"
			@@startLbl += 1
			@@endLbl += 1
			@@instructions.insert(@@instructions.length - 1, "JMP .end" + @@endLbl.to_s + " 2")
		end

		# handle function calls
		argumentIndex = 0
		while argumentIndex < tokens.length
			if tokens[argumentIndex] =~ /.+\.call/
				identifier = tokens[argumentIndex][0...tokens[argumentIndex].length - 5]
				tokens[argumentIndex] = identifier
				@@instructions.push "MOV %sp <STACK>"
				@@instructions.push "MOV %cs <CODE>"
				argumentIndex += 1
				while tokens[argumentIndex] != ")"
					if tokens[argumentIndex] != "," && tokens[argumentIndex] != "("
						@@instructions.push "PSH " + tokens[argumentIndex]
					end
					argumentIndex += 1
				end
				@@instructions.push "GTO .fn" + identifier
				break
			end
			argumentIndex += 1
		end

		# parse through tokens
		while index < tokens.length

			# if paranthetical is found
			if tokens[index] == "("

				# parse to inner-most paranthetical
				until tokens[index] == ")"
					if tokens[index] == "("
						paranIndex = index
					end
					index += 1
				end

				# copy paranthetical to template strand
				index = paranIndex + 1
				until tokens[index] == ")"
					template.push tokens[index]
					index += 1
				end

				# delete copied paranthetical, replace with placeholder
				index = paranIndex
				until tokens[index] == ")"
					tokens.delete_at index
				end
				tokens[index] = "EXP"

				# evaluate paranthetical
				Parser.ExpEval template

				# replace placeholder with evaluated result
				tokens.map! {|tok| tok == "EXP" ? "%r" + (@@sp - 1).to_s : tok}

				# clear template strand, reset index
				template.clear
				index = 0

			# if no parantheticals are found, evaluate the entire expression
			elsif !(tokens.include? "(")
				if tokens[3] =~ /\[.*\]/
					fullArray = tokens[3]
					fullArray[0] = ""
					fullArray[fullArray.length - 1] = ""
					fullArray = fullArray.split ","
					@@instructions.push "MOV %sp " + (Env.Hash tokens[1]).to_s
					for el in fullArray
						@@instructions.push "PSH " + el.strip
					end
				else
					Parser.ExpEval tokens
				end
				break
			end
			index += 1
		end
		# branch at conditional, or return
			if tokens[tokens.length - 1] == "{" && !((tokens.include? "else") || (tokens.include? "fn"))
				@@instructions.push("JCC .end" + (@@endLbl).to_s + " %r" + (@@sp - 1).to_s)
			elsif tokens[0] == "return"
				@@instructions.push "RET %r" + (@@sp - 1).to_s
			end
	end

	# method to reset all pointers
	def self.ResetState
		@@sp = 0
		@@ip = 0
	end

	# method to generate target code, return it
	def self.Instructions

		# create counters, find length of instruction code
		i = 0
		j = 0
		lngth = @@instructions.length

		# parse through instructions
		while i < lngth

			# find nearest end label after start labels
			if @@instructions[i] =~ /\.strt\d+/
				j = i
				
				# find scope level of current label
				scopeLevel = @@instructions[i].scan(/\d+/).to_s[2]
				while j < lngth

					# if end label is found and incomplete, insert branch, increment counters
					if @@instructions[j] == ".end" + scopeLevel && @@instructions[j - 1] !~ /JMP \.strt\d+/
						@@instructions.insert(j, "JMP .strt" + scopeLevel)
						lngth += 1
						i += 1
						j += 1
						break
					end
					j += 1
				end
			end
			i += 1
		end

		@@instructions.push "HLT"

		return @@instructions
	end
end