scriptName = "MicroIdealize"
scriptVersion = 5.0
buildNumber = 5

saveSlot = 11
bestScore = 0
fragmentLength = 6
startFragmentLength = 6
endFragmentLength = 3
minResidue = 1
maxResidue = 999
doWorstFirst = true
doIdealizeSS = true
doIdealizeBoth = true
doLocalWiggle = false
localWiggleSpacer = 3
scoreType = 1
wiggleIterations = 12
sphereSegments = {}
sphereSegmentsRadius = 10

function trunc(x)
	return math.floor(x * 1000) / 1000
end

function round3(x)
	return x - x % 0.001
end

function getScore()
	if scoreType == 1 then
		score = current.GetEnergyScore()
	end
	return score
end

function sphereSegmentsSelect(indexStart, indexEnd)
	for i = 1, numResidues do
		sphereSegments[i] = false
	end
	for i = 1, numResidues do
		for j = indexStart, indexEnd do
			if structure.GetDistance(i, j) < sphereSegmentsRadius then
				sphereSegments[i] = true
			end
		end
	end
	selection.DeselectAll()
	for i = 1, numResidues do
		if sphereSegments[i] == true then
			selection.Select(i)
		end
	end
end

function goSegment(indexStart, indexEnd)
	save.Quickload(saveSlot)
	if indexStart > 1 then
		structure.InsertCut(indexStart)
	end
	if indexEnd < numResidues then
		structure.InsertCut(indexEnd)
	end
	selection.DeselectAll()
	selection.SelectRange(indexStart, indexEnd)
	if doIdealizeSS == false then
		structure.IdealizeSelected()
	else
		structure.IdealSSSelected()
	end
	if indexStart > 1 then
		structure.DeleteCut(indexStart)
	end
	if indexEnd < numResidues then
		structure.DeleteCut(indexEnd)
	end

	if doLocalWiggle == false then
		sphereSegmentsSelect(indexStart, indexEnd)
		structure.WiggleSelected(wiggleIterations)
	else
		selection.DeselectAll()
		selection.SelectRange(math.max(1, indexStart - localWiggleSpacer), math.min(indexEnd + localWiggleSpacer, numResidues))
		structure.WiggleSelected(wiggleIterations)
	end

	score = getScore()
	local gain = score - bestScore
	if gain > 0 then
		bestScore = score
		print("Gained: " .. string.format("%.3f", gain), "Score: " .. string.format("%.3f", bestScore))
		save.Quicksave(saveSlot)
		--if score > bestScore then
		--bestScore = score
		--print("Improvement to " .. string.format("%.3f", bestScore))
		--save.Quicksave(saveSlot)
	end
end

function coPrime(n)
	local primes = {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101}
	i = #primes   -- find the highest prime < 70% of the residue count and which is coprime with the number of residues
	while i >= 1 do
		if (primes[i] < n * 0.7) and (n % primes[i] ~= 0) then
			return primes[i]
		end
		i = i - 1
	end
	return 1
end

function pseudoRandom(score)
	-- Returns a pseudoRandom number >= 0 and < 1.
	-- Based on the fractional part of the  score
	if score >= 0 then
		return score % 1
	else
		return (-score) % 1
	end
end

function Go()
	local inc
	maxFragStart = maxResidue - fragmentLength + 1
	numFragments = maxFragStart - minResidue + 1
	r = pseudoRandom(bestScore)

	indexStart = minResidue + numFragments * r
	indexStart = indexStart - indexStart % 1
	inc = coPrime(numFragments)

	for i = 1, numFragments do
		print(indexStart .. "-" .. indexStart + fragmentLength - 1 .. " (" .. i .. "/" .. numFragments .. ")")
		goSegment(indexStart, indexStart + fragmentLength - 1)
		indexStart = indexStart + inc
		if indexStart > maxFragStart then
			indexStart = indexStart - numFragments
		end
	end
end

function shellSort(ids, sequenceScores, n)
	local inc = 1
	repeat
		inc = inc * 3 + 1
	until inc > n
	repeat
		inc = inc / 3
		inc = inc - inc % 1
		for i = inc + 1, n do
			v = sequenceScores[i]
			w = ids[i]
			j = i
			flag = false
			while (flag == false) and (sequenceScores[j - inc] > v) do
				sequenceScores[j] = sequenceScores[j - inc]
				ids[j] = ids[j - inc]
				j = j - inc
				if j <= inc then
					flag = true
				end
			end
			sequenceScores[j] = v
			ids[j] = w
		end
	until inc <= 1
end

