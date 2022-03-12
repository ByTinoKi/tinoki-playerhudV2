local invehicle = false
local HudStage = 1

local lastValues = {}
local currentValues = {
	["health"] = 100,
	["armor"] = 100,
	["hunger"] = 100,
	["thirst"] = 100,
}

currentValues["hunger"] = 100
currentValues["thirst"] = 100

hunger = "Full"
thirst = "Sustained"


Citizen.CreateThread(function()
    while true do
        
        TriggerEvent('esx_status:getStatus', 'hunger', function(hunger)
            TriggerEvent('esx_status:getStatus', 'thirst', function(thirst)

                local myhunger = hunger.getPercent()
                local mythirst = thirst.getPercent()

                SendNUIMessage({
                    action = "updateStatusHud",
					varSetHunger = myhunger,
					varSetThirst = mythirst,
                })
            end)
        end)
        Citizen.Wait(5000)
    end
end)

local stresslevel = 0


currentValues["hunger"] = 0

currentValues["thirst"] = 0

Citizen.CreateThread(function()
	
	while true do
		Citizen.Wait(5000)
		
		TriggerEvent('esx_status:getStatus', 'hunger', function(status)
			currentValues["hunger"]  = status.val/1000000*100
		end)
		TriggerEvent('esx_status:getStatus', 'thirst', function(status)
			currentValues["thirst"] = status.val/1000000*100
		end)
	end
end)



currentValues["oxy"] = 25.0





Citizen.CreateThread(function()

	while true do
		Wait(1)
		if currentValues["oxy"] > 0 and IsPedSwimmingUnderWater(PlayerPedId()) then
			SetPedDiesInWater(PlayerPedId(), false)
			if currentValues["oxy"] > 25.0 then
				currentValues["oxy"] = currentValues["oxy"] - 0.003125
			else
				currentValues["oxy"] = currentValues["oxy"] - 1
			end
		else
			if IsPedSwimmingUnderWater(PlayerPedId()) then
				currentValues["oxy"] = currentValues["oxy"] - 0.01
				SetPedDiesInWater(PlayerPedId(), true)
			end
		end

		if not IsPedSwimmingUnderWater( PlayerPedId() ) and currentValues["oxy"] < 25.0 then
			if GetGameTimer() - lastDamageTrigger > 3000 then
				currentValues["oxy"] = currentValues["oxy"] + 1
				if currentValues["oxy"] > 25.0 then
					currentValues["oxy"] = 25.0
				end
			else
				if currentValues["oxy"] <= 0 then
					
					if exports["isPed"]:isPed("dead") then
						lastDamageTrigger = -7000
						currentValues["oxy"] = 25.0
					else
						SetEntityHealth(PlayerPedId(), GetEntityHealth(PlayerPedId()) - 20)
					end
				end
			end
		end

		if currentValues["oxy"] > 25.0 and not oxyOn then
			oxyOn = true
			attachProp("p_s_scuba_tank_s", 24818, -0.25, -0.25, 0.0, 180.0, 90.0, 0.0)
			attachProp2("p_s_scuba_mask_s", 12844, 0.0, 0.0, 0.0, 180.0, 90.0, 0.0)
		elseif oxyOn and currentValues["oxy"] <= 25.0 then
			oxyOn = false
			removeAttachedProp()
			removeAttachedProp2()
		end
		if not oxyOn then
			Wait(1000)
		end
	end
end)

