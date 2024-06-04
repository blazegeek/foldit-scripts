scriptName = "Cut & Wiggle 2.0 RC1"
buildNumber = 36

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

-- for puzzles with locked segments, find the non-locked portion and adjust accordingly
function checkLocked()
	print("Checking for locked segments...") -- for testing
	while ((structure.IsLocked(startSegment) == true) and (startSegment <= numSegments)) do
		-- from segment 1, incrememt starting segment until first non-locked segment found
		startSegment = startSegment + 1
	end
	while ((structure.IsLocked(endSegment) == true) and (endSegment >= 1)) do
		-- decrement ending segment until last non-locked segment found
		endSegment = endSegment - 1
	end
	return startSegment, endSegment
end

function checkBands()
	local numBands = band.GetCount()
	if numBands > 0 then
		hasBands = true
		keepBands = true
		for i = 1, numBands do
			if band.IsEnabled(i) then
				bandStates[i] = true
				allBandsDisabled = false
			else
				bandStates[i] = false
				allBandsDisabled = true
			end
		end
	end
end

function performCutWiggle()
	if (useCreditBest == true) then
		creditbest.Restore()
		currentBestScore = checkScore()
	else
		save.Quickload(saveSlot)
		currentBestScore = checkScore()
	end
	startScore = currentBestScore
	currentGain = 0
	totalGain = 0
	print("Start score:", trunc(startScore))
	print("Range:", startSegment .. " - " .. endSegment)
	print("Fragment Length:", fragmentLength)
	print("Low Clash Importance:", lowCI)
	print("Disable Slow Filters:", tostring(disableFilters))
	if (keepCI == true) then
		maxCI = originalCI
		print("Keep Current CI (" .. originalCI .. "):", tostring(keepCI))
	else
		maxCI = 1.0
	end
	if (useCreditBest == true) then
		print("Using Credit Best")
	else
		print("Using QuickSave " .. saveSlot)
	end
	print("")

	failCounter = 0
	runCounter = 0

	while true do
		for j = 0, fragmentLength - 1 do
			runCounter = runCounter + 1
			undo.SetUndo(false)
			if (useCreditBest == true) then
				creditbest.Restore()
			else
				save.Quickload(saveSlot)
			end
			--band.DeleteAll()
			for i = startSegment + j, endSegment, fragmentLength do
				structure.InsertCut(i)
			end
			selection.SelectRange(startSegment, endSegment)
			behavior.SetClashImportance(lowCI)
			structure.WiggleSelected(1)
			behavior.SetClashImportance(maxCI)
			structure.WiggleSelected(10)
			for i = startSegment + j, endSegment, fragmentLength do
				structure.DeleteCut(i)
			end
			undo.SetUndo(true)
			behavior.SetClashImportance(lowCI)
			structure.WiggleSelected(1)
			behavior.SetClashImportance(maxCI)
			structure.WiggleSelected(10)
			currentScore = checkScore()
			--print("Run:", runCounter, trunc(currentScore))
			if (currentScore > currentBestScore) then
				save.Quicksave(saveSlot)
				currentGain = currentScore - currentBestScore
				currentBestScore = currentScore
				totalGain = currentBestScore - startScore
				--print("Gained:", trunc(currentGain), "Total Gain:", trunc(totalGain))
				failCounter = 0
			else
				--print("Run: " .. runCounter, trunc(currentScore))
				currentGain = 0
				failCounter = failCounter + 1
			end
			print("Run:", runCounter, trunc(currentScore), trunc(currentGain), trunc(totalGain), trunc(currentBestScore))
			if (failCounter >= fragmentLength) then
				return
			end
		end
	end
end

