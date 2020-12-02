class Env
	def self.Hash identifier
		address = 0
		letters = identifier.split ""
		for letter in letters
			address += letter.ord
		end
		return address % 1000
	end
end