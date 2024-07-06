scriptName = "Enhanced Walking Rebuild"
scriptVersion = 1.0
buildNumber = 2

-- NOT USED
function roundDown(x)
	--return x - x % 1
	return math.floor(x)
end

-- [NOTE] Why is it done this way?
function setCI(currentCI)
	if currentCI > 0.99 then
		maxCI = true
	else
		maxCI = false
	end
	behavior.SetClashImportance(currentCI * CIfactor)
end

function checkCI()
	local ask = dialog.CreateDialog("Clash importance is not 1")
	ask.l1 = dialog.AddLabel("Last change to change it")
	ask.l2 = dialog.AddLabel("CI settings will be multiplied by set CI")
	ask.continue = dialog.AddButton("Continue", 1)
	dialog.Show(ask)
end

function getScore(pose)
	if pose == nil then
		pose = current
	end
	local total
	if disableFilters == true then
		total = pose.GetEnergyScore()
	else
		total = pose.GetScore()
	end
	-- FIX for big negatives
	if normal then
		return total
	else
		return total * pose.GetExplorationMultiplier()
	end
end

-- NOT USED
function segmentScore(pose)
	if pose == nil then
		pose = current
	end
	local total = 8000
	for i = 1, segCount do
		total = total + pose.GetSegmentEnergyScore(i)
	end
	return total
end

-- NOT USED
function scoreRecentBest()
	return getScore(recentbest)
end

function round3(x)
		return x - x % 0.001
end

-- NOT USED
function saveBest()
	local interimGain = getScore() - bestScore
	if interimGain > 0 then
		if interimGain > 0.001 then
			print("Gained another " .. round3(interimGain) .. " points")
		end
		bestScore = getScore()
		save.Quicksave(3)
	end
end

-- Optimized due to Susumes ideas
-- Note the extra parameter to be used if only selected parts must be done
-- NOT USED
function doWiggle(how, iters, minPPI, onlySelected)
	-- Fixed a bug () absolute difference is the threshold now)
	if how == nil then
		how = "wa"
	end
	if iters == nil then
		iters = 3
	end
	if minPPI == nil then
		minPPI = 0.1
	end
	if onlySelected == nil then
		onlySelected = false
	end

	local wiggleFactor = 1
	-- [NOTE] This is redundant
	if maxCI then
		wiggleFactor = 1
	end
	if onlySelected then
		if how == "s" then
			-- Shake is not considered to do much in second or more rounds
			structure.ShakeSidechainsSelected(1)
			return
		elseif how == "wb" then
			structure.WiggleSelected(2 * wiggleFactor * iters, true, false)
		elseif how == "ws" then
			structure.WiggleSelected(2 * wiggleFactor * iters, false, true)
		elseif how == "wa" then
			structure.WiggleSelected(2 * wiggleFactor * iters, true, true)
		end
	else
		structure.DeselectAll()
		if how == "s" then
			-- Shake is not considered to do much in second or more rounds
			structure.ShakeSidechainsAll(1)
			return
		elseif how == "wb" then
			structure.WiggleAll(2 * wiggleFactor * iters, true, false)
		elseif how == "ws" then
			structure.WiggleAll(2 * wiggleFactor * iters, false, true)
		elseif how == "wa" then
			structure.WiggleAll(2 * wiggleFactor * iters, true, true)
		end
	end
end

