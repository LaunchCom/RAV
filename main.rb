require "./build/Scanner"
require "./build/Error"
require "./build/Parser"
require "./build/Vm"

# linker
rawCode = Scanner.ReadFile "main.rav"
linkedCode = Scanner.Link rawCode

#Error.Test linkedCode

# parser
Scanner.NumOfLines(linkedCode).times do
	toks = Scanner.GetTokens linkedCode
	Parser.Evaluate toks
	Parser.ResetState
end

# run through virtual machine
Vm.Execute Parser.Instructions