scriptName = "RedFuze 2020 v1.0"
buildNumber = 14
function trunc(x)
	return math.floor(x * 1000) / 1000
end

function checkScore()
	local score
	if (disableFilters == true) then
		behavior.SetFiltersDisabled(false)
		score = current.GetEnergyScore()
		behavior.SetFiltersDisabled(true)
	else
		score = current.GetEnergyScore()
	end
	return score
end

function checkSlowFilters()
	local scoreWithFilters
	local scoreWithoutFilters
	if (originalFilterSetting == false) then
		scoreWithoutFilters = current.GetEnergyScore()
		behavior.SetSlowFiltersDisabled(true)
		scoreWithFilters = current.GetEnergyScore()
	else
		scoreWithFilters = current.GetEnergyScore()
		behavior.SetSlowFiltersDisabled(false)
		scoreWithoutFilters = current.GetEnergyScore()
	end
	behavior.SetSlowFiltersDisabled(originalFilterSetting)
	if (math.abs(scoreWithoutFilters - scoreWithFilters) > 0.001) then
		return true
	else
		return false
	end
end

function calcGain()
	currentScore = checkScore()
	currentGain = currentScore - bestScore
	if currentGain > 0 then
		save.Quicksave(saveSlot)
		bestScore = currentScore
		totalGain = totalGain + currentGain
	end
	return currentScore, bestScore, currentGain, totalGain
end

function checkBands()
	bandStates = {}
	local numBands = band.GetCount()
	if numBands > 0 then
		hasBands = true
		keepBands = true
		--for i = 1, numBands do
			--if band.IsEnabled(i) then
				--bandStates[i] = true
				--allBandsDisabled = false
			--else
				--bandStates[i] = false
				--allBandsDisabled = true
			--end
		--end
	else
		hasBands = false
		keepBands = false
	end
end

function dialogOptions()
	optionsPopup = dialog.CreateDialog(scriptName .. "build" .. buildNumber)
	optionsPopup.shakeIterations = dialog.AddSlider("Shake Iterations: ", shakeIterations, 0, 99, 0)
	optionsPopup.wiggleIterations = dialog.AddSlider("Wiggle Iterations: ", wiggleIterations, 1, 99, 0)
	optionsPopup.useCreditBest = dialog.AddCheckbox("Use Credit Best", useCreditBest)
	if hasBands == true then
		optionsPopup.keepBands = dialog.AddCheckbox("Keep Bands", false)
	end
	optionsPopup.ok = dialog.AddButton("OK", 1)
	optionsPopup.cancel = dialog.AddButton("Cancel", 0)

	dialogOptionsButton = dialog.Show(optionsPopup)
	if dialogOptionsButton > 0 then
		shakeIterations = optionsPopup.shakeIterations.value
		wiggleIterations = optionsPopup.wiggleIterations.value
		useCreditBest = optionsPopup.useCreditBest.value
		if hasBands == true then
			keepBands = optionsPopup.keepBands.value
		end
	end
	return dialogOptionsButton
end

function runCycle(currentRun)
	if useCreditBest == true then
		creditbest.Restore()
	else
		save.Quickload(saveSlot)
	end
	if keepBands == false then
		band.DeleteAll()
	--else
		--band.DisableAll()
	end
	calcGain()
	print("Cycle " .. currentRun .. "/8")
	if shakeIterations ~= 0 then
		print("Begin Shake:", trunc(currentScore), trunc(currentGain), trunc(totalGain))
	end
	if currentRun == 1 then
		behavior.SetClashImportance(0.03)
	elseif currentRun == 2 then
		behavior.SetClashImportance(0.05)
	elseif currentRun == 3 then
		behavior.SetClashImportance(0.07)
	elseif currentRun == 4 then
		behavior.SetClashImportance(0.10)
	elseif currentRun == 5 then
		behavior.SetClashImportance(0.13)
	elseif currentRun == 6 then
		behavior.SetClashImportance(0.30)
	elseif currentRun == 7 then
		behavior.SetClashImportance(0.50)
	else
		behavior.SetClashImportance(0.70)
	end
	if shakeIterations ~= 0 then
			structure.ShakeSidechainsAll(shakeIterations)
	end
	calcGain()
	print("Begin Wiggle:", trunc(currentScore), trunc(currentGain), trunc(totalGain))
	structure.WiggleAll(3)
	behavior.SetClashImportance(1.00)
	structure.WiggleAll(wiggleIterations)
	calcGain()
	print("Cycle " .. currentRun .. " Score: ", trunc(currentScore), trunc(currentGain), trunc(totalGain))
	print("")
end

function cleanup(errorMessage)
	if (errorMessage ~= nil) then
		if string.find(errorMessage, "Cancelled") then
			print("Cancelled by user")
		else
			print("")
			print("Error:")
			print(errorMessage)
		end
	end
	print("")
	print("Cleaning up")
	if (useCreditBest == true) then
		creditbest.Restore()
	else
		save.Quickload(saveSlot)
	end
		print("Done")
		calcGain()
	print("Final Score:", trunc(currentScore), trunc(totalGain))
	behavior.SetClashImportance(1.0)
	selection.DeselectAll()
	--band.EnableAll()
end

function main()
	saveSlot = 11
	useCreditBest = false
	save.Quicksave(saveSlot)
	startScore = current.GetEnergyScore()
	currentScore = startScore
	bestScore = startScore
	totalGain = 0
	currentCycle = 1
	shakeIterations = 4
	wiggleIterations = 12

	print(scriptName .. " build " .. buildNumber) -- for testing
	print("Initial Score: " .. trunc(startScore))
	print("")

	checkBands()
	--dialogOptions()

	dialogOptionsCode = dialogOptions()
	if (dialogOptionsCode == 0) then
		print("Cancelled without changes")
		return
	end

	repeat
		runCycle(currentCycle)
		currentCycle =  currentCycle + 1
	until currentCycle > 8
	calcGain()
	cleanup()
end

xpcall(main, cleanup)
