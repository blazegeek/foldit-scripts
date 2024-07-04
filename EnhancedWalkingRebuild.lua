-- Based on TvdL Walking Rebuild V2 1.6.1 by ?
scriptName = "Enhanced Walking Rebuild"
scriptVersion = 1.0
buildNumber = 2

--[[
Walking Rebuild v4 - Sphered
All options at end
Modified by TvdL, made with Lua v2 and using my modules.

Options are now interactive
v1.6.0 by Bruno Kestemont added inward, outward and slice ward walks
v1.6.1 debugged slices
TO DO: bug see DEBUG lines
v1.6.2: Modified maximum rebuild length to actual number of segments, added slider to adjust max iterations
]]--

function down(x)
	return x - x % 1
end

function CI(CInr)
	if CInr > 0.99 then
		maxCI = true
	else
		maxCI = false
	end
	behavior.SetClashImportance(CInr * CIfactor)
end

function CheckCI()
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

function segmentScore(pose)
	if pose == nil then
		pose = current
	end
	local total = 8000
	for i = 1, segCount2 do
		total = total + pose.GetSegmentEnergyScore(i)
	end
	return total
end

function scoreRecentBest()
	return getScore(recentbest)
end

function round3(x)
		return x - x % 0.001
end

function saveBest()
	local g = getScore() - bestScore
	if g > 0 then
		if g > 0.001 then
			print("Gained another " .. round3(g) .. " points")
		end
		bestScore = getScore()
		save.Quicksave(3)
	end
end

-- doWiggle function
-- Optimized due to Susumes ideas
-- Note the extra parameter to be used if only selected parts must be done
function doWiggle(how, iters, minppi, onlyselected)
	--score conditioned recursive wiggle/shake
	--fixed a bug, absolute difference is the threshold now
	if how == nil then
		how = "wa"
	end
	if iters == nil then
		iters = 3
	end
	if minppi == nil then
		minppi = 0.1
	end
	if onlyselected == nil then
		onlyselected = false
	end

	local wiggleFactor = 1
	-- [NOTE] This is redundant
	if maxCI then
		wiggleFactor = 1
	end
	local sp = getScore()
	if onlyselected then
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

