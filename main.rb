require "./build/Scanner"
require "./build/Parser"

Scanner.NumOfLines.times do
	toks = Scanner.GetTokens
	Parser.Evaluate toks
end

Parser.Inst