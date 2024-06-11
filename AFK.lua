scriptName = "AFK 3.5"
scriptVersion = 3.5
buildNumber = 2

BestSlot = 98
JumpSlot = 10
JumpCredit = 50

arraySelected = {}
arrayFrozen = {}
maxCycles = 1000
minGain = 0
doRisky = false
doShake = false
hasMutable = false
doMutate = false
skipCIMaximization = true
isSketchbook = false

numSegments = structure.GetCount()

function cleanup(errorMessage)
	behavior.SetClashImportance(originalCI)
	recentbest.Restore()
	selection.DeselectAll()
end


function detectFilters()
	local puzzleDescription = puzzle.GetDescription()
	local puzzleTitle = puzzle.GetName()
	if #puzzleDescription > 0 and (puzzleDescription:find("Sketchbook") or puzzleDescription:find("Sketchbook")) then
		isSketchbook = true
	end
	if #puzzleTitle > 0 and puzzleTitle:find("Sketchbook") then
		isSketchbook = true
	end
	--[[
	if #puzzleDescription > 0 and (puzzleDescription:find("filter") or puzzleDescription:find("filters") or puzzleDescription:find("contact") or puzzleDescription:find("Contacts")) then
		--probableFilter = true -- NOT USED ANYWHERE ELSE IN THIS SCRIPT
		--filterManage = true -- NOT USED ANYWHERE ELSE IN THIS SCRIPT
		--genericFilter = false -- NOT USED ANYWHERE ELSE IN THIS SCRIPT
	end
	]]--
	if #puzzleDescription > 0 and (puzzleDescription:find("design") or puzzleDescription:find("designs")) then
		hasMutable = true
		--idealCheck = true -- NOT USED ANYWHERE ELSE IN THIS SCRIPT (EXCEPT BELOW)
	end
	--[[
	if #puzzleDescription > 0 and (puzzleDescription:find("De-novo") or puzzleDescription:find("de-novo") or puzzleDescription:find("freestyle")
		or puzzleDescription:find("prediction") or puzzleDescription:find("predictions")) then
		idealCheck = true -- NOT USED ANYWHERE ELSE IN THIS SCRIPT (EXCEPT ABOVE)
	end
	]]--
	--[[
	if #puzzleTitle > 0 then
		if (puzzleTitle:find("Sym") or puzzleTitle:find("Symmetry") or puzzleTitle:find("Symmetric") or puzzleTitle:find("Dimer") or puzzleTitle:find("Trimer") or puzzleTitle:find("Tetramer") or puzzleTitle:find("Pentamer")) then
			probableSymmetry = true -- NOT USED ANYWHERE ELSE IN THIS SCRIPT (EXCEPT BELOW)
			if puzzleTitle:find("Dimer") and not puzzleTitle:find("Dimer of Dimers") then
				sym = 2
			elseif puzzleTitle:find("Trimer") or puzzleTitle:find("Tetramer") then
				sym = 3
			elseif puzzleTitle:find("Dimer of Dimers") or puzzleTitle:find("Tetramer") then
				sym = 4
			elseif puzzleTitle:find("Pentamer") then
				sym = 5
			else
				sym = 6
			end
		end
	end
	]]--
	--[[
	if #puzzleDescription > 0 and (puzzleDescription:find("Sym") or puzzleDescription:find("Symmetry") or puzzleDescription:find("Symmetric") or puzzleDescription:find("sym") or puzzleDescription:find("symmetry") or puzzleDescription:find("symmetric")) then
		probableSymmetry = true
		if (puzzleDescription:find("Dimer") or puzzleDescription:find("dimer")) and not (puzzleDescription:find("Dimer of Dimers") or puzzleDescription:find("dimer of dimers")) then
			sym = 2
		elseif puzzleDescription:find("Trimer") or puzzleDescription:find("trimer") then
			sym = 3
		elseif (puzzleDescription:find("Dimer of Dimers") or puzzleDescription:find("Tetramer")) and not (puzzleDescription:find("dimer of dimers") or puzzleDescription:find("tetramer"))then
			sym = 4
		elseif puzzleDescription:find("Pentamer") or puzzleDescription:find("pentamer") then
			sym = 5
		end
	end
	]]--
	--[[
	if probableSymmetry then
		print("Symmetric")
		if sym == 2 then
			print("Dimer")
		elseif sym == 3 then
			print("Trimer")
		elseif sym == 4 then
			print("Tetramer")
		elseif sym == 5 then
			print("Pentamer")
		elseif sym > 5 then
			print("Terrible polymer")
		end
	else
		print("Monomer")
	end
	]]--
	--[[
	if #puzzleTitle > 0 and puzzleTitle:find("Sepsis") then
		isSepsis = true -- NOT USED ANYWHERE ELSE IN THIS SCRIPT
		print("Sepsis")
	end
	if #puzzleTitle > 0 and puzzleTitle:find("Electron Density") then
		isDensity = true -- NOT USED ANYWHERE ELSE IN THIS SCRIPT
		print("Electron density")
	end
	if #puzzleTitle > 0 and puzzleTitle:find("Centroid") then
		isCentroid = true -- NOT USED ANYWHERE ELSE IN THIS SCRIPT
		print("Centroid")
	end
	if #puzzleTitle>0 and puzzleTitle:find("Hotspot") then
		isHotspot = true -- NOT USED ANYWHERE ELSE IN THIS SCRIPT
		print("Hotspot")
	end
	]]--
	return
