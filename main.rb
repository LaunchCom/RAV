require "./build/Scanner"
require "./build/Parser"
require "./build/Vm"

rawCode = Scanner.ReadFile "main.rav"
linkedCode = Scanner.Redirect rawCode

Scanner.NumOfLines(linkedCode).times do
	toks = Scanner.GetTokens linkedCode
	Parser.Evaluate toks
	Parser.ResetState
end

Vm.Execute Parser.Instructions