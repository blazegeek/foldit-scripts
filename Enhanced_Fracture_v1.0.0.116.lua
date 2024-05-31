scriptName = "Enchanced Fracture 1.0"
buildNumber = 122

debugOutput = false

function trunc(x)
	return math.floor(x * 1000) / 1000
end

function setCI(ci)
	return behavior.SetClashImportance(ci)
end

function getSS(sn)
	return structure.GetSecondaryStructure(sn)
end

function checkScore()
	local currentScore = 0
	if useEnergyScore == true then
		currentScore = current.GetEnergyScore()
	else
		currentScore = current.GetScore()
	end
	return currentScore
end

function checkBest()
	if testSubscoreImprovement == true then
		if subscorePart ~= 'total' then
			PT = current.GetSegmentEnergySubscore(rebuildSegment, subscorePart)
		else
			PT = current.GetSegmentEnergyScore(rebuildSegment)
		end
		if PT >= tempSegScore - 0.03 then
			beter = true
		else
			beter = false
		end
	else
		beter = true
	end

	if doingBanders == true then
		if banderBestScore < checkScore() then
			banderGain = checkScore() - banderBestScore
			banderGain = banderGain - banderGain % 0.001
			banderBestScore = checkScore()
			save.Quicksave(8)
		else
			banderGain = 0
		end
	elseif doingBanders == false then
		if beter == true then
			if bestScore < checkScore() then
				gain = checkScore() - bestScore
				gain = gain - gain % 0.001
				bestScore = checkScore()
				save.Quicksave(1)
				save.Quicksave(8)
				save.Quicksave(99)
			else
				gain = 0
			end
		else
			gain = 0
		end
	end

	if doingBanders == true then
		if banderGain > 0.01 then
			print("     +" .. banderGain .. " points")
		end
	elseif doingBanders == false then
		if gain > 0.01 then
			print("     +" .. gain .. " points")
		end
	end

	if banderBestScore > bestScore then
		bestScore = banderBestScore
		save.Quicksave(99)
		save.Quicksave(1)
	end
end

function generateSeed()
	-- REALLY good seed by Rav3n_pl
	seed = os.time() / math.abs(current.GetEnergyScore())
	seed = seed % 0.001
	seed = 1 / seed
	while seed < 10000000 do
		seed = seed * 10
	end
	seed = seed - seed % 1
	math.randomseed(seed)
end

function performWiggles(wiggleHow, wiggleIterations, wiggleRuns, minPPI)
	if disableFilters then
		behavior.SetSlowFiltersDisabled(true)
	end
	if wiggleHow == nil then
		wiggleHow = "wiggleAll"
	end
	if wiggleIterations == nil then
		wiggleIterations = 10 * iterationMultiplier
	else
		wiggleIterations = wiggleIterations * iterationMultiplier
	end
	if wiggleRuns == nil then
		wiggleRuns = 2
	end
	if minPPI == nil then
		minPPI = 1
	end
	wiggleIterations = math.ceil(wiggleIterations)
	if wiggleRuns > 0 then
		wiggleRuns = wiggleRuns - 1
		local currentScore = checkScore()
		if wiggleHow == "shakeSidechains" then
			if allAlanine == false then
				structure.ShakeSidechainsAll(1)
			end
		elseif wiggleHow == "wiggleBackbone" then
			structure.WiggleAll(wiggleIterations, true, false)
		elseif wiggleHow == "wiggleSidechains" then
			structure.WiggleAll(wiggleIterations, false, true)
		elseif wiggleHow == "wiggleAll" then
			structure.WiggleAll(wiggleIterations, true, true)
		end
		if checkScore() - currentScore > minPPI and wiggleHow ~= "shakeSidechains" then
			return performWiggles(wiggleHow, wiggleIterations, wiggleRuns, minPPI)
		end
	end
	if disableFilters then
		behavior.SetSlowFiltersDisabled(false)
	end
end

function checkMutable()
	if numSegments == nil then
		numSegments = structure.GetCount()
	end
	for i = 1, numSegments - 1 do
		if structure.IsMutable(i) then
			isMutable = true
			break
		end
	end
end

function checkReference()
	if numSegments == nil then
		numSegments = structure.GetCount()
	end
	for i = 1, numSegments do
		if current.GetSegmentEnergySubscore(i, "reference") ~= -0 then
			hasReference = true
			useReference = true
			break
		end
	end
end

function checkPairwise()
	if numSegments == nil then
		numSegments = structure.GetCount()
	end
	for i = 1, numSegments do
		if current.GetSegmentEnergySubscore(i, "pairwise") ~= -0 then
			hasPairwise = true
			usePairwise = true
			break
		end
	end
end

function checkDensity()
	if numSegments == nil then
		numSegments = structure.GetCount()
	end
	for i = 1, numSegments - 1 do
		if current.GetSegmentEnergySubscore(i, "density") ~= -0 then
			hasDensity = true
			useDensity = true
			break
		end
	end
end

function checkBander()
	if comdecom == false then
		both = false
		Bloat = false
	end
	if qval == nil then
		qval = 5
	end
	if Shap == nil and shap == nil and tryboth == nil then
		Shap = true
	end
	if fuzt == nil then
		fuzt = ( - 1 * 50)
	end
	if qci == nil then
		qci = (0.4 * maxCI)
	end
	if minB == nil then
		minB = 1
	end
	if pullci == nil then
		pullci = 0.9
	end
	if maxLoss == nil then
		maxLoss = 1
	end
	if minBS == nil then
		minBS = 0.2
	end
	if maxBS == nil then
		maxBS = 4
	end
	if noGains == nil then
		noGains = 1
	end
	if muta1 == nil then
		muta1 = false
	end
	if mut2 == nil then
		mut2 = false
	end
	if mut3 == nil then
		mut3 = false
	end
	if raci == nil then
		raci = true
	end
	if fuzt <= 0 then
		FF = ( - 1 * fuzt)
	end
	if Shap == false and shap == false and tryboth == false then
		Shap = true
		shap = false
		Hhrr = true
	elseif Shap == true and shap == true and tryboth == false then
		shap = true
		Shap = false
		Uhr = true
	elseif Shap == true and shap == true and tryboth == true then
		dehr = true
	elseif Shap == true and shap == false and tryboth == true then
		yuhr = true
	end
	if Hhrr or Uhr or dehr or yuhr == true then
		print("Fixed that for you:")
	end
	if yuhr == true then
		print("Heh. Trying both.")
	end
	if dehr == true then
		print("All three checked; trying both.")
	end
	if Hhrr == true then
		print("Nothing checked, pull, then wiggle only.")
	end
	if Uhr == true then
		print("Both checked, shake / mutate after pull. ")
	end
	if tryboth == true then
		shap = true
	end
end

function checkAlanine()
	allAlanine = false
	local countAlanine = 0
	for i = 1, structure.GetCount() do
		local Taa = structure.GetAminoAcid(i)
		if Taa == 'a' or Taa == 'g' then
			countAlanine = countAlanine + 1
		else
			allAlanine = false
			break
		end
	end
	if countAlanine >= numSegments then
		allAlanine = true
	end
	return allAlanine
end

function checkLock()
	lockd = 0 -- locked segment quantity counter
	locklist = {}
	if numSegments == nil then
		numSegments = structure.GetCount()
	end
	for k = 1, numSegments do -- k = segment identity counter
		if isMovable(k, k) == false then
			lockd = lockd + 1
			locklist[lockd] = k
		end
	end
	return locklist
end

function checkLengths(SecStr, length)
	local b = 0
	if numSegments == nil then
		numSegments = structure.GetCount()
	end
	for e = 1, numSegments do
		if getSS(e) ~= SecStr then
			b = b + 1
		else
			b = 0
		end
		if b >= length then
			broken = false
			break
		end
	end
end

function checkLockLengths(length)
	local v = 0
	broken = true
	if numSegments == nil then
		numSegments = structure.GetCount()
	end
	for e = 1, numSegments do
		if isMovable(e, e) == true then
			v = v + 1
		else
			v = 0
		end
		if v >= length then
			broken = false
			break
		end
	end
end

function optionsTest()
	if ciDo == nil then
		ciDo = false
	end
	if ciCh == nil then
		ciCh = 0
	end
	if ciCy == nil then
		ciCy = 50000000
	end
	if cyGa == nil then
		cyGa = 50000000
	end
	if notLoops == nil then
		notLoops = false
	end
	if notSheets == nil then
		notSheets = false
	end
	if notHelices == nil then
		notHelices = false
	end
	if shakeSphere == nil then
		shakeSphere = 8
	end
	if rebuildCI == nil then
		rebuildCI = 0.1
	end
	if cyclesPerRebuildLength == nil then
		cyclesPerRebuildLength = 1
	end
	if numSegments == nil then
		numSegments = structure.GetCount()
	end
	if endSegment == nil then
		endSegment = numSegments
	end
	if startSegment == nil then
		startSegment = 1
	end
	if rebuildLengthDelta == nil then
		if minRB ~= maxRB then
			if largestFirst == true then
				rebuildLengthDelta = -1
			else rebuildLengthDelta = 1
			end
		else
			rebuildLengthDelta = 0
		end
	end
end

function dialogPreset()
	--[[]]
	print("Early Game:")
	print("1 = DRW Small RB (3-4)")
	print("2 = DRW Large-Med RB (8-5)")
	print("3 = RR Large-Med RB (8-5)")
	print("4 = RR Small RB (4-2)")
	print("5 = RR Tiny RB (2-1)")
	print("Mid Game:")
	print("1 = DRW Med RB (6-4)")
	print("2 = RR Large-Med RB (8-5)")
	print("3 = RR Med-Small RB (6-3)")
	print("End Game:")
	print("1 = DRW Small RB (4-2)")
	print("2 = RR Small RB (4-2)")
	print("3 = DRW Acid Tweak (2-4)")
	print("4 = RR Acid Tweak (2-4)")
	print("")
	--]]--

	if band.GetCount() > 0 then
		for e = 1, band.GetCount() do
			if band.IsEnabled(e) then
				oldBands = band.GetCount()
				hasBands = true
			end
		end
	end
	local plc = 0
	for y = 1, numSegments, 4 do
		if getSS(y) == 'E' then
			plc = plc + 1
		end
		if plc >= 2 then
			plank = true
			break
		end
	end
	--for contact map puzzles
	--[[
	for y = 1, numSegments - 2 do
		for j = y + 2, numSegments do
			if contactmap.GetHeat(y, j) ~= 0 then
				ConP = true
				break
			end
		end
		if ConP then
			break
		end
	end
	]]--

	if numberOfRebuilds == nil then
		numberOfRebuilds = 5
	end
	if rebuildIterations == nil then
		rebuildIterations = 5
	end
	opt = dialog.CreateDialog(scriptName .. " build " .. buildNumber)
	opt.doCustom = dialog.AddCheckbox("Custom", false)
	opt.labelPresets = dialog.AddLabel("Presets:")
	opt.maxCI = dialog.AddSlider("Maximum CI:", maxCI, 0.1, 1, 2)
	opt.iterationMultiplier = dialog.AddSlider("Iteration Multiplier:", iterationMultiplier, 0.1, 10.0, 1)
	opt.startGame = dialog.AddCheckbox("Early Game - Fast & Loose ", false)
	opt.startGameLevel = dialog.AddSlider("", 1, 1, 9, 0)
	opt.midGame = dialog.AddCheckbox("Mid Game - Deep Rebuild & Refine ", false)
	opt.midGameLevel = dialog.AddSlider("", 1, 1, 3, 0)
	opt.endGame = dialog.AddCheckbox("End Game - Idealize & Polish ", false)
	opt.endGameLevel = dialog.AddSlider("", 1, 1, 4, 0)
	opt.labelExtra = dialog.AddLabel("Extra Options:")
	opt.numberOfRebuilds = dialog.AddSlider("Number of Rebuilds: ", numberOfRebuilds, 1, 20, 0)
	opt.rebuildIterations = dialog.AddSlider("Rebuild Iterations: ", rebuildIterations, 1, 20, 0)
	opt.forceBest = dialog.AddCheckbox("Force rebuild best", false)
	opt.labelVariables = dialog.AddLabel("Variables:")
	opt.allLoops = dialog.AddCheckbox("Change to loop before rebuild", false)
	opt.doBanders = dialog.AddCheckbox("I'll have Banders with that", false)
	opt.doReSort = dialog.AddCheckbox("Re-sort after every rebuild", false)

	-- puzzle specific
	if isMutable == true then
		opt.mutaL = dialog.AddCheckbox("Mutate locally;", true)
		opt.muta = dialog.AddCheckbox("and in fuze.", false)
	end
	if hasBands == true then
		opt.keepBands = dialog.AddCheckbox("Keep bands, disable during rebuild", true)
		opt.keepBandsEnabled = dialog.AddCheckbox("Keep bands enabled", false)
		opt.keepBandStrength = dialog.AddCheckbox("Keep original strength and goal length", true)
	end

	--opt.totalOnly = dialog.AddCheckbox("Target total subscore only", false)
	opt.doShortCycles = dialog.AddCheckbox("Shorter Cycles", false)
	opt.doThoroughMode = dialog.AddCheckbox("Thorough Mode", false)

	opt.disableFilters = dialog.AddCheckbox("Disable slow filters during wiggle.", false)
	opt.selectSubscores = dialog.AddButton("Subscores", 2)
	opt.ok = dialog.AddButton("Start", 1)
	opt.cancel = dialog.AddButton("Cancel", 0)

	local dialogBoxCode = dialog.Show(opt)

	if dialogBoxCode > 0 then
		allLoops = opt.allLoops.value
		doCustom = opt.doCustom.value
		doShortCycles = opt.doShortCycles.value
		doThoroughMode = opt.doThoroughMode.value
		doReSort = opt.doReSort.value
		numberOfRebuilds = opt.numberOfRebuilds.value
		rebuildIterations = opt.rebuildIterations.value
		forceBest = opt.forceBest.value

		if doCustom == true then
			return dialogCustom()
		end

		startGame = opt.startGame.value
		startGameLevel = opt.startGameLevel.value
		midGame = opt.midGame.value
		midGameLevel = opt.midGameLevel.value
		endGame = opt.endGame.value
		endGameLevel = opt.endGameLevel.value
		maxCI = opt.maxCI.value
		disableFilters = opt.disableFilters.value
		iterationMultiplier = opt.iterationMultiplier.value

		if isMutable == true then
			muta = opt.muta.value
			mutaL = opt.mutaL.value
		else
			muta = false
			mutaL = false
		end

		if hasBands == true then
			keepBands = opt.keepBands.value
			keepBandsEnabled = opt.keepBandsEnabled.value
			keepBandStrength = opt.keepBandStrength.value
		end

		if doCustom == false and startGame == false and midGame == false and endGame == false then
			dialogPreset()
		end
		if startGame == true and (midGame == true or endGame == true) then
			dialogPreset()
		end
		if midGame == true and (startGame == true or endGame == true) then
			dialogPreset()
		end

		if opt.doBanders.value == true then
			dialogBandersPreset()
		end
		--return doCustom, maxCI, startGame, startGameLevel, midGame, midGameLevel, endGame, endGameLevel, disableFilters, doReSort
	end
	return dialogBoxCode