-- Notice that most functions assume that the sets are well formed (ordered and no overlaps)
function segmentListToSet(list)
	local result = {}
	local first = 0
	local last = -1
	table.sort(list)
	for i = 1, #list do
		if list[i] ~= last + 1 and list[i] ~= last then
			-- note: duplicates are removed
			if last > 0 then
				result[#result + 1] = {first, last}
			end
			first = list[i]
		end
		last = list[i]
	end
	if last > 0 then
		result[#result + 1] = {first, last}
	end
	return result
end

function segmentSetToList(set)
	local result = {}
	for i = 1, #set do
		for k = set[i][1], set[i][2] do
			result[#result + 1] = k
		end
	end
	return result
end

function segmentCleanSet(set)
-- Makes it well formed
	return segmentListToSet(segmentSetToList(set))
end

function segmentInvertSet(set, maxSeg)
	-- Gives back all segments not in the set
	-- maxSeg is added for ligand
	local result = {}
	if maxSeg == nil then
		maxSeg = structure.GetCount()
	end
	if #set == 0 then
		return {{1, maxSeg}}
	end
	if set[1][1] ~= 1 then
		result[1] = {1, set[1][1] - 1}
	end
	for i = 2, #set do
		result[#result + 1] = {set[i - 1][2] + 1, set[i][1] - 1}
	end
	if set[#set][2] ~= maxSeg then
		result[#result + 1] = {set[#set][2] + 1, maxSeg}
	end
	return result
end

-- NOT USED
function segmentInvertList(list)
	table.sort(list)
	local result = {}
	for i = 1, #list - 1 do
		for j = list[i] + 1, list[i + 1] - 1 do
			result[#result + 1] = j
		end
	end
	for j = list[#list] + 1, segCount do
		result[#result + 1] = j
	end
	return result
end

-- NOT USED
function isSegmentInList(s, list)
	table.sort(list)
	for i = 1, #list do
		if list[i] == s then
			return true
		elseif list[i] > s then
			return false
		end
	end
	return false
end

function isSegmentInSet(set, s)
	for i = 1, #set do
		if s >= set[i][1] and s <= set[i][2] then
			return true
		elseif s < set[i][1] then
			return false
		end
	end
	return false
end

function segmentJoinList(list1, list2)
	local result = list1
	if result == nil then
		return list2
	end
	for i = 1, #list2 do
		result[#result + 1] = list2[i]
	end
	table.sort(result)
	return result
end

-- NOT USED
function segmentJoinSet(set1, set2)
	return segmentListToSet(segmentJoinList(segmentSetToList(set1), segmentSetToList(set2)))
end

function segmentCommList(list1, list2)
	local result = {}
	table.sort(list1)
	table.sort(list2)
	if #list2 == 0 then return
		result
	end
	local j = 1
	for i = 1, #list1 do
		while list2[j] < list1[i] do
			j= j + 1
			if j > #list2 then
				return result
			end
		end
		if list1[i] == list2[j] then
			result[#result + 1] = list1[i]
		end
	end
	return result
end

function segmentCommSet(set1, set2)
	return segmentListToSet(segmentCommList(segmentSetToList(set1), segmentSetToList(set2)))
end

function segmentSetMinus(set1, set2)
	return segmentCommSet(set1, segmentInvertSet(set2))
end

-- NOT USED
function segmentPrintSet(set)
	print(segmentSetToString(set))
end

function segmentSetToString(set)
	local line = ""
	for i = 1, #set do
		if i ~= 1 then
			line = line .. ", "
		end
	line = line .. set[i][1] .. "-" .. set[i][2]
	end
	return line
end

-- NOT USED
function segmentSetInSet(set, sub)
	if sub == nil then
		return true
	end
	-- Checks if sub is a proper subset of set
	for i = 1, #sub do
		if not segmentRangeInSet(set, sub[i]) then
			return false
		end
	end
	return true
end

function segmentRangeInSet(set, range)
	if range == nil or #range == 0 then
		return true
	end
	local rangeBeginning = range[1]
	local rangeEnd = range[2]
	for i = 1, #set do
		if rangeBeginning >= set[i][1] and rangeBeginning <= set[i][2] then
			return (rangeEnd <= set[i][2])
		elseif rangeEnd <= set[i][1] then
			return false
		end
	end
	return false
end

-- NOT USED
function segmentSetToBool(set)
	local result = {}
	for i = 1, structure.GetCount() do
		result[i] = isSegmentInSet(set, i)
	end
	return result
end

function findMutablesList()
	local result = {}
	for i = 1, segCount do
		if structure.IsMutable(i) then
			result[#result + 1] = i
		end
	end
	return result
end

function findMutables()
	return segmentListToSet(findMutablesList())
end

function findFrozenList()
	local result = {}
	for i = 1, segCount do
		if freeze.IsFrozen(i) then
			result[#result + 1] = i
		end
	end
	return result
end

function findFrozen()
	return segmentListToSet(findFrozenList())
end

function findLockedList()
	local result = {}
	for i = 1, segCount do
		if structure.IsLocked(i) then
			result[#result + 1] = i
		end
	end
	return result
end

function findLocked()
	return segmentListToSet(findLockedList())
end

function findSelectedList()
	local result = {}
	for i = 1, segCount do
		if selection.IsSelected(i) then
			result[#result + 1] = i
		end
	end
	return result
end

function findSelected()
	return segmentListToSet(findSelectedList())
end

function findAminoAcidTypeList(aa)
	local result = {}
	for i = 1, segCount do
		if structure.GetSecondaryStructure(i) == aa then
			result[#result + 1] = i
		end
	end
	return result
end

function findAminoAcidType(aa)
	return segmentListToSet(findAminoAcidTypeList(aa))
end

-- NOT USED
function findAminoType(at) --NOTE: only this one gives a list not a set
	local result = {}
	for i = 1, segCount do
		if structure.GetAminoAcid(i) == at then
			result[#result + 1] = i
		end
	end
	return result
end

function setSelection(set)
	selection.DeselectAll()
	if set ~= nil then
		for i = 1, #set do
			selection.SelectRange(set[i][1], set[i][2])
		end
	end
end

function selectAround(segStart, segEnd, radius, nodeselect)
	if nodeselect~=true then
		selection.DeselectAll()
	end
	for i = 1, segCount do
		for x = segStart, segEnd do
			if structure.GetDistance(x, i) < radius then
				selection.Select(i)
				break
			end
		end
	end
end

-- NOT USED
function setAminoAcidType(set, aa)
	local saveselected = findSelected()
	setSelection(set)
	structure.SetSecondaryStructureSelected(aa)
	setSelection(saveselected)
end

function allLoops()
	local anychange = false
	for i = 1, segCount do
		if structure.GetSecondaryStructure(i) ~= "L" then
			anychange = true
			break
		end
	end
	if anychange then
		save.SaveSecondaryStructure()
		saveStructures = true
		selection.SelectAll()
		structure.SetSecondaryStructureSelected("L")
	end
end

function seedRandom()
	math.randomSeed(randomSeed)
	math.random(100) -- Because the first is not random
end

function shuffleTable(tab)
	for i = 1, #tab do
		local r = math.random(cnt) -- Not very convincing: it gives always the same number on same puzzle
		tab[i], tab[r] = tab[r], tab[i]
	end
	return tab
end

function mixInwardTable(tab) -- 1234567 = 7254361 [WARNING] If done twice, it returns to the original table
	local cnt = #tab
	local mid = down(cnt / 2)
	local adjust = 1
	local result = {}
	local isPair = true
	if mid < cnt / 2 then
		adjust = 0
	end
	for i = 1, mid - adjust do
		isPair = not isPair
		if isPair then
			result[i], result[cnt + 1 - i] = tab[i], tab[cnt + 1 - i] -- Pair segments are kept untouched
		else
			result[i], result[cnt + 1 - i] = tab[cnt + 1 - i], tab[i] -- Impair segments are shifted (loop starts with last seg)
		end
	end
	return result
end

function inwardTable(tab) -- 1234567 = 7162534 [WARNING] If done twice, it mixes everything like a feuillete bakery
	local cnt = #tab
	local cntup = 1
	local result = {}
	local isPair = true
	for i = 1, #tab do
		isPair = not isPair
		if isPair then
			result[i] = tab[cntup] -- Pair segments are taken from bottom
			cntup = cntup + 1
		else
			result[i] = tab[cnt] -- Impairs segments are taken from end (loop starts with last seg)
			cnt = cnt - 1
		end
	end
	return result
end

function reverseList(tab) -- 1234567 = 7654321
	local cnt = #tab
	local result = {}
	for i = 1, #tab do
		result[i] = tab[cnt + 1 - i]
	end
	return result
end

function outwardTable(tab) -- 1234567 = 4352617
	local result = {}
	result = reverseList(inwardTable(tab))
	return result
end

function askForSelections(title, mode)
	local result = {{1, structure.GetCount()}}
	if mode == nil then
		mode = {}
	end
	if mode.askLoops == nil then
		mode.askLoops = true
	end
	if mode.askSheets == nil then
		mode.askSheets = true
	end
	if mode.askHelices == nil then
		mode.askHelices = true
	end
	if mode.askLigands == nil then
		mode.askLigands = false
	end
	if mode.askSelected == nil then
		mode.askSelected = true
	end
	if mode.askUnselected == nil then
		mode.askUnselected = true
	end
	if mode.askMutatableOnly == nil then
		mode.askMutatableOnly = true
	end
	if mode.askIgnoreLocks == nil then
		mode.askIgnoreLocks = true
	end
	if mode.askIgnoreFrozen == nil then
		mode.askIgnoreFrozen = true
	end
	if mode.askRanges == nil then
		mode.askRanges = true
	end
	if mode.doLoops == nil then
		mode.doLoops = true
	end
	if mode.doSheets == nil then
		mode.doSheets = true
	end
	if mode.doHelices == nil then
		mode.doHelices = true
	end
	if mode.doLigands == nil then
		mode.doLigands = false
	end
	if mode.doSelected == nil then
		mode.doSelected = false
	end
	if mode.doUnselected == nil then
		mode.doUnselected = false
	end
	if mode.doMutableOnly == nil then
		mode.doMutableOnly = false
	end
	if mode.doIgnoreLocks == nil then
		mode.doIgnoreLocks = false
	end
	if mode.doIgnoreFrozen == nil then
		mode.doIgnoreFrozen = false
	end

	local errFound = false

	repeat
		local ask = dialog.CreateDialog(title)
		if errFound then
			ask.E1 = dialog.AddLabel("Try again, ERRORS found, check output box")
			result = {{1, structure.GetCount()}} --reset start
			errFound = false
		end

		if mode.askLoops then
			ask.loops = dialog.AddCheckbox("Work on loops", mode.doLoops)
		elseif not mode.doLoops then
			ask.noLoops = dialog.AddLabel("Loops will be auto excluded")
		end

		if mode.askHelices then
				ask.helixes = dialog.AddCheckbox("Work on helixes", mode.doHelices)
		elseif not mode.doHelices then
				ask.noHelices = dialog.AddLabel("Helixes will be auto excluded")
		end

		if mode.askSheets then
				ask.sheets = dialog.AddCheckbox("Work on sheets", mode.doSheets)
		elseif not mode.doSheets then
				ask.noSheets = dialog.AddLabel("Sheets will be auto excluded")
		end

		if mode.askLigands then
				ask.ligands = dialog.AddCheckbox("Work on ligands", mode.doLigands)
		elseif not mode.doLigands then
				ask.noLigands = dialog.AddLabel("Ligands will be auto excluded")
		end

		if mode.askSelected then
			ask.selected = dialog.AddCheckbox("Work only on selected", mode.doSelected)
		end
		if mode.askUnselected then
			ask.unselected = dialog.AddCheckbox("Work only on nonselected", mode.doUnselected)
		end
		if mode.askMutatableOnly then
			ask.mutableOnly = dialog.AddCheckbox("Work only on mutateonly", mode.doMutableOnly)
		end
		if mode.askIgnoreLocks then
			ask.ignoreLocks = dialog.AddCheckbox("Dont work on locked ones", true)
		elseif mode.doIgnoreLocks then
			ask.noLocks = dialog.AddLabel("Locked ones will be auto excluded")
		end
		if mode.askIgnoreFrozen then
			ask.ignoreFrozen = dialog.AddCheckbox("Dont work on frozen", true)
		elseif mode.doIgnoreFrozen then
			ask.noFrozen = dialog.AddLabel("Frozen ones will be auto excluded")
		end
		if mode.askRanges then
			ask.R1 = dialog.AddLabel("Or put in segmentranges. Above selections also count")
			ask.ranges = dialog.AddTextbox("Ranges", "")
		end

		ask.OK = dialog.AddButton("OK", 1)
		ask.Cancel = dialog.AddButton("Cancel",0)

		if dialog.Show(ask) > 0 then
			-- We start with all the segments including ligands
			if mode.askLoops then
				mode.doLoops = ask.loops.value
			end
			if not mode.doLoops then
				result = segmentSetMinus(result, findAminoAcidType("L"))
			end
			if mode.askSheets then
				mode.doSheets = ask.sheets.value
			end
			if not mode.doSheets then
				result = segmentSetMinus(result, findAminoAcidType("E"))
			end
			if mode.askHelices then
				mode.doHelices = ask.helixes.value
			end
			if not mode.doHelices then
				result = segmentSetMinus(result, findAminoAcidType("H"))
			end
			if mode.askLigands then
				mode.doLigands = ask.ligands.value
			end
			if not mode.doLigands then
				result = segmentSetMinus(result, findAminoAcidType("M"))
			end
			if mode.askIgnoreLocks then
				mode.doIgnoreLocks = ask.ignoreLocks.value
			end
			if mode.doIgnoreLocks then
				result = segmentSetMinus(result, findLocked())
			end
			if mode.askIgnoreFrozen then
				mode.doIgnoreFrozen = ask.ignoreFrozen.value
			end
			if mode.doIgnoreFrozen then
				result = segmentSetMinus(result, findFrozen())
			end
			if mode.askSelected then
				mode.doSelected = ask.selected.value
			end
			if mode.doSelected then
				result = segmentCommSet(result, findSelected())
			end
			if mode.askUnselected then
				mode.doUnselected = ask.nonselected.value
			end
			if mode.doUnselected then
				result = segmentCommSet(result, segmentInvertSet(findSelected()))
			end
			if mode.askRanges and ask.ranges.value ~= "" then
				local rangeText = ask.ranges.value
				local function checkNums(nums)
				-- Now checking
					if #nums % 2 ~= 0 then
						print("Not an even number of segments found")
						return false
					end
					for i =1, #nums do
						if nums[i] == 0 or nums[i] > structure.GetCount() then
							print("Number " .. nums[i] .. " is not a segment")
							return false
						end
					end
					return true
				end

				local function readSegmentSet(data)
					local nums = {}
					local noNegatives = '%d+'
					local result = {}
					for v in string.gfind(data, noNegatives) do
						table.insert(nums, tonumber(v))
					end
					if checkNums(nums) then
						for i = 1, #nums / 2 do
							result[i] = {nums[2 * i - 1], nums[2 * i]}
						end
						result = segmentCleanSet(result)
					else
						errFound = true
						result = {}
					end
					return result
				end
				local rangeList = readSegmentSet(rangeText)
				if not errFound then
					result = segmentCommSet(result, rangeList)
				end
			end
		end
	until not errFound
	return result
end

function Gibaj(jak, iters, minPPI) -- Score-conditioned recursive wiggle/shake
 if jak == nil then
	jak = "wa"
 end
 if iters == nil then
	iters = 6
 end
 if minPPI == nil then
	minPPI = 0.04
 end
 if iters > 0 then
	iters = iters - 1
	local startScore = getScore()
	if jak == "s" then
		structure.ShakeSidechainsSelected(1)
	elseif jak == "wb" then
		selection.DeselectAll()
		structure.WiggleAll(1, true, false)
	elseif jak == "ws" then
		selection.DeselectAll()
		structure.WiggleAll(1, false, true)
	elseif jak == "wa" then
		selection.DeselectAll()
		structure.WiggleAll(1, true, true)
	end
	local endScore = getScore()
	local interimGain = endScore - startScore
	if interimGain > minPPI then Gibaj(jak, iters, minPPI) end
 end
end

function blueFuze(locally)
	recentbest.Save()
	if locally ~= true then
		selection.SelectAll()
	end
	setCI(.05)
	structure.ShakeSidechainsSelected(1)
	setCI(1)
	Gibaj()
	setCI(.07)
	structure.ShakeSidechainsSelected(1)
	setCI(1)
	Gibaj()
	recentbest.Restore()
	setCI(.3)
	selection.DeselectAll()
	structure.WiggleAll(1, true, true)
	setCI(1)
	Gibaj()
	recentbest.Restore()
end

function localWiggleShake(minGain) -- Score-conditioned local wiggle,
	setCI(1)
	if minGain == nil then
		minGain = 1
	end
	repeat
		local scoreStart = getScore()
		structure.LocalWiggleSelected(2, true, true)
		local scoreEnd = getScore()
		local wiggleGain = scoreEnd - scoreStart
		if wiggleGain < 0 then
			recentbest.Restore()
		end
	until wiggleGain < minGain
end

function postRebuild(doLocalWiggleShake, doBlueFuze, locally)
	if doLocalWiggleShake == nil then
		doLocalWiggleShake = true
	end
	if doBlueFuze == nil then
		doBlueFuze = true
	end
	recentbest.Save()
	setCI(1)
	Gibaj("s", 1)
	Gibaj("ws", 1)
	Gibaj("s", 1)
	Gibaj("ws", 1)
	if doLocalWiggleShake then
		localWiggleShake(2)
	end
	if doBlueFuze then
		blueFuze(locally)
	end
	selection.SelectAll()
	Gibaj()
end

function rebuildSegments(maxRebuildIterations) -- Local rebuild until any change
	if maxRebuildIterations == nil then
		maxRebuildIterations = 5
	end
	local rebuildScore = -10000
	local startScore = getScore()
	save.Quicksave(9)
	for j = 1, numRebuilds do
		local i = 0
		repeat
			local tempScore = getScore()
			i = i + 1
			if i > maxRebuildIterations then
				break
			end
			structure.RebuildSelected(i)
		until getScore() ~= tempScore
		if getScore() > rebuildScore then
			save.Quicksave(9)
			rebuildScore = getScore()
		end
	end
	save.Quickload(9)
	if getScore() == startScore then
		return false
	else
		return true
	end
end

function localRebuild(segStart, segEnd, maxRebuildIterations, sphereSize, doLocalWiggleShake, doBlueFuze)
	if segStart > segEnd then
		segStart, segEnd = segEnd, segStart
	end
	if segStart ~= segEnd then
		print("Working on segments " .. segStart .. "-" .. segEnd .. " from " .. round3(getScore()))
	else
		print("Working on segment " .. segStart .. " from " .. round3(getScore()))
	end
	selection.DeselectAll()
	selection.SelectRange(segStart, segEnd)
	local tempScore = getScore()
	local ok = rebuildSegments(maxRebuildIterations)
	if ok then
		selectAround(segStart, segEnd, sphereSize, true)
		postRebuild(doLocalWiggleShake, doBlueFuze, true)
	end
	local interimGain = getScore() - tempScore
	if interimGain > 0 then
		save.Quicksave(3)
		print("Rebuild accepted! Gain: ", interimGain)
	elseif interimGain < 0 then
		save.Quickload(3)
	else
		print("Unable to rebuild.")
	end
end

function rebuildList(worklist, len, maxRebuildIterations, sphereSize, doLocalWiggleShake, doBlueFuze)
	for i = 1, #worklist do
		if worklist[i] == nil then
			break
		end -- DEBUG
		local s1 = worklist[i]
		if s1 + len - 1 <= segCount then
			localRebuild(s1, s1 + len - 1, maxRebuildIterations, sphereSize, doLocalWiggleShake, doBlueFuze)
		end
	end
end

function startWalkingRebuild(worklist, startLength, endLength, maxRebuildIterations, sphereSize, doLocalWiggleShake, doBlueFuze)
	local startScore = getScore()
	print("Walking Rebuild started. Score: ", round3(startScore))
	freeze.UnfreezeAll()
	selection.DeselectAll()
	recentbest.Save()
	save.Quicksave(3)
	local stepLength = 1
	if startLength > endLength then
		stepLength = -1
	end
	for i = startLength, endLength, stepLength do
		print("\nTrying rebuilds of length: " .. i)
		rebuildList(worklist, i, maxRebuildIterations, sphereSize, doLocalWiggleShake, doBlueFuze)
	end
	print("Total rebuild interimGain: ", round3(getScore() - startScore))
	cleanup("Finishing")
end

function AskWalking()
	seedRandom()
	local ask = dialog.CreateDialog(scriptName .. " build " .. buildNumber)
	ask.l0 = dialog.AddLabel("From length can be higher then To length")
	ask.startLength = dialog.AddSlider("From length:", startLength, 1, segCount, 0)
	ask.endLength = dialog.AddSlider("To length:", endLength, 1, segCount, 0)
	ask.l1 = dialog.AddLabel("Pick the best rebuild of")
	ask.numRebuilds = dialog.AddSlider("Number of RBs:", numRebuilds, 1, 10, 0)
	ask.maxRebuildIterations = dialog.AddSlider("Max Iterations:", maxRebuildIterations, 1, 10, 0)
	ask.selSeg = dialog.AddCheckbox("Select where to work on", false)
	ask.backward = dialog.AddCheckbox("Backward walk", false)
	ask.random = dialog.AddCheckbox("Random walk", false)
	ask.inward = dialog.AddCheckbox("Inward walk", false)
	ask.outward = dialog.AddCheckbox("Outward walk", false)
	ask.sliceward = dialog.AddCheckbox("Sliceward walk", false)

	ask.allLoops = dialog.AddCheckbox("All loops", false)
	ask.sphereSize = dialog.AddSlider("Sphere size:", sphereSize, 3, 15, 0)
	ask.doLocalWiggleShake = dialog.AddCheckbox("Do local wiggles:", doLocalWiggleShake)
	ask.doBlueFuze = dialog.AddCheckbox("Use Blue Fuze:", doBlueFuze)
	ask.OK = dialog.AddButton("OK" ,1)
	ask.Cancel = dialog.AddButton("Cancel", 0)

	if dialog.Show(ask) > 0 then
		startLength = ask.startLength.value
		endLength = ask.endLength.value
		local worklist = {{1, segCount}} -- List of segments to work on
		if ask.selSeg.value then
			worklist=segmentSetToList(askForSelections(scriptName))
		else
			worklist = segmentSetToList(worklist)
		end
		if ask.backward.value then
			local blist = {}
			for i = 1, #worklist do
				blist[i] = worklist[#worklist + 1 - i]
			end
			worklist = blist
		end
		if ask.random.value then
			worklist = shuffleTable(worklist)
		end
		if ask.inward.value then
			worklist = inwardTable(worklist)
		end
		if ask.outward.value then
			worklist = outwardTable(worklist)
		end
		if ask.sliceward.value then
			worklist = mixInwardTable(worklist)
		end
		if ask.allLoops.value then
			allLoops()
		end
		sphereSize = ask.sphereSize.value
		doLocalWiggleShake = ask.doLocalWiggleShake.value
		doBlueFuze = ask.doBlueFuze.value
		numRebuilds = ask.numRebuilds.value
		startWalkingRebuild(worklist, startLength, endLength, maxRebuildIterations, sphereSize, doLocalWiggleShake, doBlueFuze)
	else
		print("Cancelled")
		return
	end
end

function cleanup(err)
	print("Restoring CI, best result and structures")
	setCI(1)
	save.Quickload(3)
	if saveStructures then
		save.LoadSecondaryStructure()
	end
	selection.DeselectAll()
	print(err)
end

function main()
	disableFilters = false
	saveStructures = true
	randomSeed = os.time() % 1000000
	numRebuilds = 1
	wiggleFactor = 1

	-- On request of gmn
	CIfactor = 1
	maxCI = true

	segCount = structure.GetCount()

	while structure.GetSecondaryStructure(segCount) == "M" do
		segCount = segCount - 1
	end

	startLength = segCount
	endLength = 1
	maxRebuildIterations = 5
	sphereSize = 9
	doLocalWiggleShake = true
	doBlueFuze = true

	-- Handy shorts module
	normal = (current.GetExplorationMultiplier() == 0)

	if behavior.GetClashImportance() < 0.99 then
		checkCI()
	end
	CIfactor = behavior.GetClashImportance()

	bestScore = current.GetScore()
	save.Quicksave(3)

	print(scriptName .. " v" .. scriptVersion .. " build " .. buildNumber)
	AskWalking()
end

xpcall(main, cleanup)
