local Stack = {}
Stack.__index = Stack
Stack.new = function()
	local NewStack = setmetatable({}, Stack)
	NewStack.Stack = {}
	NewStack.Length = 0
	return NewStack
end
Stack.FromTable = function(Table)
	local NewStack = Stack.new()
	NewStack.Queue = Table
	NewStack.Length = #Table
	return NewStack
end

function Stack:Push(Item)
	self.Length = self.Length + 1
	self.Top = Item
	self.Stack[self.Length] = Item
end

function Stack:Peek()
	return self.Top
end

function Stack:Pop()
	self.Length = self.Length - 1
	local Top = table.remove(self.Stack)
	self.Top = self.Stack[self.Length]
	return Top
end

function Stack:IsEmpty()
	return self.Length == 0
end

return Stack