end

function dialogSubscores()
	subscorePopup = dialog.CreateDialog("Subscore Selection")
	subscorePopup.useTotal = dialog.AddCheckbox("Total", useTotal)
	subscorePopup.useIdeality = dialog.AddCheckbox("Ideality", useIdeality)
	subscorePopup.useSidechain = dialog.AddCheckbox("Sidechain", useSidechain)
	subscorePopup.useBonding = dialog.AddCheckbox("Bonding", useBonding)
	subscorePopup.useClashing = dialog.AddCheckbox("Clashing", useClashing)
	subscorePopup.useHiding = dialog.AddCheckbox("Hiding", useHiding)
	subscorePopup.usePacking = dialog.AddCheckbox("Packing", usePacking)
	subscorePopup.useBackbone = dialog.AddCheckbox("Backbone", useBackbone)
	if hasPairwise == true then
		subscorePopup.usePairwise = dialog.AddCheckbox("Pairwise", usePairwise)
	end
	if hasReference == true then
		subscorePopup.useReference = dialog.AddCheckbox("Reference", useReference)
	end
	if hasDensity == true then
		subscorePopup.useDensity = dialog.AddCheckbox("Density", useDensity)
	end
	subscorePopup.ok = dialog.AddButton("OK", 1)
	subscorePopup.cancel = dialog.AddButton("Cancel", 0)

	local dialogBoxCode = dialog.Show(subscorePopup)

	if dialogBoxCode > 0 then
		useTotal = subscorePopup.useTotal.value
		useIdeality = subscorePopup.useIdeality.value
		useSidechain = subscorePopup.useSidechain.value
		useBonding = subscorePopup.useBonding.value
		useClashing = subscorePopup.useClashing.value
		useHiding = subscorePopup.useHiding.value
		useBackbone = subscorePopup.useBackbone.value
		usePacking = subscorePopup.usePacking.value
		if hasPairwise == true then
			usePairwise = subscorePopup.usePairwise.value
		end
		if hasReference == true then
			useReference = subscorePopup.useReference.value
		end
		if hasDensity == true then
			useDensity = subscorePopup.useDensity.value
		end
		--selectedSubscores = {}
		--listIndex = 1
	end
	return dialogBoxCode
end

function dialogBandersPreset()
	-- called from dialogPreset() ONLY
	comdecom = true
	opt = dialog.CreateDialog("Banders")
	opt.wosl = dialog.AddLabel("Slider value = Bander intensity")
	opt.w1sl = dialog.AddLabel("1 is weak, fuzing; 3 is strong, altering")
	opt.w2sl = dialog.AddLabel("Previous choice of preset factors in as well")
	opt.wos = dialog.AddSlider("", 1, 1, 3, 0)
	opt.prebis = dialog.AddCheckbox(" Spacebands. ", false)
	if ConP then
		opt.conp = dialog.AddCheckbox("Use local contact map bands after every rebuild", true)
	end
	opt.rbldcomp = dialog.AddCheckbox("Bander after every rebuild", false)
	opt.cyclecomp = dialog.AddCheckbox("Bander after every cycle", true)
	opt.doBandersFirst = dialog.AddCheckbox("Start with a cycle of bander", false)
	opt.ok = dialog.AddButton("Go go!", 1)
	dialog.Show(opt)
	cyclecomp = opt.cyclecomp.value
	rbldcomp = opt.rbldcomp.value
	doSpaceBands = opt.prebis.value
	doBandersFirst = opt.doBandersFirst.value
	BSl = opt.wos.value
	if ConP then
		if opt.conp.value then
			ConB = true
		end
	end
	bandson = false
		comdecom = true
		bloat = false
		shap = true
		tryboth = true
		raci = true
		fuzt = 1.5
		pullci = 0.9
	if startGame == true then
		SinSq = false
		------- end local
		runs = 10
		both = false
		minB = 8
		------- end basic
		if BSl == 1 then
			-- weak
			maxLoss = 0.6
			minBS = 0.1
			maxBS = 0.7
		elseif BSl == 2 then
			-- med
			maxLoss = 1
			minBS = 0.1
			maxBS = 1.5
		elseif BSl == 3 then
			-- strong
			maxLoss = 1.5
			minBS = 0.4
			maxBS = 3
		end
	elseif midGame == true then
		SinSq = true
		Qradius = 7
		LoBaCD = false
		LBstr = 0.4
		------- end local
		runs = 20
		both = false
		------- end basic
		if BSl == 1 then
			-- weak
			minB = 2
			maxLoss = 0.6
			minBS = 0.1
			maxBS = 0.7
		elseif BSl == 2 then
			-- med
			minB = 8
			maxLoss = 1
			minBS = 0.1
			maxBS = 1.5
		elseif BSl == 3 then
			-- strong
			minB = 8
			maxLoss = 1.5
			minBS = 0.4
			maxBS = 3
		end
	elseif endGame == true then
		SinSq = true
		Qradius = 7
		LoBaCD = true
		LBstr = 0.6
		------- end local
		runs = 40
		both = true
		------- end basic
		if BSl == 1 then
			-- weak
			minB = 1
			maxLoss = 1
			minBS = 0.1
			maxBS = 1.3
		elseif BSl == 2 then
			-- med
			minB = 4
			maxLoss = 1
			minBS = 0.1
			maxBS = 2
		elseif BSl == 3 then
			-- strong
			minB = 1
			maxLoss = 1.7
			minBS = 0.4
			maxBS = 3
		end
	end
	if ConB then
		SinSq = true
	end
	return cyclecomp, rbldcomp, bandson, SinSq, Qradius, LoBaCD, LBstr, runs, comdecom, both, bloat, shap, tryboth, raci, minB, maxLoss, minBS, maxBS, fuzt, pullci, comdecom, doSpaceBands, doBandersFirst, ConB, ConP
end

function dialogCustom()
	-- called from dialogPreset() ONLY
	opt = dialog.CreateDialog("Fracture: Executive Edition")
	opt.doRainbowRebuild = dialog.AddCheckbox("RR instead of DRW", false)
	opt.Bndr = dialog.AddCheckbox("Bander", true)
	opt.maxCI = dialog.AddSlider("Maximum CI:", maxCI, 0.1, 1, 2)
	opt.rblbl = dialog.AddLabel("RB Length:")
	opt.maxRebuildLength = dialog.AddSlider("Max:", 5, 1, maxRebuildLength, 0)
	opt.minrblng = dialog.AddSlider("Min:", 2, 1, maxRebuildLength, 0)
	opt.worstFirst = dialog.AddCheckbox("Longest First", true)
	opt.fuze = dialog.AddSlider("Fuze Threshold:", -50, -200, 100, 1)
	opt.Sf = dialog.AddCheckbox("Short Fuze", true)
	opt.qStabDo = dialog.AddCheckbox("qStab", false)
	opt.doIdealize = dialog.AddCheckbox("Idealize (Beware of large RB lengths)", true)
	if isMutable == true then
		opt.mutaL = dialog.AddCheckbox("Mutate Locally", true)
		opt.muta = dialog.AddCheckbox("and in fuze?", false)
	end
	if hasBands == true then
		opt.keepBands = dialog.AddCheckbox("Keep bands, disable during rebuild", true)
		opt.keepBandsEnabled = dialog.AddCheckbox("Keep bands enabled", false)
		opt.keepBandStrength = dialog.AddCheckbox("Keep original strength and goal length", true)
	end
	opt.disableFilters = dialog.AddCheckbox("Disable slow filters during wiggle", true)
	opt.aa = dialog.AddLabel("")
	opt.allLoops = dialog.AddCheckbox("Change to loop before rebuild", false)
	opt.AO = dialog.AddCheckbox("More Options", false)
	opt.ok = dialog.AddButton("Start", 1)
	dialog.Show(opt)
	if isMutable == true then
		muta = opt.muta.value
		mutaL = opt.mutaL.value
	else
		muta = false
		mutaL = false
	end
	if hasBands == true then
		keepBands = opt.keepBands.value
		keepBandsEnabled = opt.keepBandsEnabled.value
		keepBandStrength = opt.keepBandStrength.value
	end
	doRainbowRebuild = opt.doRainbowRebuild.value
	Sf = opt.Sf.value
	fzt = opt.fuze.value
	maxCI = opt.maxCI.value
	qStabDo = opt.qStabDo.value
	disableFilters = opt.disableFilters.value
	allLoops = opt.allLoops.value
	maxRB = opt.maxRebuildLength.value
	minRB = opt.minrblng.value
	largestFirst = opt.worstFirst.value
	if minRB > maxRB then
		mnnrb = minRB
		mxxrb = maxRB
		minRB = mxxrb
		maxRB = mnnrb
	end
	if largestFirst == true then
		rebuildLength = maxRB
	elseif largestFirst == false then
		rebuildLength = minRB
	end
	Bndrss = opt.Bndr.value
	doIdealize = opt.doIdealize.value
	if opt.AO.value == true then
		dialogMoreOptions()
	elseif (opt.AO.value == false) and (minRB ~= maxRB) then
		if largestFirst == true then
			rebuildLengthDelta = -1
		elseif largestFirst == false then
			rebuildLengthDelta = 1
		end
	end
	if Bndrss == true then
		dialogMainBanderOptions()
	end
	if band.GetCount() > 0 and keepBands == false and keepBandsEnabled == false then
		band.DeleteAll()
	end
	if fzt <= 0 then
		FFzt = ( - 1 * fzt)
	else
	end
	if doRainbowRebuild == true then
		dialogOptionsRR()
	else
		dialogOptionsDRW()
	end
	return qStabDo, rebuildLength, allLoops, Sf, fzt, FFzt, maxCI, Bndrss, doIdealize, largestFirst, minRB, maxRB, disableFilters
