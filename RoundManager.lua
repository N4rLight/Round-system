--Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--Settings
local MIN_PLAYERS = 2
local INTERMISSION_TIME = 5
local ROUND_TIME = 5

--Tables
local loadedPlayers = {} :: {Players}
local playersEvent = {} 

--Remote
local remoteFunction = {
	["GetRoundInfo"] = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Functions"):WaitForChild("GetRoundInfo")
}

--Current round
local activeRound

--The round object module
local roundObjectModule : ModuleScript

--Checks if there is enough players for the round and if not then stops it
local function checkPlayers()
	if #loadedPlayers < MIN_PLAYERS then
		activeRound:Stop()
	end
	
	if activeRound.Status == "Round" then
		for i, player : Player in pairs(activeRound.Players) do
			if player.Character and player.Character.Humanoid and player.Character.Humanoid.Health == 0 then
				table.remove(activeRound.Players, i)
			end
		end

		if #activeRound.Players < MIN_PLAYERS then
			activeRound:Stop()
		end
	end
end

--Functions which detects when player die
local function playerDieEvent(player : Player)
	--Humanoid
	local humanoid = player.Character.Humanoid :: Humanoid
	
	--Main function
	local function humanoidDieFunc()
		--[[If humanoid died during the round then it removes it from current players
			and check if it should stop the round]]
		if activeRound.Status == "Round" then
			table.remove(activeRound.Players, table.find(activeRound.Players, player))
			
			--If there is only one person left in the round then sets the winner
			if #activeRound.Players == 1 then
				activeRound:StopTimer()
				activeRound:SetWinner()
			--Stoping the round because no one won
			elseif #activeRound.Players <= 0 and activeRound.Status ~= "Winner" then
				activeRound:Stop()
			end
		end
		
		--Uplying the die function to the new humanoid and saving the function
		local newChar = player.CharacterAdded:Wait()
		local humanoid = newChar:WaitForChild("Humanoid") :: Humanoid
		
		local event = humanoid.Died:Once(humanoidDieFunc)
		
		playersEvent[player] = event
	end
	
	--Connecting the function to the humanoid
	local event = humanoid.Died:Once(humanoidDieFunc)
	
	--Saving the event to disconnect it when the player leaves
	playersEvent[player] = event
end

--Function which adding loaded players to the players which may play and removes players who left
local function loadingPlayers()
	Players.PlayerAdded:Connect(function(player : Player)
		--Waits for the character if it's still not created
		if not player.Character then
			player.CharacterAdded:Wait()
		end
		
		--Adding to the loaded players
		table.insert(loadedPlayers, player)
		
		--Connecting the die function
		playerDieEvent(player)
	end)
	
	Players.PlayerRemoving:Connect(function(player : Player)
		--Searching player in the loaded players table
		local pos = table.find(loadedPlayers, player)
		if pos then
			--Removes the player
			table.remove(loadedPlayers, pos)
			
			--Checks for the round
			if #loadedPlayers < MIN_PLAYERS then
				activeRound:Stop()
			end
			
			--Disconnects the die function from the player
			if playersEvent[player] then
				playersEvent[player]:Disconnect()
				playersEvent[player] = nil
			end
		end
	end)
end

--Main functions which handles the round
local function start()
	--Connecting the loadPlayers function
	loadingPlayers()
	
	--Starting the round loop
	while task.wait() do
		--Creating the round object
		activeRound= roundObjectModule.new("Waiting for players", INTERMISSION_TIME)
		--Checks if there is enough players to start
		if #loadedPlayers >= MIN_PLAYERS then
			--Setting the round status to "Intermission"
			activeRound:SetStatus("Intermission")
			
			--Starts the intermission timer
			activeRound:StartTimer(INTERMISSION_TIME)
			
			--Double check if there still enough players to start
			checkPlayers()
			
			activeRound:Start(loadedPlayers)
			
			--Double check if there still enough players to continue
			checkPlayers()
			
			--Starting the round timer
			activeRound:StartTimer(ROUND_TIME)
			
			--[[Checks if there still more than 1 player or non when the timer stops
				and if so then sets round status to tie]]
			if #activeRound.Players ~= 1 then
				activeRound:SetStatus("Tie")
			end
			
			--Starts the last timer to show the winner/tie
			activeRound:StartTimer(3)
			
			--Teleports the players back
			activeRound:End()
			
			--Destroys the current round
			activeRound:Destroy()
		else
			--Waiting untill there is enough players to start
			repeat
				task.wait()
			until #loadedPlayers >= MIN_PLAYERS
		end
	end
end

local module = {}

--Module Initializing
function module:Init()
	--Checks if it's the server
	if RunService:IsClient() then return end
	
	--Requiring the round object module
	roundObjectModule = require(game.ServerScriptService:WaitForChild("Objects"):WaitForChild("RoundObject"))
	
	--Connects remote function
	remoteFunction["GetRoundInfo"].OnServerInvoke = function()
		return activeRound.Status, activeRound.Timer, activeRound.Winner
	end
	
	--Starts the main function
	start()
end

return module
