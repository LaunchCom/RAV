require "./build/Env"

class Parser

	#init instruction code array, stack pointer, instruction pointer
	@@instructions = []
	@@sp = 0
	@@ip = 0

	#method for parsing through operators
	def self.Operator opType, instrArray

		#get both operands
		opA = instrArray[@@ip - 1]
		opB = instrArray[@@ip + 1]

		#determine if operand is immediate, register, or address
		if opA !~ /\D/
			@@instructions.push "MOV %a $" + opA
		elsif opA =~ /%r\d+/
			@@instructions.push "MOV %a " + opA
		else
			@@instructions.push "LOD %a " + (Env.Hash opA).to_s
		end
		if opB !~ /\D/
			@@instructions.push "MOV %b $" + opB
		elsif opB =~ /%r\d+/
			@@instructions.push "MOV %b " + opB
		else
			@@instructions.push "LOD %b " + (Env.Hash opB).to_s
		end
		
		#determine the operator instruction
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
		end

		#delete finished operator and operands, replace with result
		instrArray.delete_at @@ip - 1
		instrArray.delete_at @@ip
		instrArray[@@ip - 1] = "%r" + @@sp.to_s

		#reset instruction pointer, increment stack pointer
		@@sp += 1
		@@ip = 0
	end

	#method for evaluating expressions
	def self.ExpEval instrArray

		#parse through tokens
		while @@ip < instrArray.length

			#evaluate multiplicative operators
			if instrArray[@@ip] == "*"
				Parser.Operator "*", instrArray
			elsif instrArray[@@ip] == "/"
				Parser.Operator "/", instrArray
			elsif instrArray[@@ip] == "%"
				Parser.Operator "%", instrArray
			end
			@@ip += 1
		end

		#reset instruction pointer, evaluate additive operators
		@@ip = 0
		while @@ip < instrArray.length
			if instrArray[@@ip] == "+"
				Parser.Operator "+", instrArray
			elsif instrArray[@@ip] == "-"
				Parser.Operator "-", instrArray
			end
			@@ip += 1
		end

		#reset instruction pointer, evaluate comparative operators
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
	end

	def self.Evaluate instrArray

		#initialize tokens, template strand, indices
		tokens = instrArray
		template = []
		index = 0
		paranIndex = -1

		#parse through tokens
		while index < tokens.length

			#if paranthetical is found
			if tokens[index] == "("

				#parse to inner-most paranthetical
				until tokens[index] == ")"
					if tokens[index] == "("
						paranIndex = index
					end
					index += 1
				end

				#copy paranthetical to template strand
				index = paranIndex + 1
				until tokens[index] == ")"
					template.push tokens[index]
					index += 1
				end

				#delete copied paranthetical, replace with placeholder
				index = paranIndex
				until tokens[index] == ")"
					tokens.delete_at index
				end
				tokens[index] = "EXP"

				#evaluate paranthetical
				Parser.ExpEval template

				#replace placeholder with evaluated result
				tokens.map! {|tok| tok == "EXP" ? "%r" + (@@sp - 1).to_s : tok}

				#clear template strand, reset index
				template.clear
				index = 0

			#if no parantheticals are found, evaluate the entire expression
			elsif !(tokens.include? "(")
				Parser.ExpEval tokens
				break
			end
			index += 1
		end
	end

	#method to reset all pointers, return instruction code
	def self.Instructions
		@@sp = 0
		@@ip = 0
		return @@instructions
	end
end