end

function dialogMoreOptions()
	-- called from dialogCustom() ONLY
	opt = dialog.CreateDialog("More Options")
	if minRB ~= maxRB then
		opt.rbc = dialog.AddLabel("Change Rebuild Length by x after y cycles")
		if largestFirst == true then
			opt.rebuildLengthDelta = dialog.AddSlider("        x", -1, -1 * (maxRB - minRB), 0, 0)
		elseif largestFirst == false then
			opt.rebuildLengthDelta = dialog.AddSlider("        x", 1, 0, (maxRB - rebuildLength), 0)
		end
	opt.cyclesPerRebuildLength = dialog.AddSlider("        y", 2, 1, 50, 0)
	end
	opt.mxl = dialog.AddLabel("Change max CI by x after y cycles with less than z gain")
	opt.ciDo = dialog.AddCheckbox(" uncheck to NOT do this", false)
	opt.ciCh = dialog.AddSlider("        x", 0.1, 0.05, 0.95, 2)
	opt.ciCy = dialog.AddSlider("        y", 5, 1, 50, 0)
	opt.cyGa = dialog.AddSlider("        z", 0, 0, 500, 0)
	opt.aab = dialog.AddLabel("")
	opt.rebuildCI = dialog.AddSlider("Rebuild CI value:", 0.1, 0, 1, 2)
	opt.sphere = dialog.AddSlider("Shake Sphere:", 7, 4, 50, 0)
	opt.notsh = dialog.AddCheckbox("Don't rebuild sheets", false)
	opt.nothe = dialog.AddCheckbox("Don't rebuild helices", false)
	opt.notlo = dialog.AddCheckbox("Don't rebuild loops", false)
	opt.ok = dialog.AddButton("Start", 1)
	dialog.Show(opt)
	shakeSphere = opt.sphere.value
	ciCh = opt.ciCh.value
	ciCy = opt.ciCy.value
	cyGa = opt.cyGa.value
	ciDo = opt.ciDo.value
	if minRB ~= maxRB then
		rebuildLengthDelta = opt.rebuildLengthDelta.value
		cyclesPerRebuildLength = opt.cyclesPerRebuildLength.value
	end
	rebuildCI = opt.rebuildCI.value
	notHelices = opt.nothe.value
	notSheets = opt.notsh.value
	notLoops = opt.notlo.value
	return ciCh, ciCy, cyGa, ciDo, notLoops, notSheets, notHelices, rebuildCI, rebuildLengthDelta, cyclesPerRebuildLength, shakeSphere
end

function dialogOptionsDRW()
	-- called from dialogCustom() AND dialogMoreOptionsDRW()
	opt = dialog.CreateDialog("DRW Options.")
	opt.a = dialog.AddLabel("Choose one scorepart:")
	opt.b = dialog.AddCheckbox("backbone", true)
	opt.to = dialog.AddCheckbox("total", false)
	opt.c = dialog.AddCheckbox("other", false)
	opt.worstFirst = dialog.AddCheckbox("Worst scoring first (uncheck is best scoring)", true)
	opt.testSubscoreImprovement = dialog.AddCheckbox("Chosen scorepart MUST improve to accept gains", false)
	opt.fewerTests = dialog.AddCheckbox("Less testing if scorepart too low", false)
	opt.ltl = dialog.AddLabel("    ^('every rebuild' banders and fuze will be skipped)")
	opt.doReSort = dialog.AddCheckbox("Re-sort after every rebuild", true)
	opt.gsort = dialog.AddCheckbox("Gary sort: after x succesful rebuilds", false)
	opt.perscnt = dialog.AddCheckbox("Persistant Counter", false)
	opt.cntG = dialog.AddSlider("x for Gary sort:", (maxRPC / 4), 1, maxRPC, 0)
	opt.maxCycles = dialog.AddSlider("Number of cycles:", 1000, 1, 1000, 0)
	opt.rebuildsPerCycle = dialog.AddSlider("Rebuilds per cycle:", (maxRPC / 2) + 2, 1, maxRPC, 0)
	opt.lal = dialog.AddLabel("Start and End Segment for DRW")
	opt.startSegment = dialog.AddSlider("Start Seg:", startSegment, 1, endSegment, 0)
	opt.endSegment = dialog.AddSlider("End Seg:", endSegment, 2, endSegment, 0)
	opt.norl = dialog.AddLabel("Number of RB per segment:")
	opt.numberOfRebuilds = dialog.AddSlider("", 10, 1, 60, 0)
	opt.doWiggleSidechains = dialog.AddCheckbox("Wiggle Sidechains every rebuild iteration", false)
	opt.doLocalWiggle = dialog.AddCheckbox("Local wiggle every rebuild iteration", false)
	opt.doGlobalWiggle = dialog.AddCheckbox("Global wiggle every rebuild iteration", false)
	if comdecom == true or doSpaceBands == true then
		opt.rbldcomp = dialog.AddCheckbox("Bander after every rebuild. (qkrbld style)", false)
		opt.cyclecomp = dialog.AddCheckbox("Bander after every cycle. (tvdl comp style)", true)
	end
	if isMutable == true then
		opt.bm = dialog.AddCheckbox("Bruteforce mutate after every cycle", false)
	end
	opt.ok = dialog.AddButton("Start", 1)
	dialog.Show(opt)
	doReSort = opt.doReSort.value
	cntGary = opt.cntG.value
	gsort = opt.gsort.value
	PersCnt = opt.perscnt.value
	if isMutable == true then
		bfm = opt.bm.value
	end
	testSubscoreImprovement = opt.testSubscoreImprovement.value
	fewerTests = opt.fewerTests.value
	worstFirst = opt.worstFirst.value
	endSegment = opt.endSegment.value
	startSegment = opt.startSegment.value
	rebuildsPerCycle = opt.rebuildsPerCycle.value
	numberOfRebuilds = opt.numberOfRebuilds.value
	doLocalWiggle = opt.doLocalWiggle.value
	doGlobalWiggle = opt.doGlobalWiggle.value
	doWiggleSidechains = opt.doWiggleSidechains.value
	maxCycles = opt.maxCycles.value
	if comdecom == true or doSpaceBands == true then
		cyclecomp = opt.cyclecomp.value
		rbldcomp = opt.rbldcomp.value
	end
	if startSegment > endSegment then
		startSegment = 1
		endSegment = numSegments
	end
	if rebuildLength > (endSegment - startSegment) then
		rebuildLength = (endSegment - startSegment) + 1
	end
	if opt.to.value == true then
		subscorePart = "total"
	end
	if opt.b.value == true then
		subscorePart = "backbone"
	end
	if opt.c.value == true or subscorePart == nil then
		getMoreOptions = true
	end
	if getMoreOptions == true then
		dialogMoreOptionsDRW()
	end
	return testSubscoreImprovement, subscorePart, doGlobalWiggle, doLocalWiggle, doWiggleSidechains, startSegment, endSegment, maxCycles, rebuildsPerCycle, numberOfRebuilds, worstFirst, cyclecomp, rbldcomp, garyCnt, cntGary, gsort, doReSort
end

function dialogOptionsRR()
	--called from dialogCustom() ONLY
	ask = dialog.CreateDialog("Rainbow Rebuilder Options")
	ask.maxCycles = dialog.AddSlider(" Nr. of cycles:", 500, 1, 1000, 0)
	ask.ll = dialog.AddLabel("Start and End Segment for RR")
	ask.startSegment = dialog.AddSlider("Start Seg:", startSegment, 1, endSegment, 0)
	ask.endSegment = dialog.AddSlider("End Seg:", endSegment, 0, endSegment, 0)
	ask.rebuildIterations = dialog.AddSlider("Rebuild iterations:", 2, 1, 27, 0)
	ask.doWiggleSidechains = dialog.AddCheckbox("Wiggle Sidechains", false)
	ask.doLocalWiggle = dialog.AddCheckbox("Local wiggle", false)
	if comdecom == true or doSpaceBands == true then
		ask.rbldcomp = dialog.AddCheckbox("Bander after every rebuild. (qkrbld style)", false)
		ask.cyclecomp = dialog.AddCheckbox("Bander after every cycle. (tvdl comp style)", true)
	end
	if isMutable == true then
		ask.bm = dialog.AddCheckbox("Bruteforce mutate after every cycle", false)
	end
	ask.ok = dialog.AddButton("Go go!", 1)
	dialog.Show(ask)
	if isMutable == true then
		bfm = ask.bm.value
	end
	if comdecom == true or doSpaceBands == true then
		cyclecomp = ask.cyclecomp.value
		rbldcomp = ask.rbldcomp.value
	end
	startSegment = ask.startSegment.value
	endSegment = ask.endSegment.value
	rebuildIterations = ask.rebuildIterations.value
	maxCycles = ask.maxCycles.value
	if startSegment > endSegment then
		startSegment = 1
		endSegment = numSegments
	end
	if rebuildLength > (endSegment - startSegment) then
		rebuildLength = (endSegment - startSegment) + 1
	end
	return startSegment, endSegment, rebuildIterations, maxCycles, cyclecomp, rbldcomp
end

function dialogMoreOptionsDRW()
	-- called from dialogOptionsDRW() ONLY
	if getMoreOptions == true then
		-- THIS DIALOG IS NOW REDUNDANT
		opt = dialog.CreateDialog("Choose one subscore")
		opt.aa = dialog.AddLabel("")
		opt.cl = dialog.AddCheckbox("clashing", false)
		opt.p = dialog.AddCheckbox("packing", false)
		opt.h = dialog.AddCheckbox("hiding", false)
		opt.s = dialog.AddCheckbox("sidechain", false)
		opt.bo = dialog.AddCheckbox("bonding", false)
		opt.ide = dialog.AddCheckbox("ideality", false)
		if hasDensity == true then
			opt.useDensity = dialog.AddCheckbox("density", true)
		end
		opt.ok = dialog.AddButton("Start", 1)
		dialog.Show(opt)
		useDensity = opt.useDensity.value
		if opt.ide.value == true then
			subscorePart = "ideality"
		end
		if opt.bo.value == true then
			subscorePart = "bonding"
		end
		if opt.s.value == true then
			subscorePart = "sidechain"
		end
		if opt.cl.value == true then
			subscorePart = "clashing"
		end
		if opt.p.value == true then
			subscorePart = "packing"
		end
		if opt.h.value == true then
			subscorePart = "hiding"
		end
		if hasDensity == true then
			if useDensity == true then
				subscorePart = "density"
			end
		end
	end
	if subscorePart == nil then
		return dialogOptionsDRW()
	end
end

function dialogMainBanderOptions()
	-- called from dialogCustom() ONLY
	ask = dialog.CreateDialog("Bander Options")
	ask.SinSq = dialog.AddCheckbox("Single squeeze / push local bands after rebuild", false)
	ask.comdecom = dialog.AddCheckbox("Compress / Decompress", true)
	ask.spb = dialog.AddCheckbox("Space bands", true)
	if plank == true then
		ask.Sti = dialog.AddCheckbox("Sheet Stitcher every rebuild", false)
	end
	ask.ok = dialog.AddButton("Go go!", 1)
	dialog.Show(ask)
	if plank == true then
		Stitch = ask.Sti.value
	end
	SinSq = ask.SinSq.value
	comdecom = ask.comdecom.value
	doSpaceBands = ask.spb.value
	if Stitch == nil then
		Stitch = false
	elseif Stitch then
		dialogSheetStitcher()
	end
	if SinSq then
		dialogLocalBands()
	end
	if comdecom == true or doSpaceBands == true then
		dialogMoreBanderOptions()
	end
	return SinSq, comdecom, doSpaceBands
end

function dialogSheetStitcher()
	-- called from dialogMainBanderOptions() ONLY
	ask = dialog.CreateDialog("Sheet Stitcher")
	ask.BStr = dialog.AddSlider("Band Strength:", 0.7, 0.1, 1, 2)
	ask.dis = dialog.AddSlider("Distance:", 7, 5, 15, 0)
	ask.frz = dialog.AddCheckbox("Freeze sheet backbone", true)
	ask.doFuzit = dialog.AddCheckbox("Fuze with bands", false)
	ask.ok = dialog.AddButton("Go go!", 1)
	dialog.Show(ask)
	doFuzit = ask.doFuzit.value
	BStr = ask.BStr.value
	distance = ask.dis.value
	frz = ask.frz.value
