class Env

	# method to hash identifiers
	def self.Hash identifier

		# initialize virtual address, get array of characters
		address = 0
		letters = identifier.split ""

		# find sum of the ascii encoding for each letter
		for letter in letters
			address += letter.ord
		end

		# return the address within a scope of 1000
		return address % 1000
	end
end