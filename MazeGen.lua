--not the most efficient, but it works and it works fine.
--can handle 16800 cells on a crappy laptop like mines
--you still obviously need the Stack class

local Stack = require(game.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("List"):WaitForChild("Stack.mod.lua"))
local MainContainer = script.Parent:WaitForChild("MainMazeFrame")
local Generate = script.Parent:WaitForChild("Generate")
local DEBUG = false

local CellSize = 20
local FitX = math.floor(MainContainer.AbsoluteSize.X/CellSize)
local FitY = math.floor(MainContainer.AbsoluteSize.Y/CellSize)
local Heartbeat = game:GetService("RunService").Heartbeat
local CanGenerate = true

local Walls = {}
local UnvisitedCells = {}
local AllCells = {}
local UnvisitedAmount = FitX*FitY

local function GetIndex(X,Y)
	return "("..X..","..Y..")"
end
local function GetCoords(Index)
	return Index:match("(%-?%d+),(%-?%d+)")
end
local function Sum(...)
	local Args = {...}
	local Len = #Args
	local Sum = 0
	for Index = 1,Len do
		Sum = Sum + tonumber(Args[Index])
	end
	return Sum, Len
end
local function Mean(...)
	local Sum, Len = Sum(...)
	return Sum/Len
end

--//MAZE GENERATION AND RENDERING \\\

local function Clear()
	local Children = MainContainer:GetChildren()
	local Count = 0
	for Index = 1,#Children do
		Count = Count + 1
		Children[Index]:Destroy()
		if Count % 10 == 0 then
			Heartbeat:Wait()
		end
	end
	FitX = math.floor(MainContainer.AbsoluteSize.X/CellSize)
	FitY = math.floor(MainContainer.AbsoluteSize.Y/CellSize)
	Walls = {}
	AllCells = {}
	UnvisitedCells = {}
	UnvisitedAmount = FitX*FitY
end

local tIn = table.insert
local function GetNeighbours(X,Y)
	local Neighbours = {}
	tIn(Neighbours, UnvisitedCells[GetIndex(X - 1, Y)])
	tIn(Neighbours, UnvisitedCells[GetIndex(X + 1, Y)])
	tIn(Neighbours, UnvisitedCells[GetIndex(X, Y - 1)])
	tIn(Neighbours, UnvisitedCells[GetIndex(X, Y + 1)])
	return Neighbours, #Neighbours
end

local function GetWallIndex(Cell1, Cell2)
	local C1 = Sum(GetCoords(Cell1))
	local C2 = Sum(GetCoords(Cell2))
	local OrigC1, OrigC2 = Cell1, Cell2
	Cell1 = C1 >= C2 and OrigC1 or OrigC2
	Cell2 = C1 >= C2 and OrigC2 or OrigC1
	return Cell2..Cell1
end

local function InitializeMaze()
	for X = 0,FitX - 1 do
		for Y = 0,FitY - 1 do
			local Coords = GetIndex(X, Y)
			UnvisitedCells[Coords] = Coords
			AllCells[Coords] = Coords
			if X - 1 >= 0 then
				Walls[GetWallIndex(GetIndex(X - 1, Y), Coords)] = true
			end
			if Y - 1 >= 0 then
				Walls[GetWallIndex(GetIndex(X, Y - 1), Coords)] = true
			end
		end
	end
end

local Pointer = Instance.new("Frame")
Pointer.Size = UDim2.new(0, CellSize, 0, CellSize)
Pointer.BackgroundColor3 = Color3.new(1,1,1)
Pointer.BorderSizePixel = 0
Pointer.Name = "Pointer"
Pointer.Position = UDim2.new(0, -CellSize, 0, 0)
Pointer.ZIndex = 10

local function GenerateMaze()
	if DEBUG then
		Pointer.Position = UDim2.new(0, -CellSize, 0, 0)
		Pointer.Parent = MainContainer
	end
	local MazeStack = Stack.new()
	local Total = FitX*FitY
	local Current, Prev = "(0,0)"
	while UnvisitedAmount > 0 do
		if DEBUG then
			Heartbeat:Wait()
			local X, Y = GetCoords(Current)
			Pointer.Position = UDim2.new(0, X*CellSize, 0, Y*CellSize)
			Pointer.BackgroundColor3 = Color3.fromRGB(170, 255, 0)
		end
		MazeStack:Push(Current)
		UnvisitedCells[Current] = nil
		UnvisitedAmount = UnvisitedAmount - 1
		if UnvisitedAmount <= 0 then break end
		Generate.Text = "Generating maze: "..math.floor(((Total - UnvisitedAmount)/Total)*100) .."%"
		local Neighbours, Len = GetNeighbours(GetCoords(Current))
		while Len == 0 do
			Prev = Current
			Current = MazeStack:Pop()
			Neighbours, Len = GetNeighbours(GetCoords(Current))
			if DEBUG then
				local X, Y = GetCoords(Current)
				Pointer.Position = UDim2.new(0, X*CellSize, 0, Y*CellSize)
				Pointer.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
				Heartbeat:Wait()
			end
		end
		local Next = Neighbours[math.random(1, Len)]
		Walls[GetWallIndex(Current, Next)] = nil
		Prev, Current = Current, Next
	end
	if DEBUG then
		Pointer.Parent = script
	end
end

local WallTemplate = Instance.new("Frame")
WallTemplate.BackgroundColor3 = Color3.new(0,0,0)
WallTemplate.Size = UDim2.new(0, 1, 0, CellSize)
WallTemplate.ZIndex = 10
WallTemplate.BorderSizePixel = 0
WallTemplate.AnchorPoint = Vector2.new(0, 0)
local RotSize = UDim2.new(0, CellSize, 0, 1)

local Count = 0
local function Draw()
	Count = 0
	Generate.Text = "Drawing walls."
	for i,v in pairs(Walls) do
		if v then
			Count = Count + 1
			local Cell1, Cell2 = i:match("(%(.-%))(%(.-%))")
			local C1X, C1Y = GetCoords(Cell1)
			local C2X, C2Y = GetCoords(Cell2)
			local MeanX, MeanY = math.ceil(Mean(C1X, C2X)), math.ceil(Mean(C1Y, C2Y))
			
			local NewWall = WallTemplate:Clone()
			NewWall.Name = i
			NewWall.Position = UDim2.new(0, MeanX*CellSize, 0, MeanY*CellSize)
			if C1X == C2X then
				NewWall.Size = RotSize
			end
			NewWall.Parent = MainContainer
			if Count % 10 == 0 then
				Heartbeat:Wait()
			end
		end
	end
end

script.Parent:WaitForChild("Clear").MouseButton1Click:Connect(Clear)
Generate.MouseButton1Click:Connect(function()
	if CanGenerate then
		CanGenerate = false
		Clear()
		InitializeMaze()
		GenerateMaze()
		Draw()
		Generate.Text = "Generate"
		CanGenerate = true
	end
end)