end

detectFilters()

--[[
if creditbest.GetScore() > current.GetScore() then
	print("???????????")
	print("WARNING not starting from creditbest score")
	print("Risky endless on your own risk !")
	print("???????????")
end
]]--

function dialogStrategic()
	local currentDialog = dialog.CreateDialog("BounceWiggleStrategy")
	currentDialog.sketchbooklabel = dialog.AddLabel("Sketchbook automatic")
	currentDialog.labelBlank = dialog.AddLabel("")
	currentDialog.TwoMoves = dialog.AddButton("2 moves", 1)
	currentDialog.TenMoves = dialog.AddButton("7 moves", 2)
	currentDialog.Custom = dialog.AddButton("Custom", 3)
	currentDialog.buttonCancel = dialog.AddButton("Cancel", 0)
	local choice = dialog.Show(currentDialog)
	return choice
end

function dialogBounceWiggle()
	for n = 1, numSegments() do
		if structure.IsMutable(n) then
			hasMutable = true
		end
		if selection.IsSelected(n) then
			arraySelected[n] = true
		else
			arraySelected[n] = false
		end
		if freeze.IsFrozen(n) then
			arrayFrozen[n] = true
		else
			arrayFrozen[n] = false
		end
	end

	local currentDialog = dialog.CreateDialog("BounceWiggle")
	currentDialog.labelIterations = dialog.AddLabel("Failed Iterations before ending")
	currentDialog.maxCycles = dialog.AddSlider("Failure Iterations", maxCycles, 0, 1000, 0)
	currentDialog.labelBlank = dialog.AddLabel("")
	currentDialog.labelDiscard = dialog.AddLabel("(Sketchbook) Discard gains less than")
	currentDialog.minGain = dialog.AddSlider("Discard <", minGain, 0, 500, 2)
	currentDialog.doRisky = dialog.AddCheckbox("Risky endless using CreditBest", doRisky)
	currentDialog.labelBlank2 = dialog.AddLabel("")
	currentDialog.skipCIMaximization = dialog.AddCheckbox("Skip CI=1 Maximization", skipCIMaximization)
	currentDialog.buttonNoShake = dialog.AddButton("No Shake", 1)
	currentDialog.buttonShake = dialog.AddButton("Shake", 2)
	if (hasMutable) then
		currentDialog.buttonMutate = dialog.AddButton("Mutate", 3)
	end
	currentDialog.buttonCancel = dialog.AddButton("Cancel", 0)

	local choice = dialog.Show(currentDialog)

	maxCycles = currentDialog.maxCycles.value
	minGain = currentDialog.minGain.value
	doRisky = currentDialog.doRisky.value
	skipCIMaximization = currentDialog.skipCIMaximization.value
	if maxCycles < 1 then
		maxCycles = -1 -- WHY?????
	end
	cyclesReset = maxCycles -- init if further rounds needed

	if choice > 2 then
		print("AFK3(BounceWiggleMutate) started. " .. maxCycles .. " failed Iterations before ending")
		doMutate = true
	elseif choice > 1 then
		print("AFK3(BounceWiggleShake) started. " .. maxCycles .. " failed Iterations before ending")
		doShake = true
	elseif choice > 0 then
		print("AFK3(BounceWiggleNoShake) started. " .. maxCycles .. " failed Iterations before ending")
	else
		print("Dialog cancelled")
	end

	return choice
end

