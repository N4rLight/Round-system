--Example points
local spawnPoint = workspace:WaitForChild("Spawn")
local points = {
	workspace:WaitForChild("Point1");
	workspace:WaitForChild("Point2");
	workspace:WaitForChild("Point3");
	workspace:WaitForChild("Point4");
}

--Remote
local updateUIRemote = game:GetService("ReplicatedStorage").Remotes.Events.RoundDataChanged

--Functions which spawn players randomly
local function shufflePlayers(players : {Players})
	--Checking if there enough points
	if #players > #points then
		error("Not enough spawn points for players!!!")
	end
	
	--Creating a copy of points table
	local freePoints = {unpack(points)}
	
	--Looping through every player in round
	for i : number, player : Player in players do
		--Getting character
		local char = player.Character
		if char then
			--Getting random point
			local randPos = math.random(1, #freePoints)
			local point = freePoints[randPos]
			
			--Teleporting player to the point
			char:PivotTo(point.CFrame * CFrame.new(0, .5, 0))
			
			--Removing the point from the table copy so it won't be used twice
			table.remove(freePoints, randPos)
		end
	end
end

--Function which return all of the players in round to spawn
local function returnPlayers2Spawn(players : {Players})
	for i : number, player : Player in players do
		local char = player.Character
		if char then
			char:PivotTo(spawnPoint.CFrame * CFrame.new(0, .5, 0))
		end
	end
end

local Round = {}
Round.__index = Round

--Round constructor
function Round.new(status : string, time : number)
	local newRound = {}
	newRound.Status = status :: string
	newRound.Timer = time :: number
	newRound.Players = {} :: {Players}
	newRound.Winner = nil :: Player
	newRound.ForceEnd = false
	newRound.EndTimer = false
	
	setmetatable(newRound, Round)
	return newRound
end

--Function which changed round status and notify the clients (for UI stuff)
function Round:SetStatus(status : string)
	self.Status = status :: string
	updateUIRemote:FireAllClients(self.Status, self.Timer, self.Winner)
end

--Sets winner and changes the status to "Winner"
function Round:SetWinner()
	self.Winner = self.Players[1]
	self:SetStatus("Winner")
end

--Starts timer for the round
function Round:StartTimer(startTime : number) 
	for newTime = startTime, 0, -1 do
		--Updating timer value and notify clients about new time
		self.Timer = newTime :: number
		updateUIRemote:FireAllClients(self.Status, self.Timer, self.Winner)
		
		--Checks if the timer should be shut down entirly for the round
		if self.ForceEnd then
			self.Timer = 0
			updateUIRemote:FireAllClients(self.Status, self.Timer, self.Winner)
			break
		--Checks if the timer should be shut down only this time
		elseif self.EndTimer == true then
			self.Timer = 0
			self.EndTimer = false
			updateUIRemote:FireAllClients(self.Status, self.Timer, self.Winner)
			break
		end
		task.wait(1)
	end
end

--Stops the current timer
function Round:StopTimer()
	self.EndTimer = true
end

--Starting the round
function Round:Start(players : {Players})
	if self.ForceEnd == true then
		return
	end
	
	self:SetStatus("Round")

	self.Players = {unpack(players)}
	shufflePlayers(self.Players)
end

--Returns the players to spawn
function Round:End()
	returnPlayers2Spawn(self.Players)
end

--Stops the round entirly
function Round:Stop()
	self.ForceEnd = true
end

--Destroying the current round
function Round:Destroy()
	self.Status = nil
	self.Timer = nil
	self.Players = nil
	self.Winner = nil
	self.ForceEnd = nil
	self = nil
end

return Round