function goWorstFirst()
	idealityScores = {}
	sequenceScores = {}
	ids = {}
	maxFragStart = maxResidue - fragmentLength + 1
	numFragments = maxFragStart - minResidue + 1

	for i = minResidue, maxResidue do
		idealityScores[i] = current.GetSegmentEnergySubscore(i, "ideality")
	end

	idx = 1

	for i = minResidue, maxResidue - fragmentLength + 1 do
		total = 0
		for j = i, i + fragmentLength - 1 do
			total = total + idealityScores[j]
		end
		sequenceScores[idx] = total
		ids[idx] = i
		idx = idx + 1
	end

	shellSort(ids, sequenceScores, maxFragStart - minResidue + 1)

	for i = 1, numFragments do
		local j = ids[i] + fragmentLength - 1
		print("Fragment:", string.format("%03i", i) .. "/" .. string.format("%03i", numFragments), "Segments:", string.format("%03i", ids[i]) .. " - " .. string.format("%03i", j))
		--print(ids[i] .. "-" ..  ids[i] + fragmentLength - 1 .. " (" .. i .. "/" .. numFragments .. ")")
		goSegment(ids[i], ids[i] + fragmentLength - 1)
	end
end

function getParameters()
	local dlog = dialog.CreateDialog(scriptName)
	dlog.startFragmentLength = dialog.AddSlider("Starting Idealize length:", startFragmentLength, 1, 20, 0)
	dlog.endFragmentLength = dialog.AddSlider("Ending Idealize length:", endFragmentLength, 1, 20, 0)
	--dlog.fragmentLength = dialog.AddSlider("Idealize length", fragmentLength, 1, 20, 0)
	dlog.minResidue = dialog.AddSlider("Min residue:", minResidue, 1, numResidues, 0)
	dlog.maxResidue = dialog.AddSlider("Max residue:", maxResidue, 1, numResidues, 0)
	dlog.doIdealizeSS = dialog.AddCheckbox("Use IdealizeSS", doIdealizeSS)
	dlog.doIdealizeBoth = dialog.AddCheckbox("Use both Idealize methods", doIdealizeBoth)
	dlog.doWorstFirst = dialog.AddCheckbox("Worst first", doWorstFirst)
	dlog.doLocalWiggle = dialog.AddCheckbox("Local Wiggle", doLocalWiggle)
	dlog.localWiggleSpacer = dialog.AddSlider("Local wiggle spacer", localWiggleSpacer, 0, 10, 0)
	dlog.ok = dialog.AddButton("OK", 1)
	dlog.cancel = dialog.AddButton("Cancel", 0)

	if dialog.Show(dlog) > 0 then
		startFragmentLength = dlog.startFragmentLength.value
		endFragmentLength = dlog.endFragmentLength.value
		--fragmentLength = dlog.fragmentLength.value
		minResidue = dlog.minResidue.value
		maxResidue = dlog.maxResidue.value
		doIdealizeSS = dlog.doIdealizeSS.value
		doIdealizeBoth = dlog.doIdealizeBoth.value
		doWorstFirst  = dlog.doWorstFirst.value
		localWiggleSpacer = dlog.localWiggleSpacer.value
		doLocalWiggle = dlog.doLocalWiggle.value
		return true
	else
		return false
	end
end

function main()
	print(scriptName, "Build:", buildNumber)
	save.Quicksave(saveSlot)
	bestScore = getScore()
	print("Start Score: ", string.format("%.3f", bestScore))
	numResidues = structure.GetCount()
	minResidue = 1
	while (structure.IsLocked(minResidue) == true) and (minResidue <= numResidues) do
		minResidue = minResidue + 1
	end
	maxResidue = numResidues
	while (structure.IsLocked(maxResidue) == true) and (maxResidue >= 1) do
		maxResidue = maxResidue - 1
	end

	if getParameters() == false then
		return
	end

	if scoreType == 2 then
		behavior.SetSlowFiltersDisabled(true)
	end

	--print("Idealize Range: " .. minResidue .. " to " .. maxResidue)
	--print("Length: " .. fragmentLength)
	--print("Idealize SS: " .. tostring(doIdealizeSS))
	print("Idealize Range: " .. string.format("%03i", minResidue) .. " to " .. string.format("%03i", maxResidue))

	for i = startFragmentLength, endFragmentLength, -1 do
		doWorstFirst = true
		-- test: force WorstFirst always, IdealizeSS first, then repeat without
		print("")
		print("Fragment Range: " .. startFragmentLength .. " to " .. endFragmentLength)
		print("Worst First:", tostring(doWorstFirst))
		print("")
		fragmentLength = i
		print("Current Fragment Length:", fragmentLength)
		doIdealizeSS = true
		print("Idealize SS:", tostring(doIdealizeSS))
		goWorstFirst()
		doIdealizeSS = false
		print("")
		print("Idealize SS:", tostring(doIdealizeSS))
		goWorstFirst()
		--if doWorstFirst == false then
			--Go()
		--else
			--goWorstFirst()
		--end
	end
	cleanup()
end

function cleanup()
	print("Cleaning up...")
	behavior.SetClashImportance(1.0)
	save.Quickload(saveSlot)
end

xpcall (main, cleanup)