end

function dialogLocalBands()
	-- called from dialogExtraBanderOptions() ONLY
	ask = dialog.CreateDialog("Local Bands Options")
	ask.band = dialog.AddCheckbox("Contract. Uncheck for Expand", true)
	if ConP then
		ask.conp = dialog.AddCheckbox("Use only contact map bands", true)
	end
	ask.blurp = dialog.AddLabel("Max. distance radius size:")
	ask.Qradius = dialog.AddSlider("", 10, 6, 20, 0)
	ask.bstr = dialog.AddSlider("Band strength:", 0.4, 0.2, 2, 1)
	ask.ok = dialog.AddButton("Go go!", 1)
	dialog.Show(ask)
	Qradius = ask.Qradius.value
	if ConP then
		ConB = true
	end
	LoBaCD = ask.band.value
	LBstr = ask.bstr.value
	return Qradius, LoBaCD, LBstr, ConB
end

function dialogMoreBanderOptions()
	-- called from dialogMainBanderOptions() ONLY
	ask = dialog.CreateDialog("Bander Options")
	if comdecom == true then
		ask.bloat = dialog.AddCheckbox("Decompress. Unchecked = compress", false)
		if maxCI >= 0.8 then
			ask.both = dialog.AddCheckbox("Alternate both (overrides) ", true)
		else
			ask.both = dialog.AddCheckbox("Alternate both (overrides) ", false)
		end
	end
	ask.doBandersFirst = dialog.AddCheckbox("Start with a cycle of bander ", false)
	ask.bll = dialog.AddLabel("")
	ask.runs = dialog.AddSlider("Number of runs:", 12, 1, 200, 0)
	ask.MBndr = dialog.AddCheckbox("More options", false)
	ask.dr2 = dialog.AddLabel(" ")
	ask.noGa = dialog.AddLabel("Runs without gain before restore best")
	ask.noGains = dialog.AddSlider("", 3, 1, 100, 0)
	ask.Sf = dialog.AddCheckbox("Short fuze", true)
	ask.bandson = dialog.AddCheckbox("Fuze with bands on", false)
	ask.ok = dialog.AddButton("Go go!", 1)
	dialog.Show(ask)
	MBndr = ask.MBndr.value
	noGains = ask.noGains.value
	if comdecom == true then
		both = ask.both.value
		Bloat = ask.bloat.value
	end
	bandson = ask.bandson.value
	Sf = ask.Sf.value
	doBandersFirst = ask.doBandersFirst.value
	runs = ask.runs.value
	if MBndr == true then
		dialogEvenMoreBanderOptions()
	end
	return muta1, mut2, mut3, bandson, Sf, both, Bloat, qval, shap, Shap, fuzt, qci, minB, pullci, maxLoss, minBS, maxBS, runs, tryboth, FF, noGains, doBandersFirst
end

function dialogEvenMoreBanderOptions()
	-- called from dialogMoreBanderOptions() ONLY
	ask = dialog.CreateDialog("More Bander Options")
	ask.pullci = dialog.AddSlider("Banding CI:", 0.9, 0.1, 1, 1)
	ask.loss = dialog.AddLabel("Minimum % loss when perturbing")
	ask.maxloss = dialog.AddSlider("Min.:", maxLoss, 0.2, 10, 1)
	ask.minB = dialog.AddSlider("Min. # of bands:", 1, 1, 20, 0)
	ask.mia = dialog.AddLabel("Minimum / maximum band strength")
	ask.minbs = dialog.AddSlider("Min.:", 0.5, 0.1, 0.7, 1)
	ask.maxbs = dialog.AddSlider("Max.:", 2, 0.3, 4, 1)
	ask.ShaMutPull = dialog.AddLabel("Shake / mutate after bands?")
	ask.shap = dialog.AddCheckbox("Yes", false)
	ask.Shap = dialog.AddCheckbox("No; Perturb, then wiggle only", false)
	ask.trb = dialog.AddCheckbox("Try both", true)
	ask.qlab = dialog.AddLabel("Shake CI after bands ")
	ask.qci = dialog.AddSlider("CI:", (0.2 * maxCI), 0.01, 1, 2)
	ask.raci = dialog.AddCheckbox(" Use random CI (overrides)", true)
	ask.qla = dialog.AddLabel("qStab if score drops more than %: (otherwise wiggle only)")
	ask.qval = dialog.AddSlider("", 5, 1, 20, 0)
	ask.fu = dialog.AddLabel("Fuzing threshold (negative value is only on gain)")
	ask.fuz = dialog.AddSlider("", -50, -50, 100, 1)
	if isMutable == true then
		ask.mut = dialog.AddCheckbox("Mutate after Bands", false)
		ask.mut2 = dialog.AddCheckbox("Mutate during qStab", false)
		ask.mut3 = dialog.AddCheckbox("Mutate during Fuze", false)
	end
	ask.ok = dialog.AddButton("Go go!", 1)
	dialog.Show(ask)
	raci = ask.raci.value
	qval = ask.qval.value
	shap = ask.shap.value
	Shap = ask.Shap.value
	fuzt = ask.fuz.value
	qci = ask.qci.value
	minB = ask.minB.value
	pullci = ask.pullci.value
	maxLoss = ask.maxloss.value
	minBS = ask.minbs.value
	maxBS = ask.maxbs.value
	tryboth = ask.trb.value
	if isMutable == true then
		muta1 = ask.mut.value
		mut2 = ask.mut2.value
		mut3 = ask.mut3.value
	end
end

function performFuze()
	checkAlanine()
	setCI(0.05)
	performWiggles("shakeSidechains")
	checkBest()
	setCI(maxCI)
	performWiggles("wiggleAll", 9)
	checkBest()
	setCI(maxCI / 3)
	performWiggles("wiggleAll", 3)
	checkBest()
	if Sf == false then
		setCI(0.07)
		performWiggles("shakeSidechains")
		checkBest()
		setCI(maxCI)
		performWiggles("wiggleAll", 9)
		checkBest()
		setCI(maxCI / 3)
		performWiggles("wiggleAll", 3)
		checkBest()
	end
	setCI(maxCI)
	performWiggles("wiggleAll", 9)
	checkBest()
	performWiggles("shakeSidechains")
	checkBest()
	performWiggles("wiggleAll", 9)
	recentbest.Restore()
	checkBest()
end

function performFuzeMutate()
	checkAlanine()
	setCI(0.15)
	selectMutas()
	structure.MutateSidechainsSelected(1)
	checkBest()
	selection.DeselectAll()
	setCI(maxCI)
	performWiggles("wiggleAll", 9)
	checkBest()
	setCI(maxCI / 3)
	performWiggles("wiggleAll", 3)
	checkBest()
	setCI(maxCI)
	performWiggles("wiggleAll", 9)
	checkBest()
	if Sf == false then
		checkAlanine()
		setCI(0.2)
		performWiggles("shakeSidechains")
		checkBest()
		setCI(maxCI)
		performWiggles()
		checkBest()
		setCI(maxCI / 2)
		performWiggles()
		checkBest()
		setCI(0.87 * maxCI)
		selectMutas()
		structure.MutateSidechainsSelected(1)
		checkBest()
		selection.DeselectAll()
	end
	setCI(maxCI)
	performWiggles("wiggleAll", 9)
	recentbest.Restore()
	checkBest()
end

function performFuzing()
	if doingBanders == true then
		print("Fuzing...")
		if mut3 == true then
			performFuzeMutate()
		else
			performFuze()
		end
	else
		if muta then
			performFuzeMutate()
		else
			performFuze()
		end
	end
	performWiggles("wiggleAll", 6)
	checkBest()
end

function qStab()
	checkAlanine()
	if doingBanders == true then
		setCI(maxCI / 2)
		performWiggles("wiggleAll", 5)
		checkBest()
		setCI(maxCI)
		performWiggles("wiggleAll", 9)
		checkBest()
		if mut2 == true then
			selectMutas()
			structure.MutateSidechainsSelected(1)
			checkBest()
			selection.DeselectAll()
			performWiggles("shakeSidechains")
			checkBest()
		else
			performWiggles("shakeSidechains")
			checkBest()
		end
		setCI(maxCI / 2)
		performWiggles("wiggleAll", 5)
		checkBest()
		setCI(maxCI)
		performWiggles("wiggleAll", 9)
		checkBest()
	else
		setCI(maxCI / 3)
		performWiggles("wiggleAll", 3)
		checkBest()
		setCI(maxCI)
		performWiggles("shakeSidechains")
		checkBest()
		performWiggles("wiggleAll", 9)
		checkBest()
	end
	recentbest.Restore()
	checkBest()
end

function allWalk()
	lscore = checkScore()
	print("Bruteforce...")
	for j = 1, #AAs do
		for i = 1, numSegments do
			origA = structure.GetAminoAcid(i)
			if structure.CanMutate(i, AAs[j]) then
				structure.SetAminoAcid(i, AAs[j])
				checkBest()
				save.Quickload(99)
				newA = structure.GetAminoAcid(i)
				if newA ~= origA then
					print("Residue " .. i .. " changed from " .. origA .. " to " .. newA)
				end
			end
		end
	end -- aa
	if checkScore() > lscore then
		print("Gained: " .. trunc(checkScore() - lscore))
	else
		print("No change to score")
	end
end

function selectMutas()
	for i = 1, numSegments do
		if structure.IsMutable(i) == true then
			selection.Select(i)
		end
	end
end

function contains(x, value)
	for _, v in pairs(x) do
		if v == value then
			return true
		end
	end
	return false
end

function getSegmentSubscores(subscorePart)
	segmentSubscores = {}
	for i = 1, numSegments do
		segmentSubscores[i] = current.GetSegmentEnergySubscore(i, subscorePart)
	end
	return segmentSubscores
end

function getFragmentScores(rebuildLength)
	fragmentScores = {}
	for i = 1, numSegments - (rebuildLength - 1) do
		local fragmentTotal = 0
		for j = 0, rebuildLength - 1 do
			fragmentTotal = fragmentTotal + segmentSubscores[i + j]
		end
		fragmentScores[i] = {}
		fragmentScores[i][1] = fragmentTotal
		fragmentScores[i][2] = i
	end
	return fragmentScores
end

function sortFragmentScores()
	if #fragmentScores == 0 then
		getFragmentScores(rebuildLength)
	end
	table.sort(fragmentScores, function(a, b) return a[1] < b[1] end)
	return fragmentScores
end

function SortItWell(subscorePart) -- drjr
	grid = {}
	for i = 1, numSegments do
		grid[i] = {}
		if subscorePart ~= 'total' then
			grid[i][1] = current.GetSegmentEnergySubscore(i, subscorePart)
		else
			grid[i][1] = current.GetSegmentEnergyScore(i)
		end
		grid[i][2] = i
	end
	switch = 1
	while switch ~= 0 do
		switch = 0
		if worstFirst == true then
			for i = 1, numSegments - 1 do
				if grid[i][1] > grid[i + 1][1] then
					grid[i][1], grid[i + 1][1] = grid[i + 1][1], grid[i][1]
					grid[i][2], grid[i + 1][2] = grid[i + 1][2], grid[i][2]
					switch = switch + 1
				end
			end
		else
			for i = 1, numSegments - 1 do
				if grid[i][1] < grid[i + 1][1] then
					grid[i][1], grid[i + 1][1] = grid[i + 1][1], grid[i][1]
					grid[i][2], grid[i + 1][2] = grid[i + 1][2], grid[i][2]
					switch = switch + 1
				end
			end
		end
	end
	return grid
end

function isMovable(seg1, seg2)
	local FT = true
	for i = seg1, seg2 do
		BB, SC = freeze.IsFrozen(i)
		if BB == true then
			FT = false
		end
		sl = structure.IsLocked(i)
		if ( sl == true ) then
			FT = false
		end
	end
	return FT
end

function deleteBands()
	if keepBands == true then
		freshBands = band.GetCount()
		for h = originalBands, freshBands - 1 do
			band.Delete(originalBands + 1)
		end
	else
		band.DeleteAll()
	end
end

function disableBands(oldBands)
	if keepBandsEnabled == true then
		newBands = band.GetCount()
		for i = oldBands, newBands - 1 do
			band.Disable(i + 1)
		end
	else
		band.DisableAll()
	end
end