-- end of handy shorts module
-- Segment set and list module
-- Notice that most functions assume that the sets are well formed
-- (=ordered and no overlaps)
-- 02-05-2012 TvdL Free to use for non commercial purposes
function SegmentListToSet(list)
	local result = {}
	local f = 0
	local l = -1
	table.sort(list)
	for i = 1, #list do
		if list[i] ~= l + 1 and list[i] ~= l then
			-- note: duplicates are removed
			if l > 0 then
				result[#result + 1] = {f, l}
			end
			f = list[i]
		end
		l = list[i]
	end
	if l > 0 then
		result[#result + 1] = {f, l}
	end
	return result
end

function SegmentSetToList(set)
	local result = {}
	for i = 1, #set do
		for k = set[i][1], set[i][2] do
			result[#result + 1] = k
		end
	end
	return result
end

function SegmentCleanSet(set)
-- Makes it well formed
	return SegmentListToSet(SegmentSetToList(set))
end

function SegmentInvertSet(set, maxSeg)
	-- Gives back all segments not in the set
	-- maxSeg is added for ligand
	local result = {}
	if maxSeg == nil then
		maxSeg=structure.GetCount()
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

function SegmentInvertList(list)
	table.sort(list)
	local result = {}
	for i = 1, #list - 1 do
		for j = list[i] + 1, list[i + 1] - 1 do
			result[#result + 1] = j
		end
	end
	for j = list[#list] + 1, segCount2 do
		result[#result + 1] = j
	end
	return result
end

function SegmentInList(s, list)
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

function SegmentInSet(set, s)
	for i = 1, #set do
		if s >= set[i][1] and s <= set[i][2] then
			return true
		elseif s < set[i][1] then
			return false
		end
	end
	return false
end

function SegmentJoinList(list1, list2)
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

function SegmentJoinSet(set1, set2)
	return SegmentListToSet(SegmentJoinList(SegmentSetToList(set1), SegmentSetToList(set2)))
end

function SegmentCommList(list1, list2)
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

function SegmentCommSet(set1, set2)
	return SegmentListToSet(SegmentCommList(SegmentSetToList(set1), SegmentSetToList(set2)))
end

function SegmentSetMinus(set1, set2)
	return SegmentCommSet(set1, SegmentInvertSet(set2))
end

function SegmentPrintSet(set)
	print(SegmentSetToString(set))
end

function SegmentSetToString(set)
	local line = ""
	for i = 1, #set do
		if i ~= 1 then
			line = line .. ", "
		end
	line = line .. set[i][1] .. "-" .. set[i][2]
	end
	return line
end

function SegmentSetInSet(set, sub)
	if sub == nil then
		return true
	end
	-- Checks if sub is a proper subset of set
	for i = 1, #sub do
		if not SegmentRangeInSet(set, sub[i]) then
			return false
		end
	end
	return true
end

function SegmentRangeInSet(set, range)
	if range == nil or #range == 0 then
		return true
	end
	local b = range[1]
	local e = range[2]
	for i = 1, #set do
		if b >= set[i][1] and b <= set[i][2] then
			return (e <= set[i][2])
		elseif e <= set[i][1] then
			return false
		end
	end
	return false
end

function SegmentSetToBool(set)
	local result = {}
	for i = 1, structure.GetCount() do
		result[i] = SegmentInSet(set, i)
	end
	return result
end
--- End of Segment Set module

-- Module Find Segment Types
function FindMutablesList()
	local result = {}
	for i = 1, segCount2 do
		if structure.IsMutable(i) then
			result[#result + 1] = i
		end
	end
	return result
end

function FindMutables()
	return SegmentListToSet(FindMutablesList())
end

function FindFrozenList()
	local result = {}
	for i = 1, segCount2 do
		if freeze.IsFrozen(i) then
			result[#result + 1] = i
		end
	end
	return result
end

function FindFrozen()
	return SegmentListToSet(FindFrozenList())
end

function FindLockedList()
	local result = {}
	for i = 1, segCount2 do
		if structure.IsLocked(i) then
			result[#result + 1] = i
		end
	end
	return result
end

function FindLocked()
	return SegmentListToSet(FindLockedList())
end

function FindSelectedList()
	local result = {}
	for i = 1, segCount do
		if selection.IsSelected(i) then
			result[#result + 1] = i
		end
	end
	return result
end

function FindSelected()
	return SegmentListToSet(FindSelectedList())
end

function FindAAtypeList(aa)
	local result = {}
	for i = 1, segCount2 do
		if structure.GetSecondaryStructure(i) == aa then
			result[#result + 1] = i
		end
	end
	return result
end

function FindAAtype(aa)
	return SegmentListToSet(FindAAtypeList(aa))
end

function FindAminotype(at) --NOTE: only this one gives a list not a set
	local result = {}
	for i = 1, segCount2 do
		if structure.GetAminoAcid(i) == at then
			result[#result + 1] = i
		end
	end
	return result
end
-- end Module Find Segment Types

-- Module setsegmentset
-- Tvdl, 11-05-2012 Free to use for noncommercial purposes
function SetSelection(set)
	selection.DeselectAll()
	if set ~= nil then
		for i = 1, #set do
			selection.SelectRange(set[i][1], set[i][2])
		end
	end
end

function SelectAround(segStart, segEnd, radius, nodeselect)
	if nodeselect~=true then
		selection.DeselectAll()
	end
	for i = 1, segCount2 do
		for x = segStart, segEnd do
			if structure.GetDistance(x, i) < radius then
				selection.Select(i)
				break
			end
		end
	end
end

function SetAAtype(set, aa)
	local saveselected = FindSelected()
	SetSelection(set)
	structure.SetSecondaryStructureSelected(aa)
	SetSelection(saveselected)
end

function AllLoop() --turning entire structure to loops
	local anychange = false
	for i = 1, segCount2 do
		if structure.GetSecondaryStructure(i) ~= "L" then
			anychange = true
			break
		end
	end
	if anychange then
		save.SaveSecondaryStructure()
		SAVEDstructs = true
		selection.SelectAll()
		structure.SetSecondaryStructureSelected("L")
	end
end

-- Module Random
-- Tvdl, 01-11-2012

function Seedrandom()
	math.randomseed(Randomseed)
	math.random(100) -- Because the first is not random
end

-- Thanks too Rav4pl
function ShuffleTable(tab) --randomize order of elements
	local cnt = #tab
	for i = 1, cnt do
		local r = math.random(cnt)
		tab[i], tab[r] = tab[r], tab[i]
	end
	return tab
end

--START MIX TABLE subroutine by Bruno Kestemont 16/11/2015, idea by Puxatudo & Jeff101 from Go Science
function ShuffleTable(tab) --randomize order of elements
	local cnt = #tab
	for i = 1, cnt do
		local r = math.random(cnt) -- not very convincing ! it gives always the same number on same puzzle
		tab[i], tab[r] = tab[r], tab[i]
	end
	return tab
end

function MixInwardTable(tab) -- 1234567 = 7254361 WARNING: if done twice, it returns to the original table
	local cnt = #tab -- 1234567 = 7254361
	local mid = down(cnt / 2)
	local adjust = 1 -- case of pair number of segments
	local result = {}
	local pair = true
	if mid < cnt / 2 then
		adjust = 0
	end -- case of impair number of segments
	for i = 1, mid-adjust do -- mid remains untouched if impair cnt
		pair = not pair
		if pair then
			result[i], result[cnt + 1 - i] = tab[i], tab[cnt + 1 - i] -- pair segs are kept untouched
		else
			result[i], result[cnt + 1 - i] = tab[cnt + 1 - i], tab[i] -- impairs segs are shifted (loop starts with last seg)
		end
	end
	return result
end

function InwardTable(tab) -- 1234567 = 7162534 WARNING: if done twice, it mixes everything like a feuillete bakery
	local cnt = #tab -- 1234567 = 7162534
	local cntup = 1
	local result = {}
	local pair = true
	for i = 1, #tab do
		pair = not pair
		if pair then
			result[i] = tab[cntup] -- pairs segments are taken from bottom
			cntup = cntup + 1
		else
			result[i] = tab[cnt] -- impairs segs are taken from end (loop starts with last seg)
			cnt = cnt - 1
		end
	end
	return result
end

function Reverselist(tab) -- 1234567=7654321
	local cnt = #tab
	local result = {}
	for i = 1, #tab do -- simply inverts the table 7162534=4536271
		result[i] = tab[cnt + 1 - i]
	end
	return result
end

function OutwardTable(tab) --1234567=4352617
	local result={}
	result = Reverselist(InwardTable(tab))
	return result
end
--END MIX TABLE

-- Module AskSelections
-- 02-05-2012 Timo van der Laan, Free to use for non commercial purposes
function AskForSelections(title, mode)
	local result = {{1, structure.GetCount()}} -- All segments
	if mode == nil then
		mode = {}
	end
	if mode.askloops == nil then
		mode.askloops = true
	end
	if mode.asksheets == nil then
		mode.asksheets = true
	end
	if mode.askhelixes == nil then
		mode.askhelixes = true
	end
	if mode.askligands == nil then
		mode.askligands = false
	end
	if mode.askselected == nil then
		mode.askselected = true
	end
	if mode.asknonselected == nil then
		mode.asknonselected = true
	end
	if mode.askmutateonly == nil then
		mode.askmutateonly = true
	end
	if mode.askignorelocks == nil then
		mode.askignorelocks = true
	end
	if mode.askignorefrozen == nil then
		mode.askignorefrozen = true
	end
	if mode.askranges == nil then
		mode.askranges = true
	end
	if mode.defloops == nil then
		mode.defloops = true
	end
	if mode.defsheets == nil then
		mode.defsheets = true
	end
	if mode.defhelixes == nil then
		mode.defhelixes = true
	end
	if mode.defligands == nil then
		mode.defligands = false
	end
	if mode.defselected == nil then
		mode.defselected = false
	end
	if mode.defnonselected == nil then
		mode.defnonselected = false
	end
	if mode.defmutateonly == nil then
		mode.defmutateonly = false
	end
	if mode.defignorelocks == nil then
		mode.defignorelocks = false
	end
	if mode.defignorefrozen == nil then
		mode.defignorefrozen = false
	end

	local errFound = false

	repeat
		local ask = dialog.CreateDialog(title)
		if errFound then
			ask.E1 = dialog.AddLabel("Try again, ERRORS found, check output box")
			result = {{1, structure.GetCount()}} --reset start
			errFound = false
		end

		if mode.askloops then
			ask.loops = dialog.AddCheckbox("Work on loops", mode.defloops)
		elseif not mode.defloops then
			ask.noloops = dialog.AddLabel("Loops will be auto excluded")
		end

		if mode.askhelixes then
				ask.helixes = dialog.AddCheckbox("Work on helixes", mode.defhelixes)
		elseif not mode.defhelixes then
				ask.nohelixes = dialog.AddLabel("Helixes will be auto excluded")
		end

		if mode.asksheets then
				ask.sheets = dialog.AddCheckbox("Work on sheets", mode.defsheets)
		elseif not mode.defsheets then
				ask.nosheets = dialog.AddLabel("Sheets will be auto excluded")
		end

		if mode.askligands then
				ask.ligands = dialog.AddCheckbox("Work on ligands", mode.defligands)
		elseif not mode.defligands then
				ask.noligands = dialog.AddLabel("Ligands will be auto excluded")
		end

		if mode.askselected then
			ask.selected = dialog.AddCheckbox("Work only on selected", mode.defselected)
		end
		if mode.asknonselected then
			ask.nonselected = dialog.AddCheckbox("Work only on nonselected", mode.defnonselected)
		end
		if mode.askmutateonly then
			ask.mutateonly = dialog.AddCheckbox("Work only on mutateonly", mode.defmutateonly)
		end
		if mode.askignorelocks then
			ask.ignorelocks = dialog.AddCheckbox("Dont work on locked ones", true)
		elseif mode.defignorelocks then
			ask.nolocks = dialog.AddLabel("Locked ones will be auto excluded")
		end
		if mode.askignorefrozen then
			ask.ignorefrozen = dialog.AddCheckbox("Dont work on frozen", true)
		elseif mode.defignorefrozen then
			ask.nofrozen = dialog.AddLabel("Frozen ones will be auto excluded")
		end
		if mode.askranges then
			ask.R1 = dialog.AddLabel("Or put in segmentranges. Above selections also count")
			ask.ranges = dialog.AddTextbox("Ranges", "")
		end

		ask.OK = dialog.AddButton("OK", 1)
		ask.Cancel = dialog.AddButton("Cancel",0)

		if dialog.Show(ask) > 0 then
			-- We start with all the segments including ligands
			if mode.askloops then
				mode.defloops = ask.loops.value
			end
			if not mode.defloops then
				result = SegmentSetMinus(result, FindAAtype("L"))
			end
			if mode.asksheets then
				mode.defsheets = ask.sheets.value
			end
			if not mode.defsheets then
				result = SegmentSetMinus(result, FindAAtype("E"))
			end
			if mode.askhelixes then
				mode.defhelixes = ask.helixes.value
			end
			if not mode.defhelixes then
				result = SegmentSetMinus(result, FindAAtype("H"))
			end
			if mode.askligands then
				mode.defligands = ask.ligands.value
			end
			if not mode.defligands then
				result = SegmentSetMinus(result, FindAAtype("M"))
			end
			if mode.askignorelocks then
				mode.defignorelocks = ask.ignorelocks.value
			end
			if mode.defignorelocks then
				result = SegmentSetMinus(result, FindLocked())
			end
			if mode.askignorefrozen then
				mode.defignorefrozen = ask.ignorefrozen.value
			end
			if mode.defignorefrozen then
				result = SegmentSetMinus(result, FindFrozen())
			end
			if mode.askselected then
				mode.defselected = ask.selected.value
			end
			if mode.defselected then
				result = SegmentCommSet(result, FindSelected())
			end
			if mode.asknonselected then
				mode.defnonselected = ask.nonselected.value
			end
			if mode.defnonselected then
				result = SegmentCommSet(result, SegmentInvertSet(FindSelected()))
			end
			if mode.askranges and ask.ranges.value ~= "" then
				local rangetext = ask.ranges.value
				local function Checknums(nums)
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

				local function ReadSegmentSet(data)
					local nums = {}
					local NoNegatives = '%d+' -- - is not part of a number
					local result = {}
					for v in string.gfind(data, NoNegatives) do
						table.insert(nums, tonumber(v))
					end
					if Checknums(nums) then
						for i = 1, #nums / 2 do
							result[i] = {nums[2 * i - 1], nums[2 * i]}
						end
						result = SegmentCleanSet(result)
					else
						errFound = true
						result = {}
					end
					return result
				end
				local rangelist = ReadSegmentSet(rangetext)
				if not errFound then
					result = SegmentCommSet(result, rangelist)
				end
			end
		end
	until not errFound
	return result
end
-- end of module AskSelections

function Gibaj(jak, iters, minppi) --score conditioned recursive wiggle/shake
 if jak == nil then
	jak = "wa"
 end
 if iters == nil then
	iters = 6
 end
 if minppi == nil then
	minppi = 0.04
 end
 if iters > 0 then
	iters = iters - 1
	local sp = getScore()
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
	local ep = getScore()
	local ig = ep - sp
	if ig > minppi then Gibaj(jak, iters, minppi) end
 end
end

function BlueFuse(locally)
	recentbest.Save()
	if locally ~= true then
		selection.SelectAll()
	end
	CI(.05)
	structure.ShakeSidechainsSelected(1)
	CI(1)
	Gibaj()
	CI(.07)
	structure.ShakeSidechainsSelected(1)
	CI(1)
	Gibaj()
	recentbest.Restore()
	CI(.3)
	selection.DeselectAll()
	structure.WiggleAll(1, true, true)
	CI(1)
	Gibaj()
	recentbest.Restore()
end

function Lws(minGain) --score conditioned local wiggle,
	CI(1)
	if minGain == nil then
		minGain = 1
	end
	repeat --wiggles selected segments
		local scoreStart = getScore()
		structure.LocalWiggleSelected(2, true, true)
		local scoreEnd = getScore()
		local wiggleGain = scoreEnd - scoreStart
		if wiggleGain < 0 then
			recentbest.Restore()
		end
	until wiggleGain < minGain
end

function AfterRebuild(lws, useBlueFuze, locally)
	if lws == nil then
		lws = true
	end
	if useBlueFuze == nil then
		useBlueFuze = true
	end
	recentbest.Save()
	CI(1)
	Gibaj("s", 1)
	Gibaj("ws", 1)
	Gibaj("s", 1)
	Gibaj("ws", 1)
	if lws then
		Lws(2)
	end
	if useBlueFuze then
		BlueFuse(locally)
	end
	selection.SelectAll()
	Gibaj()
end

function Rebuild(maxIters) --local rebuild until any change
	if maxIters == nil then
		maxIters = 5
	end
	local rebuildScore = -10000
	local startScore = getScore()
	save.Quicksave(9)
	for j = 1, nRB do
		local i = 0
		repeat
			local s = getScore()
			i = i + 1
			if i > maxIters then
				break
			end --impossible to rebuild!
			structure.RebuildSelected(i)
		until getScore() ~= s
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

function LocalRebuild(segStart, segEnd, maxIters, sphere, lws, useBlueFuze)
	if segStart > segEnd then
		segStart, segEnd = segEnd, segStart
	end
	if segStart ~= segEnd then
		print("Working on sgmnts " .. segStart .. "-" .. segEnd .. " from " .. round3(getScore()))
	else
		print("Working on sgmnt " .. segStart .. " from " .. round3(getScore()))
	end
	selection.DeselectAll()
	selection.SelectRange(segStart, segEnd)
	local sc = getScore()
	local ok = Rebuild(maxIters)
	if ok then
		SelectAround(segStart, segEnd, sphere, true)
		AfterRebuild(lws, useBlueFuze, true)
	end
	local gain = getScore() - sc
	if gain > 0 then
		save.Quicksave(3)
		print("Rebuild accepted! Gain: ", gain)
	elseif gain < 0 then
		save.Quickload(3)
	else
		print("Unable to rebuild.")
	end
end

function Build(worklist, len, maxIters, sphere, lws, useBlueFuze)
	for i = 1, #worklist do
		if worklist[i] == nil then
			break
		end -- DEBUG
		local s1 = worklist[i]
		if s1 + len - 1 <= segCount2 then
			LocalRebuild(s1, s1 + len - 1, maxIters, sphere, lws, useBlueFuze)
		end
	end
end

function startWalkingRebuild(worklist, startLength, endLength, maxIters, sphere, lws, useBlueFuze)
	local sscore = getScore()
	print("Walking Rebuild started. Score: ", round3(sscore))
	freeze.UnfreezeAll()
	selection.DeselectAll()
	recentbest.Save()
	save.Quicksave(3)
	local steplen = 1
	if startLength > endLength then
		steplen = -1
	end
	for i = startLength, endLength, steplen do
		print("\nTrying rebuilds of length: " .. i)
		Build(worklist, i, maxIters, sphere, lws, useBlueFuze)
	end
	print("Total rebuild gain: ", round3(getScore() - sscore))
	cleanup("Finishing")
end

function AskWalking()
	Seedrandom()
	local ask = dialog.CreateDialog(scriptName .. " build " .. buildNumber)
	ask.l0 = dialog.AddLabel("From length can be higher then To length")
	ask.firstlen = dialog.AddSlider("From length:", startLength, 1, segCount, 0) -- changed maximum length to segment count
	ask.lastlen = dialog.AddSlider("To length:", endLength, 1, segCount, 0)
	ask.l1 = dialog.AddLabel("Pick the best rebuild of")
	ask.nrRB = dialog.AddSlider("Number of RBs:", nRB, 1, 10, 0)
	ask.maxIters = dialog.AddSlider("Max Iterations:", maxIters, 1, 10, 0) -- added slider to adjust max iterations
	ask.selSeg = dialog.AddCheckbox("Select where to work on", false)
	ask.backward = dialog.AddCheckbox("Backward walk", false)
	ask.random = dialog.AddCheckbox("Random walk", false)
	ask.inward = dialog.AddCheckbox("Inward walk", false)
	ask.outward = dialog.AddCheckbox("Outward walk", false)
	ask.sliceward = dialog.AddCheckbox("Sliceward walk", false)

	ask.allloop = dialog.AddCheckbox("All loops", false)
	ask.spheresize = dialog.AddSlider("Sphere size:", sphere, 3, 15, 0)
	ask.uselw = dialog.AddCheckbox("Do local wiggles:", lws)
	ask.usebf = dialog.AddCheckbox("Use Blue Fuze:", useBlueFuze)
	ask.OK = dialog.AddButton("OK" ,1)
	ask.Cancel = dialog.AddButton("Cancel", 0)

	if dialog.Show(ask) > 0 then
		startLength = ask.firstlen.value
		endLength = ask.lastlen.value
		local worklist = {{1, segCount2}} -- List of segments to work on
		if ask.selSeg.value then
			worklist=SegmentSetToList(AskForSelections(scriptName))
		else
			worklist = SegmentSetToList(worklist)
		end
		if ask.backward.value then
			local blist = {}
			for i = 1, #worklist do
				blist[i] = worklist[#worklist + 1 - i]
			end
			worklist = blist
		end
		if ask.random.value then
			worklist = ShuffleTable(worklist)
		end
		if ask.inward.value then
			worklist = InwardTable(worklist)
		end
		if ask.outward.value then
			worklist = OutwardTable(worklist)
		end
		if ask.sliceward.value then
			worklist = MixInwardTable(worklist)
		end
		if ask.allloop.value then
			AllLoop()
		end
		sphere = ask.spheresize.value
		lws = ask.uselw.value
		useBlueFuze = ask.usebf.value
		nRB = ask.nrRB.value
		startWalkingRebuild(worklist, startLength, endLength, maxIters, sphere, lws, useBlueFuze)
	else
		print("Cancelled")
		return
	end
end

function cleanup(err)
	print("Restoring CI, best result and structures")
	CI(1)
	save.Quickload(3)
	if SAVEDstructs then
		save.LoadSecondaryStructure()
	end
	selection.DeselectAll()
	print(err)
end

function main()
	disableFilters = false
	SAVEDstructs = true
	Randomseed=os.time()%1000000
	nRB = 1 --Nr of different rebuilds to be made
	-- New WiggleFactor
	wiggleFactor = 1

	-- On request of gmn
	CIfactor = 1
	maxCI = true

	segCount = structure.GetCount()
	segCount2 = segCount

	while structure.GetSecondaryStructure(segCount2) == "M" do
		segCount2 = segCount2 - 1
	end

	startLength = segCount -- changed initial value to maximum
	endLength = 1 -- changed to min
	maxIters = 5 -- this can now be adjusted via dialog
	sphere = 9
	lws = true
	useBlueFuze = true

	-- Handy shorts module
	normal = (current.GetExplorationMultiplier() == 0)

	if behavior.GetClashImportance() < 0.99 then
		CheckCI()
	end
	CIfactor=behavior.GetClashImportance()

	bestScore = current.GetScore()
	save.Quicksave(3)

	print(scriptName .. " build " .. buildNumber)
	AskWalking()
end

--[[
startWalkingRebuild(usesegs,startLength, endLength, maxIters, sphere, lws, useBlueFuze)
usesegs- segmentlist to rebuild
startLength- first sgmnts len to be rebuild (may be even 1)
endLength- last sgmnts len to be rebuild (may be less then startLength)
maxIters- maximum tries to rebuild
sphere- sphere size for shake/wiggle after rebuild
lws- LWS sphere around (min gain 2pts, not LWSing totally)
useBlueFuze- BlueFuze sphere around

Note: 'loopmode' variable removed as it isn't used in this script (relic from previous versions?)
]]--


xpcall(main, cleanup)
