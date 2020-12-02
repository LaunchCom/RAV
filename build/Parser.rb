require "./build/Env"

class Parser

	#init instruction code array, stack pointer, instruction pointer
	@@instructions = []
	@@sp = 0
	@@ip = 0

	#method for parsing through operators
	def self.Operator opType, instrArray
		opA = instrArray[@@ip - 1]
		opB = instrArray[@@ip + 1]
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
		end
		instrArray.delete_at @@ip - 1
		instrArray.delete_at @@ip
		instrArray[@@ip - 1] = "%r" + @@sp.to_s
		@@sp += 1
		@@ip = 0
	end

	#method for evaluating expressions
	def self.ExpEval instrArray
		while @@ip < instrArray.length
			if instrArray[@@ip] == "*"
				Parser.Operator "*", instrArray
			elsif instrArray[@@ip] == "/"
				Parser.Operator "/", instrArray
			elsif instrArray[@@ip] == "%"
				Parser.Operator "%", instrArray
			end
			@@ip += 1
		end
		@@ip = 0
		while @@ip < instrArray.length
			if instrArray[@@ip] == "+"
				Parser.Operator "+", instrArray
			elsif instrArray[@@ip] == "-"
				Parser.Operator "-", instrArray
			end
			@@ip += 1
		end
	end

	def self.Evaluate instrArray
		tokens = instrArray
		template = []
		index = 0
		paranIndex = -1
		while index < tokens.length
			if tokens[index] == "("
				until tokens[index] == ")"
					if tokens[index] == "("
						paranIndex = index
					end
					index += 1
				end
				index = paranIndex + 1
				until tokens[index] == ")"
					template.push tokens[index]
					index += 1
				end
				index = paranIndex
				until tokens[index] == ")"
					tokens.delete_at index
				end
				tokens[index] = "EXP"
				Parser.ExpEval template
				tokens.map! {|tok| tok == "EXP" ? "%r" + (@@sp - 1).to_s : tok}
				template.clear
				index = 0
			elsif !(tokens.include? "(")
				Parser.ExpEval tokens
				break
			end
			index += 1
		end
	end

	#delete this later
	def self.Inst
		puts @@instructions
	end
end