function selectSphere(segment, radius)
	if segment > numSegments then
		segment = numSegments
	end
	if segment < 1 then
		segment = 1
	end
	for i = 1, numSegments do
		if structure.GetDistance(segment, i) <= radius then
			if segment >= 1 and segment <= numSegments then
				selection.Select(i)
			end
		end
	end
end

function banderResult()
	save.Quickload(8)
	save.Quickload(99)
	recentbest.Restore()
	print("Score: " .. trunc(checkScore()))
	deleteBands()
end

function qTest()
	local loss = (bestScore * qval) / 100
	if checkScore() < bestScore - loss then
		qStab()
	else
		setCI(maxCI)
		performWiggles("wiggleAll", 6)
		checkBest()
	end
end

function spaceBands(amount)
	if comdecom == true then
		zeBands = (oldBands + (amount / 2))
	else
		zeBands = (oldBands + (1.8 * minB))
	end
	if minB == 1 then
		zeBands = zeBands + 2
	else
		zeBands = zeBands + 1.5
	end
	while band.GetCount() < zeBands do
		segO = math.random(numSegments)
		OsegC = 1
		while structure.IsLocked(segO) == true do
			segO = math.random(numSegments)
			OsegC = OsegC + 1
			if OsegC > 25 then
				break
			end
		end
		rho = math.random(10)
		theta = math.random(3.14159)
		phi = math.random(3.14159)
		if phi < 1 then
			phi = phi + 1
		end
		if theta < 1 then
			theta = theta + 1
		end
		if segO <= numSegments and segO >= 1 then
			if segO == numSegments then
				segX = segO - 1
				segY = segO - 2
			elseif segO == 1 then
				segX = segO + 1
				segY = segO + 2
			else
				segX = segO - 1
				segY = segO + 1
			end
			if segX > numSegments then
				segX = numSegments - 1
			end
			if segY > numSegments then
				segY = numSegments - 1
			end
			if segY < 1 then
				segY = 1
			end
			if segX < 1 then
				segX = 1
			end
			band.Add(segO, segX, segY, rho, theta, phi)
			local lb = band.GetCount()
			band.SetGoalLength(lb, math.random(band.GetLength(lb) * 2))
		end
	end
end

function createBands() -- make bands
	local dd = trunc(numSegments / 7)
	local start = math.random(dd)
	local len = trunc(math.random((numSegments - dd) / 2) + dd)
	local step = trunc(math.random((numSegments - dd) / 2) + dd)
	if luktni == false then
		for x = start, numSegments, step do
			for y = start + len, numSegments, step do
				if (y <= numSegments) and ((isMovable(y, y) == true) or (isMovable(x, x) == true)) then
					band.AddBetweenSegments(x, y)
				end
			end
		end
	elseif luktni == true then
		for x = start, numSegments, step do
			for y = numSegments - (numSegments / 8), numSegments, 1 do
				if (y <= numSegments) and ((isMovable(y, y) == true) or (isMovable(x, x) == true)) then
					band.AddBetweenSegments(x, y)
				end
			end
		end
		luktni = false
	end
end

function pull(minBS, maxBS) -- find band strength: 'slow bands'
	local ss = checkScore()
	local loss = (ss * maxLoss / 100)
	local lastBS = minBS
	for str = lastBS, maxBS, 0.1 do
		if keepBandStrength == true then
			local NNbands = band.GetCount()
			for i = oldBands + 1, NNbands do
				band.SetStrength(i, str)
			end
		else
			for i = 1, band.GetCount() do
				band.SetStrength(i, str)
			end
		end
		performWiggles("wiggleBackbone", 1)
		checkBest()
		if (ss - checkScore() >= loss) or (checkScore() > bestScore + 1) then
			if band.GetCount() > (numSegments / 10) * 2 then
				lastBS = str - 0.1
				if lastBS < minBS then
					lastBS = minBS
				end
			else
				lastBS = minBS
			end
			break
		end
	end
end

function bandage()
	if Bloat == true then
		if keepBandStrength == true then -- decompress
			local NNbands = band.GetCount()
			for i = oldBands + 1, NNbands do
				band.SetGoalLength(i, band.GetLength(i) + 4)
			end
		else
			for i = 1, band.GetCount() do
				band.SetGoalLength(i, band.GetLength(i) + 4)
			end
		end
	else
		if keepBandStrength == true then -- compress
			local NNbands = band.GetCount()
			for i = oldBands + 1, NNbands do
				local leng = band.GetLength(i)
				local perc = math.random(20, 50)
				local loss = ((perc * leng) / 100)
				band.SetGoalLength(i, band.GetLength(i) - loss)
			end
		else
			for i = 1, band.GetCount() do
				local leng = band.GetLength(i)
				local perc = math.random(20, 50)
				local loss = ((perc * leng) / 100)
				band.SetGoalLength(i, band.GetLength(i) - loss)
			end
		end
	end
end

function sheetStitcher() -- M. Suchard
	print("Stitcher")
	save.Quicksave(97)
	local Ssv = checkScore()
	for i = 2, numSegments do
		for y = i + 1, numSegments do
			if (structure.GetDistance(i, y) <= distance and getSS(i) == 'E' and getSS(y) == 'E') then
				band.AddBetweenSegments(i, y)
			end
		end
	end
	newbandsS = band.GetCount()
	for i = oldBands + 1, newbandsS do
		band.SetStrength(i, BStr)
	end

	if keepBandStrength == true then
		local NNbands = band.GetCount()
		for i = oldBands + 1, NNbands do
			band.SetGoalLength(i, band.GetLength(i))
		end
	else
		for i = 1, band.GetCount() do
			band.SetGoalLength(i, band.GetLength(i))
		end
	end
	if frz == true then
		for i = 1, numSegments do
			if getSS(i) == 'E' then
				selection.Select(i)
			end
		end
		freeze.FreezeSelected(true, false)
		selection.DeselectAll()
	end
	if doRainbowRebuild == true then
		for tt = xseg, xseg + rebuildLength - 1 do
			freeze.Unfreeze(tt, true, true)
		end
	else
		for tt = rebuildStart, rebuildEnd do
			freeze.Unfreeze(tt, true, true)
		end
	end

	local preci = behavior.GetClashImportance()
	setCI(maxCI)
	performWiggles()
	checkBest()
	if doingIdealize == false then
		if doFuzit == true then
			performFuze()
		end
	end
	if frz == true then
		for i = 1, numSegments do
			if freeze.IsFrozen(i) and getSS(i) == 'E' then
				freeze.Unfreeze(i, true, false)
			end
		end
	end
	setCI(preci)
	deleteBands()
	checkBest()
end

function localBands()
	checkBest()
	if LoBaCD == false then
		print("Local push...")
	else
		print("Local pull...")
	end

	if ConB then -- contact only or all in range
		if doRainbowRebuild == true then -- create local contact bands
			for y = xseg, xseg + rebuildLength - 1 do
				if y == numSegments then
					break
				end
				for j = 1, y - 1 do
					if contactmap.GetHeat(y, j) ~= 0 and structure.GetDistance(y, j) <= Qradius then
						band.AddBetweenSegments(y, j)
					end
				end
				if y <= numSegments - 2 then
					for j = y + 1, numSegments do
						if contactmap.GetHeat(y, j) ~= 0 and structure.GetDistance(y, j) <= Qradius then
							band.AddBetweenSegments(y, j)
						end
					end
				end
			end
		else
			for y = rebuildStart, rebuildEnd do
				if y == numSegments then
					break
				end
				for j = 1, y - 1 do
					if contactmap.GetHeat(y, j) ~= 0 and structure.GetDistance(y, j) <= Qradius then
						band.AddBetweenSegments(y, j)
					end
				end
				if y <= numSegments - 2 then
					for j = y + 1, numSegments do
						if contactmap.GetHeat(y, j) ~= 0 and structure.GetDistance(y, j) <= Qradius then
							band.AddBetweenSegments(y, j)
						end
					end
				end
			end
		end
	else
		for i = 1, numSegments do -- create local bands
			if doRainbowRebuild == true then
				for x = xseg, xseg + rebuildLength - 1 do
					if structure.GetDistance(i, x) <= Qradius then
						band.AddBetweenSegments(i, x)
					end
				end
			else
				for x = rebuildStart, rebuildEnd do
					if structure.GetDistance(i, x) <= Qradius then
						band.AddBetweenSegments(i, x)
					end
				end
			end
		end
	end

	if LoBaCD == false then -- push or pull
		if keepBandStrength == true then -- decompress
			local NNbands = band.GetCount()
			for i = oldBands + 1, NNbands do
				band.SetGoalLength(i, band.GetLength(i) + 4)
			end
		else
			for i = 1, band.GetCount() do
				band.SetGoalLength(i, band.GetLength(i) + 4)
			end
		end
	else
		if keepBandStrength == true then -- compress
			local NNbands = band.GetCount()
			for i = oldBands + 1, NNbands do
				band.SetGoalLength(i, band.GetLength(i))
				if band.GetLength(i) - 10 > 0 then
					band.SetGoalLength(i, band.GetLength(i) - 9)
				end
				if band.GetLength(i) - 6 > 0 then
					band.SetGoalLength(i, band.GetLength(i) - 5)
				end
				if band.GetLength(i) - 4 > 0 then
					band.SetGoalLength(i, band.GetLength(i) - 3)
				end
			end
		else
			for i = 1, band.GetCount() do
				band.SetGoalLength(i, band.GetLength(i))
				if band.GetLength(i) - 10 > 0 then
					band.SetGoalLength(i, band.GetLength(i) - 9)
				end
				if band.GetLength(i) - 6 > 0 then
					band.SetGoalLength(i, band.GetLength(i) - 5)
				end
				if band.GetLength(i) - 4 > 0 then
					band.SetGoalLength(i, band.GetLength(i) - 3)
				end
			end
		end
	end

	if keepBandStrength == true then -- band strength
		local NNbands = band.GetCount()
		for i = oldBands + 1, NNbands do
			band.SetStrength(i, LBstr)
		end
	else
		for i = 1, band.GetCount() do
			band.SetStrength(i, LBstr)
		end
	end

	setCI(maxCI)
	performWiggles("wiggleAll", 4)
	checkBest()
	if doRainbowRebuild == true then
		for tt = xseg, xseg + rebuildLength - 1 do
			selectSphere(tt, Qradius + 1)
		end
	else
		for tt = rebuildStart, rebuildEnd do
			selectSphere(tt, Qradius + 1)
		end
	end
	checkAlanine()
	if mut3 == true or mutaL == true or muta1 == true then
		setCI(maxCI)
		structure.MutateSidechainsSelected(1)
		checkBest()
		checkAlanine()
	else
		if allAlanine == false then
			setCI(maxCI)
			structure.ShakeSidechainsSelected(1)
			checkBest()
		end
	end
	setCI(maxCI)
	selection.DeselectAll()
	disableBands(oldBands)
	performWiggles("wiggleBackbone", 8)
	checkBest()
	performWiggles()
	checkBest()
	recentbest.Restore()
	deleteBands()
	checkBest()
end