-- this should just use nui instead of drawrect - it literally ass fucks usage.
Citizen.CreateThread(function()
	local minimap = RequestScaleformMovie("minimap")
    SetRadarBigmapEnabled(true, false)
    Wait(0)
	SetRadarBigmapEnabled(false, true)
	
	local counter = 0
	local get_ped = PlayerPedId() -- current ped
	currentValues["health"] = (GetEntityHealth(get_ped) - 100)
	currentValues["voice"] = 0
	currentValues["armor"] = GetPedArmour(get_ped)
	currentValues["parachute"] = HasPedGotWeapon(get_ped, `gadget_parachute`, false)
	if currentValues["oxy"] <= 0 then currentValues["oxy"] = 0 end
	while true do

		if sleeping then
			if IsControlJustReleased(0,38) then
				sleeping = false
				DetachEntity(PlayerPedId(), 1, true)
			end
		end

		Citizen.Wait(1)
		
		if GetEntityMaxHealth(GetPlayerPed(-1)) ~= 200 then
			SetEntityMaxHealth(GetPlayerPed(-1), 200)
			SetEntityHealth(GetPlayerPed(-1), 200)
		end

		if counter == 0 then
			
			 -- current ped
			get_ped = PlayerPedId()
			SetPedSuffersCriticalHits(get_ped,false)
			currentValues["health"] = GetEntityHealth(get_ped) - 100
			currentValues["armor"] = GetPedArmour(get_ped)
			currentValues["parachute"] = HasPedGotWeapon(get_ped, `gadget_parachute`, false)

			if stresslevel > 100 then stresslevel = 100 end


			if currentValues["hunger"] < 0 then
				currentValues["hunger"] = 0
			end
			if currentValues["thirst"] < 0 then
				currentValues["thirst"] = 0
			end

			if currentValues["hunger"] > 100 then currentValues["hunger"] = 100 end

			if currentValues["health"] < 1 then currentValues["health"] = 100 end
			if currentValues["thirst"] > 100 then currentValues["thirst"] = 100 end
			if currentValues["oxy"] <= 0 then currentValues["oxy"] = 0 end
			local valueChanged = false

			for k,v in pairs(currentValues) do
				if lastValues[k] == nil or lastValues[k] ~= v then
					valueChanged = true
					lastValues[k] = v
				end
			end

			if valueChanged then
				SendNUIMessage({
					type = "updateStatusHud",
					hasParachute = currentValues["parachute"],
					varSetHealth = currentValues["health"],
					varSetArmor = currentValues["armor"],
					varSetHunger = currentValues["hunger"],
					varSetThirst = currentValues["thirst"],
					varSetOxy = currentValues["oxy"],
					varSetStress = stresslevel,

				})
			end

			counter = 25

		end

		counter = counter - 1

        if get_ped_veh ~= 0 then
            local model = GetEntityModel(get_ped_veh)
            local roll = GetEntityRoll(get_ped_veh)
  
            if not IsThisModelABoat(model) and not IsThisModelAHeli(model) and not IsThisModelAPlane(model) and IsEntityInAir(get_ped_veh) or (roll < -50 or roll > 50) then
                DisableControlAction(0, 59) -- leaning left/right
                DisableControlAction(0, 60) -- leaning up/down
            end

            if GetPedInVehicleSeat(GetVehiclePedIsIn(get_ped, false), 0) == get_ped then
				if GetIsTaskActive(get_ped, 165) then
					SetPedIntoVehicle(get_ped, GetVehiclePedIsIn(get_ped, false), 0)
				end
			end

			DisplayRadar(1)
        	SetRadarZoom(1000)
        else
        	DisplayRadar(0)
        end

		BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
        ScaleformMovieMethodAddParamInt(3)
        EndScaleformMovieMethod()
	end
end)

local HUD_ELEMENTS = {
    HUD = { id = 0, hidden = false },
    HUD_WANTED_STARS = { id = 1, hidden = true },
    HUD_WEAPON_ICON = { id = 2, hidden = true },
    HUD_CASH = { id = 3, hidden = true },
    HUD_MP_CASH = { id = 4, hidden = true },
    HUD_MP_MESSAGE = { id = 5, hidden = true },
    HUD_VEHICLE_NAME = { id = 6, hidden = true },
    HUD_AREA_NAME = { id = 7, hidden = true },
    HUD_VEHICLE_CLASS = { id = 8, hidden = true },
    HUD_STREET_NAME = { id = 9, hidden = true },
    HUD_HELP_TEXT = { id = 10, hidden = false },
    HUD_FLOATING_HELP_TEXT_1 = { id = 11, hidden = false },
    HUD_FLOATING_HELP_TEXT_2 = { id = 12, hidden = false },
    HUD_CASH_CHANGE = { id = 13, hidden = true },
    HUD_SAVING_GAME = { id = 17, hidden = false },
    HUD_GAME_STREAM = { id = 18, hidden = false },
    HUD_WEAPON_WHEEL = { id = 19, hidden = false },
    HUD_WEAPON_WHEEL_STATS = { id = 20, hidden = true },
    MAX_HUD_COMPONENTS = { id = 21, hidden = false },
    MAX_HUD_WEAPONS = { id = 22, hidden = false },
    MAX_SCRIPTED_HUD_COMPONENTS = { id = 141, hidden = false }
}

-- Main thread
Citizen.CreateThread(function()
    -- Loop forever and update HUD every frame
    while true do
        Citizen.Wait(0)

        -- If enabled only show radar when in a vehicle (use a zoomed out view)
        if HUD_HIDE_RADAR_ON_FOOT then
            local player = GetPlayerPed(-1)
            DisplayRadar(IsPedInAnyVehicle(player, false))
            SetRadarZoomLevelThisFrame(100.0)
        end

        -- Hide other HUD components
        for key, val in pairs(HUD_ELEMENTS) do
            if val.hidden then
                HideHudComponentThisFrame(val.id)
            else
                ShowHudComponentThisFrame(val.id)
            end
        end
    end
end)

