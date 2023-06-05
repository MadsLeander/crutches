-- Config --
local disableSprint = true
local disableWeapons = true
local unarmed = `WEAPON_UNARMED`
local crutchModel = `prop_mads_crutch01`
local clipSet = "move_lester_CaneUp"
local pickupAnim = {
	dict = "pickup_object",
	name = "pickup_low"
}

local localization = {
	['ragdoll'] = "You can't use a crutch while you are in ragdoll!",
	['falling'] = "You can't use a crutch while you are falling!",
	['combat'] = "You can't use a crutch while you are in combat!",
	['dead'] = "You can't use a crutch while you are dead!",
	['vehicle'] = "You can't use a crutch while you are in a vehicle!",
	['weapon'] = "You can't use a crutch while having a weapon out!",
	['pickup'] = "Press ~INPUT_PICKUP~ to pick up your crutch!",
	['forced'] = "You need to use the Crutch for a little longer!"
}

-- Variables --
local isUsingCrutch = false
local crutchObject = nil
local walkStyle = nil
local forceEquipped = false
local endForceTime = 0

-- Functions --
local function LoadClipSet(set)
	RequestClipSet(set)
	while not HasClipSetLoaded(set) do
		Wait(10)
	end
end

local function LoadAnimDict(dict)
	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		Wait(10)
	end
end

local function DisplayNotification(msg)
	BeginTextCommandThefeedPost("STRING")
	AddTextComponentSubstringPlayerName(msg)
	EndTextCommandThefeedPostTicker(false, false)
end

local function DisplayHelpText(msg)
	BeginTextCommandDisplayHelp("STRING")
	AddTextComponentSubstringPlayerName(msg)
	EndTextCommandDisplayHelp(0, false, true, 50)
end

local function CreateCrutch()
	if not HasModelLoaded(crutchModel) then
		RequestModel(crutchModel)
		while not HasModelLoaded(crutchModel) do
			Wait(10)
		end
	end
	local playerPed = PlayerPedId()
	local coords = GetEntityCoords(playerPed)
	crutchObject = CreateObject(crutchModel, coords.x, coords.y, coords.z, true, true, false)
	AttachEntityToEntity(crutchObject, playerPed, 70, 1.18, -0.36, -0.20, -20.0, -87.0, -20.0, true, true, false, true, 1, true)
end

local function CanPlayerEquipCrutch()
	local playerPed = PlayerPedId()
	local hasWeapon, _weaponHash = GetCurrentPedWeapon(playerPed, true)

	if hasWeapon then
		return false, localization['weapon']
	elseif IsPedInAnyVehicle(playerPed, false) then
		return false, localization['vehicle']
	elseif IsEntityDead(playerPed) then
		return false, localization['dead']
	elseif IsPedInMeleeCombat(playerPed) then
		return false, localization['combat']
	elseif IsPedFalling(playerPed) then
		return false, localization['falling']
	elseif IsPedRagdoll(playerPed) then
		return false, localization['ragdoll']
	end
	return true
end

local function DeleteCrutchObject()
	if DoesEntityExist(crutchObject) then
		DeleteEntity(crutchObject)
	end
end

local function UnequipCrutch()
	DeleteCrutchObject()
	isUsingCrutch = false

	if disableSprint then
		SetPlayerSprint(PlayerId(), true)
	end

	local playerPed = PlayerPedId()
	if walkStyle then
		LoadClipSet(walkStyle)
		SetPedMovementClipset(playerPed, walkStyle, 1.0)
		RemoveClipSet(walkStyle)
	else
		ResetPedMovementClipset(playerPed, 1.0)
	end
end