function Bander()
	checkAlanine()
	yy = 0
	doingBanders = true
	deleteBands()
	selection.DeselectAll()
	recentbest.Save()
	banderStartScore = checkScore()
	banderBestScore = checkScore()
	save.Quicksave(8)
	if runs > 50 then
		print(runs .. " runs to go")
	end

	for bandruns = 1, runs do
		checkAlanine()
		if comdecom == true then
			if Bloat == true then
				print("Expand " .. bandruns .. " / " .. runs)
			else
				print("Contract " .. bandruns .. " / " .. runs)
			end
		else
			print("Spacebands " .. bandruns .. " / " .. runs)
		end
		if yy >= noGains or bandruns == 1 then
			save.Quickload(8)
			recentbest.Restore()
			yy = 0
		end

		deleteBands()
		Bscore = checkScore()

		if Bscore > banderStartScore + 0.1 or (bandruns == 1) then
			print(trunc(checkScore()))
		else
		end
		if Bscore > banderStartScore + 0.1 then
			print("Bander gain: " .. trunc(banderBestScore - banderStartScore), "Last gain: Run " .. ZZ)
		end
		if doSpaceBands == true and comdecom == false then
			amount = minB
			spaceBands(amount)
		elseif doSpaceBands == true and comdecom == true then
			amount = math.random(minB * 3)
			spaceBands(amount)
			createBands()
			if (bandruns * 33) % 2 ~= 0 then
				createBands()
			end
			if band.GetCount() < minB then
				createBands()
			end
			if band.GetCount() < minB then
				createBands()
			end
			if band.GetCount() <= oldBands then
				luktni = true
				createBands()
			end
		elseif (doSpaceBands == false) and (comdecom == true) then
			createBands()
			if (bandruns * 33) % 2 ~= 0 then
				createBands()
			end
			if band.GetCount() < minB then
				createBands()
			end
			if band.GetCount() < minB then
				createBands()
			end
			if band.GetCount() < minB then
				createBands()
			end
			if band.GetCount() < minB then
				createBands()
			end
			if band.GetCount() < minB then
				createBands()
			end
			if band.GetCount() < minB then
				createBands()
			end
			if band.GetCount() <= oldBands then
				luktni = true
				createBands()
			end
		end

		bandage()
		setCI(pullci * maxCI)
		pull(minBS, maxBS)
		print(trunc(checkScore()))
		if checkScore() > Bscore then -- if: pull has gained
			recentbest.Restore()
			checkBest()
		end
		save.Quicksave(97)

		if shap == true then
			if raci == true then
				ranci = (math.random(maxCI * 100) / 100)
				setCI(ranci)
			else
				setCI(qci)
			end
			if muta1 == true then
				selectMutas()
				structure.MutateSidechainsSelected(1)
				checkBest()
				selection.DeselectAll()
				performWiggles("shakeSidechains")
				checkBest()
			else
				performWiggles("shakeSidechains")
				checkBest()
			end
		end

		checkAlanine()
		disableBands(oldBands)
		setCI(maxCI)
		performWiggles()
		checkBest()
		if tryboth == true then
			save.Quickload(97)
		end
		disableBands(oldBands)
		performWiggles()
		checkBest()
		recentbest.Restore()
		checkBest()
		print(trunc(checkScore()))
		if bandson == true then
			print("Fuzing with bands...")
			band.EnableAll()
			performFuzing()
		end
		deleteBands()
		qTest()
		recentbest.Restore()
		checkBest()

		if fuzt >= 0 then
			if checkScore() > (Bscore - fuzt) then
				performFuzing()
			end
		else
			if checkScore() >= (Bscore + FF) then
				performFuzing()
			end
			recentbest.Restore()
		end
		if (banderBestScore - Bscore) > 0.1 then -- if: gain in this run
			TT = bandruns
			ZZ = TT
		end

		bandruns = bandruns + 1

		if both == true then
			if Bloat == true then
				Bloat = false
			elseif Bloat == false then
				Bloat = true
			end
		end

		if checkScore() - startScore <= 0.001 then
			yy = yy + 1
			recentbest.Restore()
			checkBest()
		end
	end

	banderResult()
	doingBanders = false
	checkBest()
	print("Gained: " .. trunc(banderBestScore - banderStartScore))
	checkAlanine()
end

function Result()
	print("")
	setCI(maxCI)
	if disableFilters then
		behavior.SetSlowFiltersDisabled(false)
	end
	checkBest()
	save.Quickload(99)
	save.Quickload(8)
	recentbest.Restore()
	checkBest()
	save.Quickload(1)
	Tgain = (bestScore - startScore)
	if Tgain < 0.001 then
		print("No change to score")
	else
		print("Start Score: " .. trunc(startScore))
		print("Score: " .. trunc(checkScore()))
		print("Total Gain: " .. trunc(Tgain) .. " points")
	end
	save.LoadSecondaryStructure()
	deleteBands()
end

function setParameters()
	maxCycles = 5000
	if doShortCycles == true then
		rebuildsPerCycle = 10
	else
		rebuildsPerCycle = 20 --(numSegments / 3)
	end
	numberOfRebuilds = 5
	rebuildIterations = 5

	Sf = true
	fzt = -1
	if fzt <= 0 then
		FFzt = ( - 1 * fzt)
	end
	qStabDo = false
	raci = true
	if band.GetCount() > 0 and keepBands == false and keepBandsEnabled == false then
		band.DeleteAll()
	end

	if startGame == true then
		doIdealize = false
		worstFirst = true
		if startGameLevel == 1 then
			doRainbowRebuild = false
			largestFirst = false
			minRB = 3
			maxRB = 4
		elseif startGameLevel == 2 then
			doRainbowRebuild = false
			largestFirst = true
			minRB = 9
			maxRB = 12
		elseif startGameLevel == 3 then
			doRainbowRebuild = false
			largestFirst = true
			minRB = 5
			maxRB = 8
		elseif startGameLevel == 4 then
			doRainbowRebuild = false
			largestFirst = true
			minRB = 2
			maxRB = 4
		elseif startGameLevel == 5 then
			doRainbowRebuild = false
			largestFirst = true
			minRB = 5
			maxRB = 12
		elseif startGameLevel == 6 then
			doRainbowRebuild = true
			largestFirst = true
			minRB = 9
			maxRB = 12
		elseif startGameLevel == 7 then
			doRainbowRebuild = true
			largestFirst = true
			minRB = 5
			maxRB = 8
		elseif startGameLevel == 8 then
			doRainbowRebuild = true
			largestFirst = true
			minRB = 2
			maxRB = 3
		elseif startGameLevel == 9 then
			doRainbowRebuild = true
			largestFirst = true
			minRB = 3
			maxRB = 12
		end
	elseif midGame == true then
		doIdealize = false
		worstFirst = true
		if midGameLevel == 1 then
			doRainbowRebuild = false
			largestFirst = true
			minRB = 4
			maxRB = 6
		elseif midGameLevel == 2 then
			doRainbowRebuild = true
			largestFirst = true
			minRB = 5
			maxRB = 8
		elseif midGameLevel == 3 then
			doRainbowRebuild = true
			largestFirst = true
			minRB = 3
			maxRB = 6
		end
	elseif endGame == true then
		doIdealize = true
		worstFirst = true
		minRB = 2
		maxRB = 4
		if endGameLevel == 1 then
			doRainbowRebuild = false
			largestFirst = true
		elseif endGameLevel == 2 then
			doRainbowRebuild = true
			largestFirst = true
		elseif endGameLevel == 3 then
			if totalOnly == true then
				subscorePart = "total"
			else
				subscorePart = "sidechain"
			end
			if doShortCycles == true then
				rebuildsPerCycle = math.floor((numSegments / 3) / 2)
			else
				rebuildsPerCycle = math.floor(numSegments / 3)
			end
			worstFirst = false
			doRainbowRebuild = false
			largestFirst = false
			doLocalWiggle = true
			doWiggleSidechains = true
		elseif endGameLevel == 4 then
			--subscorePart = "sidechain" -- this is not needed for RR
			if doShortCycles == true then
				rebuildsPerCycle = math.floor((numSegments / 3) / 2)
			else
				rebuildsPerCycle = math.floor(numSegments / 3)
			end
			worstFirst = false
			doRainbowRebuild = true
			largestFirst = false
			doLocalWiggle = true
			doWiggleSidechains = true
		end
	end

	if largestFirst == true then
		rebuildLength = maxRB
	elseif largestFirst == false then
		rebuildLength = minRB
	end

	if forceBest == true then
		worstFirst = false
	end

	if subscorePart == nil then
		-- if not already assigned, figure out which to start with
		if useDensity == true then
			subscorePart = "density"
		elseif useTotal == true then
			subscorePart = "total"
		elseif useIdeality == true then
			subscorePart = "ideality"
		elseif useSidechain == true then
			subscorePart = "sidechain"
		elseif useBonding == true then
			subscorePart = "bonding"
		elseif useClashing == true then
			subscorePart = "clashing"
		elseif useHiding == true then
			subscorePart = "hiding"
		elseif usePacking == true then
			subscorePart = "packing"
		elseif useBackbone == true then
			subscorePart = "backbone"
		elseif usePairwise == true then
			subscorePart = "pairwise"
		elseif useReference == true then
			subscorePart = "reference"
		else
			--print("Error: No scoreparts selected!")
			print("No scoreparts selected... using \"total\"")
			subscorePart = "total"
		end
	end
end

function performRainbowRebuild()
	for cycleCounter = 1, maxCycles do
		checkBest()
		if ciDo == true and rebuildCounter >= 1 then
			if cyGa > 0 then
				if (checkScore() - cRscore) <= cyGa then
					if goodCycles >= ciCy then
						maxCI = (maxCI + ciCh)
					end
				end
			elseif cyGa == 0 then
				if badCycles >= ciCy then
					maxCI = (maxCI + ciCh)
				end
			end
			if maxCI > 1 then
				maxCI = 1
			elseif maxCI <= 0 then
				maxCI = 0.15
			end
			print("Max CI = " .. maxCI)
			setCI(maxCI)
			performWiggles()
			checkBest()
			setCI(maxCI / 2)
			performWiggles()
			checkBest()
			setCI(maxCI)
			performWiggles()
			checkBest()
			recentbest.Restore()
			checkBest()
		end
		save.Quickload(99)
		cRscore = checkScore()

		if cycleCounter > cyclesPerRebuildLength then
			cycleCounter = 1
			rebuildLength = rebuildLength + rebuildLengthDelta
			if rebuildLengthDelta == 0 then
				startOfNewRound = true
			end
			if rebuildLength < minRB then
				rebuildLength = maxRB
				startOfNewRound = true
			end
			if rebuildLength > maxRB then
				rebuildLength = minRB
				startOfNewRound = true
			end
		end
		rebuildCounter = 0

		for seg = startSegment, endSegment - (rebuildLength - 1) do
			rebuildStart = seg
			rebuildEnd = seg + rebuildLength - 1
			selection.DeselectAll()
			broken = false
			for x = rebuildStart, rebuildEnd do
				if getSS(x) ~= 'L' then
					if notSheets then
						if getSS(x) == 'E' then
							broken = true
						end
					end
					if notHelices then
						if getSS(x) == 'H' then
							broken = true
						end
					end
				end
				if getSS(x) == 'L' then
					if notLoops then
						broken = true
					end
				end
			end
			if broken ~= true then
				if isMovable(rebuildStart, rebuildEnd) == true then
					save.Quickload(99)
					selection.SelectRange(rebuildStart, rebuildEnd)
					checkAlanine()
					if printRR == true then
						print("")
						totalCycles = totalCycles + 1
						print("Cycle " .. totalCycles .. " / " .. maxCycles - minusR)
						--print("Rebuild Length: " .. rebuildLength)
						print("Range: " .. startSegment .. " - " .. endSegment, "Rebuild Length: " .. rebuildLength)
						print("Starting score this cycle: " .. trunc(checkScore()))
						printRR = false
					end
					rebuildCounter = rebuildCounter + 1
					print("Rebuild:", rebuildCounter .. " / " .. endSegment - (rebuildLength - 1), "Segments:", rebuildStart .. " - " .. rebuildEnd, trunc(checkScore()), os.date("%X"))
					xseg = seg -- for sheet stitcher, local bands
					oldScore = checkScore()
					if allLoops then
						for e = 1, numSegments do
							if selection.IsSelected(e) then
								structure.SetSecondaryStructure(e, "L")
							end
						end
					end
					setCI(rebuildCI)
					disableBands(oldBands)
					structure.RebuildSelected(1)
					recentbest.Save()
					structure.RebuildSelected(rebuildIterations)
					setCI(maxCI)
					recentbest.Restore()
					if hasBands == true then
						band.EnableAll()
					end
					newScore = checkScore()
					save.LoadSecondaryStructure()
					if oldScore ~= newScore then
						for g = rebuildStart, rebuildEnd do
							selectSphere(g, shakeSphere)
						end
						if mutaL then
							setCI(.87)
							structure.MutateSidechainsSelected(1)
							checkBest()
						else
							if allAlanine == false then
								setCI(.2)
								structure.ShakeSidechainsSelected(1)
								checkBest()
							end
						end
						checkBest()
						setCI(maxCI)
						if hasBands == true then
							band.EnableAll()
						end
						if doWiggleSidechains then
							--selection.DeselectAll()
							--selection.SelectRange(rebuildStart, rebuildEnd)
							setCI(maxCI)
							structure.WiggleAll(10, false, true)
							checkBest()
						end
						if doLocalWiggle then
							selection.DeselectAll()
							selection.SelectRange(rebuildStart, rebuildEnd) -- TO DO: DEBUG
							structure.LocalWiggleSelected(10, true, true)
							checkBest()
						end
						recentbest.Restore()
						checkBest()
						selection.DeselectAll()
						if hasBands == true then
							band.EnableAll()
						end
						if Stitch then
							sheetStitcher()
						end
						if checkScore() > 5000 then
							setCI(maxCI)
							performWiggles("wiggleAll", 9)
							checkBest()
						else
							setCI(0.6 * maxCI)
							performWiggles("wiggleAll", 3)
							checkBest()
							setCI(maxCI)
							performWiggles("wiggleAll", 9)
							checkBest()
						end
						recentbest.Restore()
						checkBest()
						if hasBands == true then
							band.EnableAll()
						end
						setCI(maxCI / 2)
						performWiggles("wiggleAll", 3)
						checkBest()
						setCI(maxCI)
						performWiggles("wiggleAll", 9)
						checkBest()
						recentbest.Restore()
						checkBest()
						if doIdealize then
							print("Idealize...")
							selection.DeselectAll()
							doingIdealize = true
							local idS = checkScore()
							selection.SelectRange(rebuildStart, rebuildEnd)
							structure.IdealizeSelected()
							checkBest()
							qStab()
							save.LoadSecondaryStructure()
							if fzt >= 0 then
								if checkScore() > (idS - fzt) then
									if muta then
										performFuzeMutate()
									else
										performFuze()
									end
								end
							else
								if checkScore() >= (idS + FFzt) then
									if muta then
										performFuzeMutate()
									else
										performFuze()
									end
								end
							end
							doingIdealize = false
						elseif doIdealize == false then
							if qStabDo then
								qStab()
							end
						end
						if SinSq then
							localBands()
						end
						checkBest()
						if fzt >= 0 then
							if checkScore() > (oldScore - fzt) then
								if muta then
									performFuzeMutate()
								else
									performFuze()
								end
							end
						else
							if checkScore() >= (oldScore + FFzt) then
								if muta then
									performFuzeMutate()
								else
									performFuze()
								end
							end
						end
						newScore = checkScore()
						checkAlanine()
						if (oldScore - newScore) < 51 then
							setCI(maxCI / 2)
							performWiggles("shakeSidechains")
							checkBest()
							setCI(maxCI)
							performWiggles("wiggleAll", 5)
							checkBest()
							recentbest.Restore()
							checkBest()
						end
					end
					newScore = checkScore()
					if(newScore > oldScore) then
						recentbest.Restore()
						checkBest()
						save.Quicksave(99)
						save.Quicksave(8)
						print("     Gained " .. trunc(checkScore() - oldScore) .. " points this rebuild")
					else
					end
				end
				if rbldcomp == true and rebuildCounter >= 1 then
					Bander()
				end
				save.Quickload(99)
			end
		end
		if (checkScore() - cRscore) > 0 then
			print("Start Score:", trunc(startScore), "Current Score:", trunc(checkScore()))
			print("     Gained: " .. trunc((checkScore() - cRscore)) .. " points this cycle")
			noGain = false
			badCycles = 0
			consecCyclesWithoutGain = 0
			goodCycles = goodCycles + 1
			printRR = true
		else
			noGain = true
			badCycles = badCycles + 1
			consecCyclesWithoutGain = consecCyclesWithoutGain + 1
			if totalCycles > 0 then
				print("Score:", trunc(checkScore()), "No gain this cycle")
				print(consecCyclesWithoutGain .. " consecutive cycles without any gain")
				printRR = true
			else
				maxCycles = maxCycles +1
				minusR = minusR + 1
			end
		end
		if badCycles > 5 and rebuildLength == numSegments then
			rebuildLength = numSegments / 3
		end
		if bfm == true and rebuildCounter >= 1 then
			allWalk()
		end
		if cyclecomp == true and rebuildCounter >= 1 then
			Bander()
		end
		cycleCounter = cycleCounter + 1
	end