function initBounceWiggle()
	local choice = 3 -- default to normal dialog
	if isSketchbook == true then -- sketchbook dialog choices 1 or 2
		choice = dialogStrategic()
	end
	if choice < 1 then
		return
	elseif choice < 2 then -- 2 moves
		doShake = false
		doMutate = false
		maxCycles = 1000
		minGain = 500
		doRisky = false
	elseif choice < 3 then -- 7 moves
		doShake = true
		if hasMutable then
			doMutate = true
		end
		maxCycles = 100
		minGain = 500
		doRisky = true
	elseif choice < 4 then -- custom (normal dialog)
		choice = dialogBounceWiggle() -- normal dialog
		if choice < 1 then
			return
		end
	end

	cyclesReset = maxCycles -- init if further rounds needed
	local currentScore = startScore
	local tempScore = currentScore
	local tempScore2 = tempScore
	save.Quicksave(BestSlot)
	recentbest.Save()
	behavior.SetClashImportance(1)
	local init = true

	if skipCIMaximization == false then
		print("Maximizing Wiggle Score at Clashing Impotance = 1. Please wait.")
		while current.GetEnergyScore() > currentScore or init == true do
			init = false
			currentScore = current.GetEnergyScore()
			tempScore = currentScore
			tempScore2 = tempScore
			selection.SelectAll()
			structure.WiggleAll(25)
			recentbest.Restore()
			tempScore = current.GetEnergyScore()
			if tempScore > (tempScore2 + minGain) then
				save.Quicksave(BestSlot)
				tempScore2 = tempScore
			else
				save.Quickload(BestSlot)
				tempScore = current.GetEnergyScore()
			end
			structure.LocalWiggleAll(25)
			recentbest.Restore()
			tempScore = current.GetEnergyScore()
			if tempScore > (tempScore2 + minGain) then
				save.Quicksave(BestSlot)
				tempScore2 = tempScore
			else
				save.Quickload(BestSlot)
				tempScore = current.GetEnergyScore()
			end
			structure.WiggleSelected(25)
			recentbest.Restore()
			tempScore = current.GetEnergyScore()
			if tempScore > (tempScore2 + minGain) then
				save.Quicksave(BestSlot)
				tempScore2 = tempScore
			else
				save.Quickload(BestSlot)
				tempScore = current.GetEnergyScore()
			end
			structure.LocalWiggleSelected(25)
			recentbest.Restore()
			tempScore = current.GetEnergyScore()
			if tempScore > (tempScore2 + minGain) then
				save.Quicksave(BestSlot)
				tempScore2 = tempScore
			else
				save.Quickload(BestSlot)
				tempScore = current.GetEnergyScore()
			end
		end
		currentScore = current.GetEnergyScore()
	end

	if currentScore > startScore then
		print("Script started: + " .. (currentScore - startScore) .. " -- " .. currentScore)
	else
		print("Script started: " .. currentScore)
	end

	init = true

	while init == true or maxCycles > 0 or maxCycles < 0 do
		init = false
		currentScore = current.GetEnergyScore()
		runBounceWiggle()
		if current.GetEnergyScore() > (currentScore + minGain) then
			print(maxCycles .. ": + " .. (current.GetEnergyScore() - currentScore) .. " -- " .. current.GetEnergyScore())
			JumpSlot = JumpSlot + 1
			if JumpSlot > 50 then
				JumpSlot = 10
			end
			save.Quicksave(JumpSlot)
			if maxCycles > 0 then
				maxCycles = maxCycles + 1
			end
		else
			print(maxCycles .. ": No gain -- " .. current.GetEnergyScore())
			--if maxCycles == 25 or maxCycles == 50 or maxCycles == 100 or maxCycles == 200 or maxCycles == 400 then
				--print(maxCycles .. " -- (Credit Best Score: " .. creditbest.GetScore() .. ")")
			--end
		end

		if maxCycles > 0 then
			maxCycles = maxCycles - 1
		end

		if doRisky and maxCycles == 1 then
			maxCycles = cyclesReset
			print("Starting over with Credit Best score: " .. creditbest.GetScore())
			creditbest.Restore()
			JumpCredit = JumpCredit + 1
			if JumpCredit > 90 then
				JumpCredit = 51
			end
			save.Quicksave(JumpCredit)
		end
	end

	init = true

	currentScore = current.GetEnergyScore()

	if skipCIMaximization == false then
		print("Maximizing Wiggle Score at Clashing Impotance = 1. Please wait.")
		while current.GetEnergyScore() > currentScore or init == true do
			init = false
			currentScore = current.GetEnergyScore()
			tempScore = currentScore
			tempScore2 = tempScore
			selection.SelectAll()
			structure.WiggleAll(25)
			recentbest.Restore()
			tempScore = current.GetEnergyScore()
			if tempScore > (tempScore2 + minGain) then
				save.Quicksave(BestSlot)
				tempScore2 = tempScore
			else
				save.Quickload(BestSlot)
				tempScore = current.GetEnergyScore()
			end
			structure.LocalWiggleAll(25)
			recentbest.Restore()
			tempScore = current.GetEnergyScore()
			if tempScore > (tempScore2 + minGain) then
				save.Quicksave(BestSlot)
				tempScore2 = tempScore
			else
				save.Quickload(BestSlot)
				tempScore = current.GetEnergyScore()
			end
			structure.WiggleSelected(25)
			recentbest.Restore()
			tempScore = current.GetEnergyScore()
			if tempScore > (tempScore2 + minGain) then
				save.Quicksave(BestSlot)
				tempScore2 = tempScore
			else
				save.Quickload(BestSlot)
				tempScore = current.GetEnergyScore()
			end
			structure.LocalWiggleSelected(25)
			recentbest.Restore()
			tempScore = current.GetEnergyScore()
			if tempScore > (tempScore2 + minGain) then
				save.Quicksave(BestSlot)
				tempScore2 = tempScore
			else
				save.Quickload(BestSlot)
				tempScore = current.GetEnergyScore()
			end
		end
	end

	if current.GetEnergyScore() > currentScore then
		print("Script complete: +" .. (current.GetEnergyScore() - startScore) .. " -- " .. current.GetEnergyScore())
	else
		print("Script complete: " .. current.GetEnergyScore())
	end
	cleanup()