function dialogOptions()
	--local dlog = dialog.CreateDialog(scriptName)
	checkLocked()
	checkBands()
	--numSegments = endSegment - startSegment + 1
	local dlog = dialog.CreateDialog(scriptName .. " build " .. buildNumber) -- for testing
	dlog.startSegment = dialog.AddSlider("Min residue:", startSegment, 1, numSegments, 0)
	dlog.endSegment = dialog.AddSlider("Max residue:", endSegment, 1, numSegments, 0)
	dlog.fragmentLength = dialog.AddSlider("Fragment length:", fragmentLength, 1, numSegments - 1, 0 )
	dlog.lowCI = dialog.AddSlider("Low CI:", lowCI, 0, 1.0, 2)
	dlog.wiggleIterations = dialog.AddSlider("Wiggle Iterations:", wiggleIterations, 1, 12, 0)
	--disableFilters = checkSlowFilters()
	dlog.disableFilters = dialog.AddCheckbox("Disable Slow Filters", disableFilters)
	dlog.useCreditBest = dialog.AddCheckbox("Use Credit Best", useCreditBest)
	if (originalCI ~= 1) then
		dlog.keepCI = dialog.AddCheckbox("Use Current CI as Maximum", keepCI)
	end
	if hasBands == true then
		dlog.keepBands = dialog.AddCheckbox("Keep Bands", keepBands)
		dlog.keepBandStates = dialog.AddCheckbox("Keep Band State", keepBandStates)
	end

	dlog.ok = dialog.AddButton("OK", 1)
	dlog.cancel = dialog.AddButton("Cancel", 0)

	if (dialog.Show(dlog) > 0) then
		startSegment = dlog.startSegment.value
		endSegment = dlog.endSegment.value
		fragmentLength = dlog. fragmentLength.value
		lowCI = dlog.lowCI.value
		wiggleIterations = dlog.fragmentLength.value
		disableFilters = dlog.disableFilters.value
		useCreditBest = dlog.useCreditBest.value
		if (originalCI ~= 1) then
			keepCI = dlog.keepCI.value
		end
		if hasBands == true then
			keepBands = dlog.keepBands.value
			keepBandStates = dlog.keepBandStates.value
		end
		return true
	else
		return false
	end
end

function cleanup(errmsg)
	if (errmsg ~= nil) then
		if string.find(errmsg, "Cancelled") then
			--print("")
			print("Cancelled by user")
		else
			print("")
			print("Error:")
			print(errmsg)
		end
	else
		print("")
		print("Done")
	end
	print("")
	print("Cleaning up")
	--reset undo state in case cancelled mid-run
	undo.SetUndo(false)
	undo.SetUndo(true)
	if (disableFilters == true) then
		behavior.SetSlowFiltersDisabled(originalFilterSetting)
	end
	if (keepCI == true) then
		behavior.SetClashImportance(originalCI)
	else
		behavior.SetClashImportance(1.0)
	end
	if (useCreditBest == true) then
		creditbest.Restore()
	else
		save.Quickload(saveSlot)
	end
	selection.DeselectAll()
	--band.EnableAll()
end

function main()
	--print(scriptName)
	--band.DisableAll()
	numSegments = structure.GetCount()
	startSegment = 1
	endSegment = numSegments
	fragmentLength = 5
	lowCI = 0.05
	originalCI = behavior.GetClashImportance()
	maxCI = 1.0
	wiggleIterations = 10
	keepCI = false
	saveSlot = 10
	useCreditBest = false
	hasBands = false
	bandStates = {}
	keepBands = false
	keepBandStates = false
	originalFilterSetting = behavior.GetSlowFiltersDisabled()
	disableFilters = originalFilterSetting
	save.Quicksave(saveSlot)

	if (originalCI ~= 1) then
		keepCI = true
		maxCI = originalCI
	end

	--checkLocked()
	--checkBands()

	if (dialogOptions() == false) then
		print("Cancelled without changes")
		return
	end

	print(scriptName, "build " .. buildNumber) -- for testing
	print("")

	performCutWiggle()
	cleanup()
end

xpcall(main, cleanup)