end

function performDeepRebuild()
	for cycleCounter = 1, maxCycles do -- DRW
		save.Quickload(99)
		if ciDo == true and rebuildCounter >= 1 then
			if cyGa > 0 then
				if (checkScore() - cycleScore) <= cyGa then
					if goodCycles >= ciCy then
						maxCI = (maxCI + ciCh)
					end
				end
			elseif cyGa == 0 then
				if badCycles >= ciCy then
					maxCI = (maxCI + ciCh)
				end
			end
			if maxCI > 1 then
				maxCI = 1
			elseif maxCI <= 0 then
				maxCI = 0.15
			end
			print("Max CI = " .. maxCI)
			setCI(maxCI)
			performWiggles()
			setCI(maxCI / 2)
			performWiggles()
			setCI(maxCI)
			performWiggles()
			recentbest.Restore()
			checkBest()
		end
		if cycleCounter > cyclesPerRebuildLength then
			cycleCounter = 1
			rebuildLength = rebuildLength + rebuildLengthDelta
			if rebuildLengthDelta == 0 then
				startOfNewRound = true
			end
			if rebuildLength < minRB then
				rebuildLength = maxRB
				-- reset sub-counter (used to track thorough cycles)
				startOfNewRound = true
			end
			if rebuildLength > maxRB then
				rebuildLength = minRB
				-- reset sub-counter (used to track thorough cycles)
				startOfNewRound = true
			end
		end

		if notLoops == true then
			broken = true
			checkLengths('L', rebuildLength)
		end
		if notHelices then
			broken = true
			checkLengths('H', rebuildLength)
		end
		if notSheets then
			broken = true
			checkLengths('E', rebuildLength)
		end

		checkLockLengths(rebuildLength)

		-- TO DO: options test to make sure thorough and total-only aren't both checked
		-- 				also target density/pairwise
		if doThoroughMode == true and startOfNewRound == true then
			-- determine proper subscore part to use for new round
			if subscorePart == "density" then
				subscorePart = "total"
			elseif subscorePart == "total" then
				subscorePart = "ideality"
			elseif subscorePart == "ideality" then
				subscorePart = "sidechain"
			elseif subscorePart == "sidechain" then
				subscorePart = "bonding"
			elseif subscorePart == "bonding" then
				subscorePart = "clashing"
			elseif subscorePart == "clashing" then
				subscorePart = "hiding"
			elseif subscorePart == "hiding" then
				subscorePart = "packing"
			elseif subscorePart == "packing" then
				subscorePart = "backbone"
			elseif subscorePart == "backbone" then
				if usePairwise == true then
					subscorePart = "pairwise"
				elseif useDensity == true then
					subscorePart = "density"
				else
					subscorePart = "total"
				end
			elseif subscorePart == "pairwise" then
				if useDensity == true then
					subscorePart = "density"
				else
					subscorePart = "total"
				end
			end
			startOfNewRound = false
		end

		if broken ~= true then
			totalCycles = totalCycles + 1
			cycleScore = checkScore()
			print("")
			print("Cycle: " .. totalCycles .. " / " .. maxCycles)
			print("Range: " .. startSegment .. " - " .. endSegment, "Rebuild Length: " .. rebuildLength)
			print("Starting score this cycle: " .. trunc(cycleScore))
			if gsort and totalCycles > 1 then
				if PersCnt == false then
					SortItWell(subscorePart)
					garyCnt = 0
				end
			else
				SortItWell(subscorePart)
				garyCnt = 0
			end

			if worstFirst == true then
				print("Looking for worst " .. subscorePart .. " score")
			else
				print("Looking for best " .. subscorePart .. " score")
			end

			rebuildCounter = 0
			j = 0
			Jround = 0

			while rebuildCounter < rebuildsPerCycle do

				broken = false
				j = j + 1

				if j > numSegments then
					j = 1
					Jround = Jround + 1
				end

				if Jround >= 2 then
					break
				end

				if (grid[j][2] - 1) < 0 then
					grid[j][2] = (grid[j][2] + 1)
				end

				if (grid[j][2] + 1) > numSegments + 1 then
					grid[j][2] = (grid[j][2] - 1)
				end

				rebuildSegment = grid[j][2]

				if debugOutput == true then
					print("rebuildSegment:", rebuildSegment)
				end

				if (rebuildSegment + (rebuildLength / 2)) < numSegments then
					rebuildEnd = math.floor(rebuildSegment + (rebuildLength / 2))
				else
					rebuildEnd = numSegments
				end

				if (rebuildSegment - (rebuildLength / 2)) > 1 then
					rebuildStart = math.ceil(rebuildSegment - (rebuildLength / 2))
				else
					rebuildStart = 1
				end

				if rebuildLength % 2 == 0 then
					if rebuildEnd == numSegments then
						rebuildStart = rebuildStart + 1
					else
						rebuildEnd = rebuildEnd - 1
					end
				end

				if debugOutput == true then
					print("rebuildStart:", rebuildStart)
					print("rebuildEnd:", rebuildEnd)
				end

				local selectionLength = (rebuildEnd - rebuildStart)
				if selectionLength < rebuildLength - 1 then
					if rebuildStart == 1 then
						rebuildEnd = rebuildEnd + 1
					elseif rebuildEnd == numSegments then
						rebuildStart = rebuildStart - 1
					end
				elseif selectionLength >= rebuildLength then
					if rebuildStart == 1 then
						rebuildEnd = rebuildEnd - 1
					elseif rebuildEnd == numSegments then
						rebuildStart = rebuildStart + 1
					end
				end

				if debugOutput == true then
					print("rebuildStart:", rebuildStart)
					print("rebuildEnd:", rebuildEnd)
				end

				-- duplicates of previous... not sure why
				local selectionLength = (rebuildEnd - rebuildStart)
				if selectionLength < rebuildLength - 1 then
					if rebuildStart == 1 then
						rebuildEnd = rebuildEnd + 1
					elseif rebuildEnd == numSegments then
						rebuildStart = rebuildStart - 1
					end
				elseif selectionLength >= rebuildLength then
					if rebuildStart == 1 then
						rebuildEnd = rebuildEnd - 1
					elseif rebuildEnd == numSegments then
						rebuildStart = rebuildStart + 1
					end
				end

				if debugOutput == true then
					print("rebuildStart:", rebuildStart)
					print("rebuildEnd:", rebuildEnd)
				end

				local selectionLength = (rebuildEnd - rebuildStart)
				if selectionLength < rebuildLength - 1 then
					if rebuildStart == 1 then
						rebuildEnd = rebuildEnd + 1
					elseif rebuildEnd == numSegments then
						rebuildStart = rebuildStart - 1
					end
				elseif selectionLength >= rebuildLength then
					if rebuildStart == 1 then
						rebuildEnd = rebuildEnd - 1
					elseif rebuildEnd == numSegments then
						rebuildStart = rebuildStart + 1
					end
				end

				if debugOutput == true then
					print("rebuildStart:", rebuildStart)
					print("rebuildEnd:", rebuildEnd)
				end

				for x = rebuildStart, rebuildEnd do
					if getSS(x) ~= 'L' then
						if notSheets then
							if getSS(x) == 'E' then
								broken = true
							end
						end
						if notHelices then
							if getSS(x) == 'H' then
								broken = true
							end
						end
					elseif getSS(x) == 'L' then
						if notLoops then
							broken = true
						end
					end
				end

				if broken ~= true then
					if (rebuildStart >= startSegment) and (rebuildEnd <= endSegment) and (isMovable(rebuildStart, rebuildEnd) == true) then
						broken = false
					else
						broken = true
					end
				end

				if broken ~= true then
					save.Quickload(99)
					checkAlanine()
					qscore = checkScore()
					save.LoadSecondaryStructure()
					selection.DeselectAll()
					rebuildCounter = rebuildCounter + 1
					print("Rebuild:", rebuildCounter .. " / " .. rebuildsPerCycle, "Segments:", rebuildStart .. " - " .. rebuildEnd, trunc(checkScore()), os.date("%X"))

					selection.SelectRange(rebuildStart, rebuildEnd)
					if allLoops then
						for e = 1, numSegments do
							if selection.IsSelected(e) then
								structure.SetSecondaryStructure(e, "L")
							end
						end
					else
						structure.SetSecondaryStructure(rebuildSegment, "L")
					end
					setCI(rebuildCI)
					disableBands(oldBands)
					if testSubscoreImprovement == true then
						beter = false
					elseif testSubscoreImprovement == false then
						beter = true
					end
					if subscorePart ~= 'total' then
						tempSegScore = current.GetSegmentEnergySubscore(rebuildSegment, subscorePart)
					else
						tempSegScore = current.GetSegmentEnergyScore(rebuildSegment)
					end
					if gsort then
						print("Target's score:", trunc(tempSegScore))
					end
					structure.RebuildSelected(1)
					recentbest.Save()
					save.Quicksave(97)

					for k = 1, numberOfRebuilds do
						save.Quickload(97)
						selection.SelectRange(rebuildStart, rebuildEnd)
						setCI(rebuildCI)
						structure.RebuildSelected(1)
						selection.DeselectAll()
						if hasBands == true then
							band.EnableAll()
						end
						for g = rebuildStart, rebuildEnd do
							selectSphere(g, shakeSphere)
						end
						if mutaL then
							setCI(.87)
							structure.MutateSidechainsSelected(1)
						else
							if allAlanine == false then
								setCI(.2)
								structure.ShakeSidechainsSelected(1)
							end
						end
						checkBest()
						setCI(maxCI)
						if doWiggleSidechains then
							performWiggles("wiggleSidechains", 14, 1)

						end
						if doLocalWiggle then
							selection.DeselectAll()
							selection.SelectRange(rebuildStart, rebuildEnd)
							if disableFilters then
								behavior.SetSlowFiltersDisabled(true)
							end
							structure.LocalWiggleSelected(10, true, true)
							if disableFilters then
								behavior.SetSlowFiltersDisabled(false)
							end
						end
						checkBest()
						selection.DeselectAll()
						if doGlobalWiggle == true then
							if checkScore() > 5000 then
								setCI(maxCI)
								performWiggles("wiggleAll", 9)
								checkBest()
							else
								setCI(0.6 * maxCI)
								performWiggles("wiggleAll")
								checkBest()
								setCI(maxCI)
								performWiggles("wiggleAll", 9)
								checkBest()
							end
						end
						checkBest()
					end

					recentbest.Restore()
					save.LoadSecondaryStructure()
					checkBest()
					checkAlanine()
					if hasBands == true then
						band.EnableAll()
					end
					if Stitch then
						sheetStitcher()
					end
					setCI(maxCI)
					performWiggles("wiggleAll", 10)
					checkBest()
					if trunc(checkScore()) ~= trunc(qscore) then
						performWiggles("shakeSidechains")
						checkBest()
						performWiggles()
						checkBest()
					end
					recentbest.Restore()
					checkBest()
					if hasBands == true then
						band.EnableAll()
					end
					if trunc(checkScore()) ~= trunc(qscore) then
						setCI(maxCI / 2)
						performWiggles("wiggleAll", 3)
						checkBest()
						setCI(maxCI)
						performWiggles("wiggleAll", 9)
						recentbest.Restore()
						checkBest()
					end
					if doIdealize then
						selection.DeselectAll()
						print("Idealize...")
						doingIdealize = true
						local idS = checkScore()
						selection.SelectRange(rebuildStart, rebuildEnd)
						structure.IdealizeSelected()
						selection.DeselectAll()
						performWiggles()
						checkBest()
						if beter == true then
							qStab()
							if fzt >= 0 then
								if checkScore() > (idS - fzt) then
									if muta then
										performFuzeMutate()
									else
										performFuze()
									end
								end
							else
								if checkScore() >= (idS + FFzt) then
									if muta then
										performFuzeMutate()
									else
										performFuze()
									end
								end
							end
						else
							setCI(maxCI / 3)
							performWiggles('wa', 10)
							checkBest()
							setCI(maxCI)
							performWiggles('wa', 10)
							checkBest()
						end
						doingIdealize = false
					elseif (doIdealize == false) and (beter == true) then
						if qStabDo then
							qStab()
						end
					end
					if testSubscoreImprovement == true then
						if subscorePart ~= 'total' then
							PT = current.GetSegmentEnergySubscore(rebuildSegment, subscorePart)
						else
							PT = current.GetSegmentEnergyScore(rebuildSegment)
						end
						if PT >= tempSegScore - 0.03 then
							beter = true
						else
							beter = false
						end
					end
					if fewerTests == true then
						if beter == true then
							if SinSq then
								if testSubscoreImprovement == true then
									print("Target's score:", trunc(PT))
								end
								localBands()
							end
							checkBest()
							if fzt >= 0 then
								save.LoadSecondaryStructure()
								if checkScore() > (qscore - fzt) then
									if muta then
										performFuzeMutate()
									else
										performFuze()
									end
								end
							else
								if checkScore() >= (qscore + FFzt) then
									if muta then
										performFuzeMutate()
									else
										performFuze()
									end
								end
							end
							recentbest.Restore()
							checkBest()
							if (checkScore() - qscore) > 0.01 then
								print("     Gained " .. trunc(checkScore() - qscore) .. " points this rebuild")
							end
							if rbldcomp == true and rebuildCounter >= 1 then
								Bander()
							end
						end
					else
						if SinSq then
							if testSubscoreImprovement == true then
								print("Target's score:", trunc(PT))
							end
							localBands()
						end
						checkBest()
						if fzt >= 0 then
							save.LoadSecondaryStructure()
							if checkScore() > (qscore - fzt) then
								if muta then
									performFuzeMutate()
								else
									performFuze()
								end
							end
						else
							if checkScore() >= (qscore + FFzt) then
								if muta then
									performFuzeMutate()
								else
									performFuze()
								end
							end
						end
						checkBest()
						if beter == true then
							if (checkScore() - qscore) > 0.01 then
								print("     Gained " .. trunc(checkScore() - qscore) .. " points this rebuild")
							end
						end
						if rbldcomp == true and rebuildCounter >= 1 then
							Bander()
						end
					end
					if (checkScore() - qscore) > 1 then
						garyCnt = garyCnt +1
						if gsort == true then
							if (cntGary - garyCnt) ~= 0 then
								print(cntGary - garyCnt .. " more good rebuilds before sort")
							end
						end
					end
					if gsort then
						if garyCnt >= cntGary then
							SortItWell(subscorePart)
							print("Sorted")
							garyCnt = 0
						end
					end

					if doReSort == true then
						--print("Re-sorting...")
						SortItWell(subscorePart)
					end
				end

			end

			save.Quickload(99)

			if testSubscoreImprovement == false then
				recentbest.Restore()
				checkBest()
			end

			if (checkScore() - cycleScore) > 0.1 then
				print("Start Score:", trunc(startScore), "Score:", trunc(checkScore()))
				print("     Gained: " .. trunc((checkScore() - cycleScore)) .. " points this cycle")
				noGain = false
				goodCycles = goodCycles + 1
				badCycles = 0
				consecCyclesWithoutGain = 0
			else
				noGain = true
				badCycles = badCycles + 1
				consecCyclesWithoutGain = consecCyclesWithoutGain + 1
				print("Score:", trunc(checkScore()), "No gain this cycle")
				print(consecCyclesWithoutGain .. " cycles without any gain")
			end

			if badCycles > 5 and rebuildLength == numSegments then
				rebuildLength = numSegments / 3
			end

			if doThoroughMode == false then
				if totalOnly == false then
					if badCycles > 1 then
						if subscorePart == "density" then
							subscorePart = "total"
						elseif subscorePart == "total" then
							if usePairwise == true then
								subscorePart = "pairwise"
							else
								subscorePart = "ideality"
							end
						elseif subscorePart == "pairwise" then
							subscorePart = "ideality"
						elseif subscorePart == "ideality" then
							subscorePart = "sidechain"
						elseif subscorePart == "sidechain" then
							subscorePart = "bonding"
						elseif subscorePart == "bonding" then
							subscorePart = "clashing"
						elseif subscorePart == "clashing" then
							subscorePart = "hiding"
						elseif subscorePart == "hiding" then
							subscorePart = "packing"
						elseif subscorePart == "packing" then
							subscorePart = "backbone"
						elseif subscorePart == "backbone" then
							if useDensity == true then
								subscorePart = "density"
							else
								subscorePart = "total"
							end
						end
					end
				else
					subscorePart = "total"
				end
			end
			if bfm == true and rebuildCounter >= 1 then
				allWalk()
			end
			if cyclecomp == true and rebuildCounter >= 1 then
				Bander()
			end
		end
		cycleCounter = cycleCounter + 1
	end
