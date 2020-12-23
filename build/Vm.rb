require "./build/Env"

class Vm
	def self.Execute targetCode
		regA = 0
		regB = 0
		resultStack = []
		ram = []
		regSP = 0
		regCS = 0
		regES = 900
		regIP = 0
		codeLength = targetCode.length
		functionScope = "NULL"

		while targetCode[regIP] != ".fnmain"
			regIP += 1
		end

		while regIP < codeLength
			instruction = targetCode[regIP].split " "
			opCode = instruction[0]

			if opCode == "MOV" && targetCode[regIP].include?('"')
				opA = instruction[1]
				opB = targetCode[regIP][7..-1]
			else
				opA = instruction[1] ? instruction[1] : "NULL"
				opB = instruction[2] ? instruction[2] : "NULL"
			end

			case opCode

				# move instruction
				when "MOV"

					# get value from operand as immediate, string, or register
					val = opB
					if opB =~ /\$\d+/
						val = opB[1...opB.length].to_i
					elsif opB =~ /".*"/
						val = opB[1...opB.length - 1]
					elsif opB =~ /%r\d+/
						val = resultStack[opB[2...opB.length].to_i]
					end

					# store value in designated register
					case opA
						when "%a"
							regA = val
						when "%b"
							regB = val
						when "%sp"
							if val == "<STACK>"
								regSP = regES
							else
								regSP = val.to_i
							end
						when "%cs"
							regCS = regIP
						else
							resultLevel = opA[2...opA.length].to_i
							resultStack[resultLevel] = val
					end
				
				# store instruction
				when "STR"
					ram[opA.to_i] = regA

				# load instruction
				when "LOD"
					case opA
						when "%a"
							regA = ram[opB.to_i]
						when "%b"
							regB = ram[opB.to_i]
						else
							resultLevel = opA[2...opA.length].to_i
							resultStack[resultLevel] = ram[opB.to_i]
					end

				# push instruction
				when "PSH"
					if opA !~ /\D+/
						ram[regSP] = opA.to_i
					else
						ram[regSP] = ram[Env.Hash(opA)]
					end
					regSP += 1

				# pop instruction
				when "POP"
					regSP -= 1
					ram[opA.to_i] = ram[regSP]
					ram.delete_at regSP

				# add instruction
				when "ADD"
					resultLevel = opA[2...opA.length].to_i
					resultStack[resultLevel] = regA + regB

				# subtract instructoin
				when "SUB"
					resultLevel = opA[2...opA.length].to_i
					resultStack[resultLevel] = regA - regB

				# multiply instructoin
				when "MUL"
					resultLevel = opA[2...opA.length].to_i
					resultStack[resultLevel] = regA * regB

				# divide instructoin
				when "DIV"
					resultLevel = opA[2...opA.length].to_i
					resultStack[resultLevel] = regA / regB

				# modulate instruction
				when "MOD"
					resultLevel = opA[2...opA.length].to_i
					resultStack[resultLevel] = regA % regB

				# compare if equal instruction
				when "CE"
					resultLevel = opA[2...opA.length].to_i
					resultStack[resultLevel] = regA == regB

				# compare if not equal instruction
				when "CNE"
					resultLevel = opA[2...opA.length].to_i
					resultStack[resultLevel] = regA != regB

				# compare if less than instruction
				when "CL"
					resultLevel = opA[2...opA.length].to_i
					resultStack[resultLevel] = regA < regB

				# compare if less than or equal instruction
				when "CLE"
					resultLevel = opA[2...opA.length].to_i
					resultStack[resultLevel] = regA <= regB

				# compare if greater than instruction
				when "CG"
					resultLevel = opA[2...opA.length].to_i
					resultStack[resultLevel] = regA > regB

				# compare if greater than or equal instruction
				when "CGE"
					resultLevel = opA[2...opA.length].to_i
					resultStack[resultLevel] = regA >= regB

				# goto instruction
				when "GTO"
					regIP = 0
					until targetCode[regIP] == opA
						regIP += 1
					end
					functionScope = opA[3...opA.length]

				# conditional jump instruction
				when "JCC"
					resultLevel = opB[2...opB.length].to_i
					unless resultStack[resultLevel]
						until targetCode[regIP] == opA
							regIP += 1	
						end
					end

				# jump instruction
				when "JMP"
					if opA =~ /\.strt\d+/
						until targetCode[regIP] == opA
							regIP -= 1
						end
					else
						regIP += 2
						until targetCode[regIP] == opA
							regIP += 1
						end
					end

				# return instruction
				when "RET"
					resultLevel = opA[2...opA.length].to_i
					ram[Env.Hash functionScope ] = resultStack[resultLevel]
					regIP = regCS
					until targetCode[regIP] =~ /GTO.+/
						regIP += 1
					end

				# call instruction
				when "CAL"
					case opA.to_i
						when 0
							puts resultStack[0]
					end

				# halt instruction
				when "HLT"
					break

			end

			regIP += 1
		end
	end
end