local function TraceCrutchObject()
	local traceObject = true
	local playerPed = PlayerPedId()
	local wait = 0

	while traceObject do
		wait = 0
		if DoesEntityExist(crutchObject) then
			playerPed = PlayerPedId()
			if not IsPedFalling(playerPed) and not IsPedRagdoll(playerPed) then
				local dist = #(GetEntityCoords(playerPed)-GetEntityCoords(crutchObject))
				if dist < 2.0 then
					DisplayHelpText(localization['pickup'])
					if IsControlJustReleased(0, 38) then
						LoadAnimDict(pickupAnim.dict)
						TaskPlayAnim(playerPed, pickupAnim.dict, pickupAnim.name, 2.0, 2.0, -1, 0, 0, false, false, false)

						local failCount = 0
						while not IsEntityPlayingAnim(playerPed, pickupAnim.dict, pickupAnim.name, 3) and failCount < 25 do
							failCount = failCount + 1
							Wait(50)
						end
						if failCount >= 25 then
							ClearPedTasks(playerPed)
						else
							Wait(800)
						end

						RemoveAnimDict(pickupAnim.dict)
						DeleteCrutchObject()
						Wait(900)
						CreateCrutch()
						traceObject = false
					end
				elseif dist < 200.0 then
					wait = dist * 10
				else
					traceObject = false
				end
			else
				wait = 250
			end
		else
			traceObject = false
		end
		Wait(wait)
	end
end

local function FrameThread()
	CreateThread(function()
		while isUsingCrutch do
			SetPedCanPlayAmbientAnims(PlayerPedId(), false)
			Wait(0)
		end
	end)
end

local function MainThread()
	CreateThread(function()
		local playerPed = nil
		local fallCount = 0

		while true do
			Wait(250)
			if not isUsingCrutch then
				break
			end

			playerPed = PlayerPedId()
			local isCrutchHidden = false
			local hasWeapon, _weaponHash = GetCurrentPedWeapon(playerPed, true)

			if hasWeapon then
				if disableWeapons then
					SetCurrentPedWeapon(playerPed, unarmed, true)
				elseif not isCrutchHidden then
					isCrutchHidden = true
					DeleteCrutchObject()
				end
			elseif IsPedInAnyVehicle(playerPed, true) then
				if not isCrutchHidden then
					isCrutchHidden = true
					DeleteCrutchObject()
				end
			elseif not DoesEntityExist(crutchObject) then
				Wait(750)
				CreateCrutch()
				isCrutchHidden = false
			elseif not IsEntityAttachedToEntity(crutchObject, playerPed) then
				TraceCrutchObject()
			elseif IsPedRagdoll(playerPed) or IsEntityDead(playerPed) then
				DetachEntity(crutchObject, true, true)
			elseif IsPedInMeleeCombat(playerPed) then
				Wait(500)
				DetachEntity(crutchObject, true, true)
			elseif IsPedFalling(playerPed) then
				fallCount = fallCount + 1
				if fallCount > 3 then
					DetachEntity(crutchObject, true, true)
					fallCount = 0
				end
			elseif fallCount > 0 then
				fallCount = fallCount - 1
			end
		end
	end)
end

local function EquipCrutch()
	local playerPed = PlayerPedId()
	local canEquip, msg = CanPlayerEquipCrutch()
	if not canEquip then
		DisplayNotification(msg)
		return
	end

	LoadClipSet(clipSet)
	SetPedMovementClipset(playerPed, clipSet, 1.0)
	RemoveClipSet(clipSet)

	CreateCrutch()
	isUsingCrutch = true

	if disableSprint then
		SetPlayerSprint(PlayerId(), false)
	end

	FrameThread()
	MainThread()
end

local function ToggleCrutch()
	if isUsingCrutch then
		if forceEquipped then
			DisplayNotification(localization['forced'])
			return
		end
		UnequipCrutch()
	else
		EquipCrutch()
	end
end

local function StartForcedTimer(time)
	CreateThread(function()
		endForceTime = GetGameTimer() + time * 1000

		while true do
			Wait(1000)
			if endForceTime < GetGameTimer() then
				break
			end
		end

		forceEquipped = false
	end)
end

-- Exports --
exports('SetWalkStyle', function(walk)
	walkStyle = walk
end)

-- Commands --
RegisterCommand("crutch", function(source, args, rawCommand)
	ToggleCrutch()
end, false)

-- Events --
-- Trigger this event on the client that should be forced to use a crutch (time is in seconds)
AddEventHandler('crutches:forceEquip', function(state, time)
	forceEquipped = state
	if forceEquipped then
		if not isUsingCrutch then
			EquipCrutch()
		end
		StartForcedTimer(time)
	end
end)

local currentResource = GetCurrentResourceName()
AddEventHandler('onResourceStop', function(resource)
    if resource ~= currentResource then
        return
    end

    if isUsingCrutch then
		UnequipCrutch()
	end
end)