end

function cleanup(errmsg)
	if done then
		return
	end
	done = true
	if string.find(errmsg, "Cancelled") then
		print("User cancel")
		Result()
		print("")
	else
		Result()
		print("")
		print(errmsg)
	end
	return errmsg
end

function main()

	generateSeed()
	numSegments = structure.GetCount()
	startSegment = 1
	endSegment = numSegments
	checkMutable()
	checkDensity()
	checkPairwise()
	checkReference()

	useTotal = true
	useIdeality = true
	useSidechain = true
	useBonding = true
	useClashing = true
	useHiding = true
	usePacking = true
	useBackbone = true

	doThoroughMode = false
	doShortCycles = false
	totalOnly = false
	iterationMultiplier = 1.0
	useEnergyScore = true -- set to true to use .GetEnergyScore()

	maxCI = behavior.GetClashImportance()
	if maxCI < 0.1 then
		maxCI = 1
	end
	maxCycles = 0
	oldBands = 0
	oldBands = band.GetCount()
	originalBands = oldBands
	startScore = checkScore()
	bestScore = startScore
	banderStartScore = checkScore()
	banderBestScore = banderStartScore
	if iterationMultiplier <= 0 then
		iterationMultiplier = 1
	end

	doingBanders = false
	luktni = false
	beter = true
	if checkScore() < 8000 then
		maxLoss = 0.5
	else
		maxLoss = 1.5
	end

	checkLock()
	allAlanine = checkAlanine()

	print(scriptName, "build: " .. buildNumber)
	print("")

	if lockd > numSegments - 1 then
		print("Not enough to work with")
		print("")
		return UnfreezeSomething()
	end
	while contains(locklist, startSegment) do
		startSegment = startSegment + 1
	end
	while contains(locklist, endSegment) do
		endSegment = endSegment - 1
	end
	while contains(locklist, endSegment) do
		endSegment = endSegment - 1
	end
	while contains(locklist, startSegment) do
		startSegment = startSegment + 1
	end

	maxRPC = (numSegments - lockd)
	maxRebuildLength = (numSegments - lockd)

	repeat
		dialogPresetCode = dialogPreset()
		if dialogPresetCode == 2 then
			--dialogSubscores()
			-- TO DO: Test if none were selected, and open subscore popup again
			dialogSubscoresCode = dialogSubscores()
			if dialogSubscoresCode == 0 then
				print("No changes made to subscore selections")
			else
				print("Using the following scoreparts:")
				-- TO DO: Complete this to cover all options
				if useTotal == true then
					print(" * total")
				end
				if useDensity == true then
					print(" * density")
				end
			end
		end
		if dialogPresetCode == 3 then
			dialogCustom()
		end
	until dialogPresetCode < 2
	if dialogPresetCode == 0 then
		print("Nothing done.")
		return
	end

	if doCustom == false then
		setParameters()
	end

	print("Start Score: " .. trunc(checkScore()))
	print("Quickslot 1 = Best Score")
	print("Quickslot 2 = Starting Structure")
	print("")
	print("Shorter Cycles: " .. tostring(doShortCycles))
	print("Thorough Mode: " .. tostring(doThoroughMode))
	print("Re-Sort After Every Rebuild: " .. tostring(doReSort))
	-- redo this output
	--[[
	if useDensity == true then
		print("Target Density Subscore: " .. tostring(useDensity))
	end
	if usePairwise == true then
		print("Target Pairwise Subscore: " .. tostring(usePairwise))
	end
	if allAlanine == true then
		print("No sidechains: no shaking, still mutating if checked")
	end
	]]--
	optionsTest()
	setCI(maxCI)
	checkBander()
	save.SaveSecondaryStructure()

	AAs = {"a", "c", "d", "e", "f", "g", "h", "i", "k", "l", "m", "n", "p", "q", "r", "s", "t", "v", "w", "y"}
	recentbest.Save()
	save.Quicksave(99)
	save.Quicksave(8)
	save.Quicksave(2)
	save.Quicksave(1)
	if disableFilters then
		behavior.SetSlowFiltersDisabled(false)
	end
	startScore = checkScore()
	bestScore = startScore
	tempSegScore = (-1 * seed)

	noGain = false
	badCycles = 0
	goodCycles = 0
	consecCyclesWithoutGain = 0
	rebuildCounter = 0
	totalCycles = 0
	cycleCounter = 1
	startOfNewRound = false -- initially false, triggered at start of NEXT round
	minusR = 0
	printRR = true

	if doBandersFirst == true then
		Bander()
	end

	if doRainbowRebuild == true then
		performRainbowRebuild()
	else
		performDeepRebuild()
	end
	Result()
end

xpcall(main, cleanup)