end -- END: function initBounceWiggle()

function runBounceWiggle()
	local currentScore = current.GetEnergyScore()
	local tempScore = currentScore
	local tempScore2 = tempScore
	save.Quicksave(BestSlot)
	--truly random numbers are not required
	local wiggle1Type = math.random(1, 4)
	local wiggle1Iterations = math.random(1, 3)
	local wiggle1CI = math.random(1, 1000) / 1000
	if wiggle1CI < 0.10 then
		wiggle1CI = 0.10
		behavior.SetClashImportance(wiggle1CI)
	else
		behavior.SetClashImportance(wiggle1CI)
	end
	local wiggle2Type = math.random(1, 4)
	behavior.SetClashImportance(wiggle1CI)

	if wiggle1Type > 3 then
		structure.LocalWiggleSelected(wiggle1Iterations)
		--wiggle1Type = "LocalWiggleSelected"
	elseif wiggle1Type > 2  then
		structure.WiggleSelected(wiggle1Iterations)
		--wiggle1Type = "LocalWiggleSelected"
	elseif wiggle1Type > 1 then
		structure.LocalWiggleAll(wiggle1Iterations)
		--wiggle1Type = "LocalWiggleSelected"
	else
		structure.WiggleAll(wiggle1Iterations)
		--wiggle1Type = "LocalWiggleSelected"
	end

	if doShake == true or doMutate == true then
		local shakeType = math.random(1, 3)
		local shakeIterations
		if numSegments <= 100 then
			shakeIterations = 4
		elseif numSegments <= 200 then
			shakeIterations = 2
		else
			shakeIterations = 1
		end
		local muIterations = 2
		local shakeCI = math.random(1, 1000) / 1000
		if shakeCI < 0.10 then
			shakeCI = 0.10
			behavior.SetClashImportance(shakeCI)
		else
			behavior.SetClashImportance(shakeCI)
		end

		if shakeType > 1 and doMutate == true then
			structure.MutateSidechainsAll(muIterations)
		elseif shakeType > 1 then
			structure.ShakeSidechainsAll(shakeIterations)
		else
			selection.DeselectAll()
			local shakeSelectionCount = math.random(1, numSegments())
			for n = 1, shakeSelectionCount do
				local selectSegment = math.random(1, numSegments())
				selection.Select(selectSegment)
			end
			if doMutate == true then
				structure.MutateSidechainsSelected(muIterations)
			else
				structure.ShakeSidechainsSelected(shakeIterations)
			end
			selection.SelectAll()
		end
	end

	behavior.SetClashImportance(1)

	if wiggle2Type > 3 then
		structure.LocalWiggleSelected(25)
		--wiggle2Type = "LocalWiggleSelected"
	elseif wiggle2Type > 2 then
		structure.WiggleSelected(25)
		--wiggle2Type = "WiggleSelected"
	elseif wiggle2Type > 1 then
		structure.LocalWiggleAll(25)
		--wiggle2Type = "LocalWiggleAll"
	else
		structure.WiggleAll(25)
		--wiggle2Type = "WiggleAll"
	end
	recentbest.Restore()
	tempScore = current.GetEnergyScore()
	if tempScore > (tempScore2 + minGain) then
		save.Quicksave(BestSlot)
		tempScore2 = tempScore
	else
		save.Quickload(BestSlot)
		tempScore = current.GetEnergyScore()
	end
end -- END: function runBounceWiggle()

startScore = current.GetEnergyScore()
originalCI = behavior.GetClashImportance()

xpcall(initBounceWiggle, cleanup)
