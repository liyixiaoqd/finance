class MyResponse
	attr_accessor :body,:code
	
	def initialize(code="408",body="failure")
		@code=code
		@body=body
	end
end