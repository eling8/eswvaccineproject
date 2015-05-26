class Writer 
	def initialize
	end 

	def write(message)
		test_file = File.new("test.txt", "w") 
		test_file.puts(message) 
		test_file.close
	end 
end 

puts("testing file writing")
x = Writer.new()
x.write("Testing")
