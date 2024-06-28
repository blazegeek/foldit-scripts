scriptName ="Acid Tweaker"
scriptVersion = 2.8.1
scriptBuild = 2

getTotalScore = 0
listSegmentEnergyScore = {}
normal = (current.GetExplorationMultiplier() == 0)
startRecTime = os.clock()
OriginalFilterSetting = filter.AreAllEnabled()

--Start MIX TABLE inits
numSegments = structure.GetCount()
flagLigand = false
numSegments2 = numSegments -- for ligands (maybe revise this to eliminate numSegments2 altogether)
while structure.GetSecondaryStructure(numSegments2) == "M" do
	numSegments2 = numSegments2 - 1
end
segStart = 1
segEnd = numSegments2
workOnBIS = {} -- the table to use is a simple list of segments in any order
counterVar = 0
for i = segStart, segEnd do -- basic list of segments (init of workOnBIS)
	counterVar = counterVar + 1
	workOnBIS[counterVar] = i
end
mixtables = 1
randomly = false
--End MIX TABLE inits

if not OriginalFilterSetting then
	print("Filter disabled on start, is that intended?")
	local function checkUserFilterPrefDialog()
		local dlg = dialog.CreateDialog("Are you sure?")
		dlg.L1 = dialog.AddLabel("Filter disabled on start, is that intended?")
		dlg.ok = dialog.AddButton("YES", 0)
		dlg.cancel = dialog.AddButton("NO", 1)
		if dialog.Show(dlg) > 0 then
			print("Enabling filter by default")
			filter.EnableAll()
		end
	end
	checkUserFilterPrefDialog()
end

filterManagement = false
isCentroid = false
isContactMap = false
isHydrogenBonds = false
-- Why is this list needed? Are these 'bugs' still present in latest Foldit versions?
badPuzzle = {'999'} -- list of not implemented puzzles - to be edited on each bug with puzzle nb

function returnToOrigFilterSetting()
	if OriginalFilterSetting then
		filter.EnableAll()
	else
		filter.DisableAll()
	end

end

-- Why this? This seems like a cumbersome way to detect filters
probableFilter = false
genericFilter = false
function detectFilter()
	local descrTxt = puzzle.GetDescription()
	if #descrTxt > 0 and (descrTxt:find("filter") or descrTxt:find("filters") or descrTxt:find("Bonus") or descrTxt:find("bonuses")
		or descrTxt:find("bonus") or descrTxt:find("Objectives") or descrTxt:find("Filters")) then
		probableFilter = true
		print("Bonus active")
	end
	return
end
detectFilter()

function CopyTable(orig)
	local copy = {}
	for originalKey, originalValue in pairs(orig) do
		copy[originalKey] = originalValue
	end
	return copy
end

function FiltersOn()
	if filter.AreAllEnabled() then
		filter.EnableAll()
	end
end

function FiltersOff()
	if not filter.AreAllEnabled() then
		filter.DisableAll()
	end
end

function mutateFunction(func)
	local currentFunction = func
	local function mutateFunc(func, newfunc)
		local lastFunction = currentFunction
		currentFunction = function(...) return
			newfunc(lastFunction, ...)
		end
	end
	local wrapper = function(...)
		return currentFunction(...)
	end
	return wrapper, mutateFunc
end

-- Function to overload a class
-- To Do: set the name of function
numClassesCopied = 0
myClassCopy = {}

function mutateClass(theClass, withFilters)
	numClassesCopied = numClassesCopied + 1
	myClassCopy[numClassesCopied] = CopyTable(theClass)
	local myClass = myClassCopy[numClassesCopied]
	for originalKey, originalValue in pairs(theClass) do
		myFunc, mutateFunc = mutateFunction(myClass[originalKey])
		if withFilters == true then
			mutateFunc(myFunc, function(...)
				FiltersOn()
				if table.getn(arg) > 1 then
					-- first arg is self (function pointer), we pack from second argument
					local arguments = {}
					for i = 2, table.getn(arg) do
						arguments[i - 1] = arg[i]
					end
					return myClass[originalKey](unpack(arguments))
				else
					print("No arguments")
					return myClass[originalKey]()
				end
			end)
			theClass[originalKey] = myFunc
		else
			mutateFunc(myFunc, function(...)
				FiltersOff()
				if table.getn(arg) > 1 then
					local arguments = {}
					for i = 2, table.getn(arg) do
						arguments[i - 1] = arg[i]
					end
					return myClass[originalKey](unpack(arguments))
				else
					return myClass[originalKey]()
				end
			end)
			theClass[originalKey] = myFunc
		end
	end
end

indexLigand = {} -- not used here yet
-- This is redundant. The while statement on line 15 detects any ligands and changes the last segment accordingly.
function detectLigand()
	local lastSeg1 = structure.GetCount()
	local lastSeg2 = lastSeg1
	 while structure.GetSecondaryStructure(lastSeg1) == "M" do
		flagLigand = true
		lastSeg1 = lastSeg1 - 1
	end
	if lastSeg1 + 1 == lastSeg2 then
		indexLigand = {lastSeg2}
	else
		indexLigand = {lastSeg1, lastSeg2}
	end
	numSegments2 = lastSeg1
end
detectLigand()

--[[
			Do we actually need to detect puzzle properties? This code is over a decade old...
			TO DO: 	Trace these properties variables to determine how and why they are used.
							Remove anything non-essential
							Simplify anything essential with modern Lua functions, if they exist
]]--

function puzzleProperties()
	local descrTxt = puzzle.GetDescription()
	local puzzletitle = puzzle.GetName()
	if #puzzletitle > 0 then
		for i = 1, #badPuzzle do
			if puzzletitle:find(i) then -- check if not bizarre puzzle
			notImplemented = true
			end
		end
		if (puzzletitle:find("Sym") or puzzletitle:find("Symmetry") or puzzletitle:find("Symmetric")
				or puzzletitle:find("Dimer") or puzzletitle:find("Trimer") or puzzletitle:find("Tetramer")
				or puzzletitle:find("Pentamer")) then
			probableSymmetry = true
			if puzzletitle:find("Dimer") and not puzzletitle:find("Dimer of Dimers") then sym = 2
			elseif puzzletitle:find("Trimer") or puzzletitle:find("Tetramer") then sym = 3
			elseif puzzletitle:find("Dimer of Dimers") or puzzletitle:find("Tetramer") then sym = 4
			elseif puzzletitle:find("Pentamer") then sym = 5
			else
			end
		end
	end
	if #descrTxt > 0 and (descrTxt:find("Sym") or descrTxt:find("Symmetry") or descrTxt:find("Symmetric")
			or descrTxt:find("sym") or descrTxt:find("symmetry") or descrTxt:find("symmetric")) then
		probableSymmetry = true
		if (descrTxt:find("Dimer") or descrTxt:find("dimer"))
			and not (descrTxt:find("Dimer of Dimers") or descrTxt:find("dimer of dimers")) then sym = 2
		elseif descrTxt:find("Trimer") or descrTxt:find("trimer") then sym = 3
		elseif (descrTxt:find("Dimer of Dimers") or descrTxt:find("Tetramer"))
			and not (descrTxt:find("dimer of dimers") or descrTxt:find("tetramer"))then sym = 4
		elseif descrTxt:find("Pentamer") or descrTxt:find("pentamer") then sym = 5
		end
	end
	if #descrTxt>0 and (descrTxt:find("filter") or descrTxt:find("filters") or descrTxt:find("Bonus") or descrTxt:find("bonuses")
		or descrTxt:find("bonus") or descrTxt:find("Objectives") or descrTxt:find("Filters")) then
		probableFilter = true
		print("Bonus active")
	end
	if #puzzletitle > 0 and puzzletitle:find("Sepsis") then
		isSepsis = true
	end
	if #puzzletitle > 0 and puzzletitle:find("Electron Density") then
		isElectronDensity = true
	end
	if #puzzletitle > 0 and puzzletitle:find("Centroid") then
		--print(true,"-Centroid")
		isCentroid = true
	end
	if #puzzletitle > 0 and puzzletitle:find("Contacts") then
		isContactMap = true
	end
	if #puzzletitle > 0 and puzzletitle:find("H-Bonds") then
		isHydrogenBonds = true
	end
	return
end

function getScore(pose)
	if pose == nil then
		pose = current
	end
	local total = pose.GetEnergygetScore()
	if total < -999999 and total > -1000001 then
		total = segmentScore(pose)
	end
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
	for i = segStart, segEnd do
		total = total + pose.GetSegmentEnergyScore(i)
	end
	return total
end

-- Is this still a necessary bugfix?
function FakeRecentBestSave()
	if probableFilter then
		save.Quicksave(5)
	else
		recentbest.Save()
	end
end

-- Is this still a necessary bugfix?
function FakeRecentBestRestore()
	if probableFilter then
		local scoreBefore = getScore()
		recentbest.Restore()
		local scoreAfter = getScore()
		if scoreAfter > scoreBefore then
			save.Quicksave(5)
		end
		save.Quickload(5)
	else
		recentbest.Restore()
	end
end

-- This function call has already been commented out. Can it just be deleted entirely then?
function ds(val)
	if doMutate == true then
		if filterManagement then
			filter.EnableAll()
		end
		structure.MutateSidechainsSelected(val + 1)
	else
		structure.ShakeSidechainsSelected(val)
	end
end

--[[
			s		= shake
			wb	= wiggle backbone
			Ws	= wiggle sidechain
			wa	= wiggle all
			lw	= local wiggle selected
			rb	= rebuild selected

			Is there a default case if how is nil?
]]--

function WiggleSimple(val, how)
	if filterManagement then
		filter.DisableAll()
	end
	if isCentroid then
		if how == "s" or how == "ws" then
			how = "wa"
		end
	end
	if how == "s" then
		ds(1)
	elseif how == "wb" then
		structure.WiggleSelected(val, true, false)
	elseif how == "ws" then
		structure.WiggleSelected(val, false, true)
	elseif how == "wa" then
		structure.WiggleSelected(val, true, true)
	elseif how == "lw" then
		structure.LocalWiggleSelected(val)
	elseif how == "rb" then
		structure.RebuildSelected(1)
	end
	if filterManagement then
		returnToOrigFilterSetting()
	end
end

function WiggleAT(ss, how, iters, minppi)
	local iterationValue = 2
	local val = 1
	if doFast == true then
		iterationValue = 1
	end
	if how == nil then
		how = "wa"
	end
	if isCentroid then
		if how == "s" or how == "ws" then
			how = "wa"
		end
	end
	if iters == nil then
		iters = 6
	end
	minppi = (getTotalScore - getScore()) / 100
	if ((minppi == nil) or (minppi < 0.001)) then
		minppi = 0.001
	end
	if global_ci == 1.00 then
		val = iterationValue
	end
	if iters > 0 then
		iters = iters - 1
		local checkStartScore = getScore()
		WiggleSimple(val, how)
		local checkEndScore = getScore()
		local interimGain = checkEndScore - checkStartScore
		if how ~= "s" then
			if interimGain > minppi then
				WiggleAT(ss, how, iters, minppi)
			end
		end
	end
end

function SelectSphere(seg, radius, nodeselect)
	if nodeselect ~= true then
		selection.DeselectAll()
	end
	for i = 1, numSegments do
		if structure.GetDistance(seg, i) < radius then
			selection.Select(i)
		end
		if includeWorstInSphere == true then
			if current.GetSegmentEnergyScore(i) < includeWorstInSphereValue then
				selection.Select(i)
			end
		end
	end
end

function fixBands(seg)
	if doFixBands == false then
		return
	end
	-- selection.DeselectAll()
	local nb = 1
	for i = 1, numSegments do
		checkDistance = structure.GetDistance(seg, i)
		if (checkDistance < 12 and checkDistance > 6) then
			local cband = band.GetCount()
			band.AddBetweenSegments(seg, i)
			if cband < band.GetCount() then
				band.SetGoalLength(nb, checkDistance)
				nb = nb + 1
			end
			-- else if checkDistance > 12 then
			-- selection.Select(i)
			-- end
		end
	end
	-- freeze.FreezeSelected(true, true)
	-- selection.DeselectAll()
	-- SelectSphere(seg, sphereSize)
	--structure.WiggleSelected(1, true, true)
	WiggleSimple(1, "wa")
	band.DeleteAll()
	-- freeze.UnfreezeAll()
end

function round(x)
	return x - x % 0.001
end

-- Calculate REALLY good seed for the pseudorandom in random (avoids to always have the same sequence)
-- Any time score is calcultated on first read, this is verified (for filter bug)
returnToOrigFilterSetting()
seed = os.time() / math.abs(getScore())
seed = seed % 0.001
seed = 1 / seed
while seed < 10000000 do
	seed = seed * 1000
end
seed = seed - seed % 1
--print("Seed is: "..seed)
math.randomseed(seed)
--REALLY good seed made by rav3n_pl

function down(x)
	return x - x % 1
end

function ShuffleTable(tab) --randomize order of elements
	local cnt = #tab
	for i = 1, cnt do
		local r = math.random(cnt) -- not very convincing ! it gives always the same number on same puzzle
		tab[i],tab[r] = tab[r],tab[i]
	end
	return tab
end

function MixInwardTable(tab) -- 1234567 = 7254361 WARNING: if done twice, it returns to the original table
	local cnt = #tab -- 1234567 = 7254361; 123456 = 624351
	local mid = down(cnt / 2)
	--local adjust = 1 -- case of pair number of segments
	--local result = {}
	local result = tab -- in order to avoid any nil seg numbers (fixing a bug)
	local pair = true
	--if mid < cnt / 2 or mid == 1 then adjust = 0 end -- case of impair number of segments
	--for i = 1, mid - adjust do -- mid remains untouched if impair cnt
	for i = 1, mid do
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
	local result = {}
	result = Reverselist(InwardTable(tab))
	return result
end

-- Better to enable filter during setup => these scores will be reset after dialog
returnToOrigFilterSetting() -- any time score is calcultated on first read, this is verified (for filter bug)
bestScore = getScore()
startEnergyPerSegment = (segmentgetScore() - 8000) / segEnd
winnerSegment = 2 -- arbitrary

-- TO DO: Simplify output, and add more frequent 'no gain' messages (ie output something for every segment)
function SaveBest(seg)
	local s = getScore()
	local g = s - bestScore
	local WaitingTime = os.clock() --StartChrono
	if g > 0 then
		if g >= 0.001 then
			print("Gained " .. round(g) .. " points on segment " .. seg .. " scoring: " .. round(sscore) .. " (Total score: " .. s .. ")")
		elseif WaitingTime > 300 then
			StartChrono = os.clock()
			print("No gain up to segment " .. seg .."/" ..segEnd .. " (Score: " .. s .. ")")
		end
		bestScore = s
		save.Quicksave(3)
		if g > bestGain then
			bestGain = g
			winnerSegment = seg
		end
	end
end

function usableAA(sn)
	local usable = false -- To start, no segment is usable unless it satisfied one of the conditions below
	sscore = current.GetSegmentEnergyScore(sn)
	if sscore > minimo then
		return usable
	end
	if sscore < maximo then
		return usable
	end
	if doRebuild == true then
		selection.DeselectAll()
		selection.Select(sn)
		structure.RebuildSelected(2)
		usable = true
		return usable
	end
	if #useThat > 0 then
		for i = 1, #useThat do
			if sn == useThat[i] then
				usable = true
				break
			end
		end
	else
		if #useOnly > 0 then
			for i = 1, #useOnly do
				local ss = useOnly[i][1]
				local se = useOnly[i][2]
				for s = ss, se do
					if s == sn then
						usable = true
						break
					end
				end
			end
		else
			usable = true
			if #doNotUse > 0 then
				for i = 1, #doNotUse do
					local ss = doNotUse[i][1]
					local se = doNotUse[i][2]
					for s = ss, se do
						if s == sn then
							usable = false
							break
						end
					end
					if usable == false then
						break
					end
				end
			end
			if #skipAA > 0 then
				local aa = structure.GetAminoAcid(sn)
				for i = 1, #skipAA do
					if aa == skipAA[i] then
						usable = false
						break
					end
				end
			end
		end
	end
	local se = numSegments
	if endSegment ~= nil then
		se = endSegment
	end
	if sn < startSegment or sn > se then
		usable = false
	end
	return usable
end

function wiggle_out(seg)
	behavior.SetClashImportance(0.6)
	WiggleSimple(2,"wa")
	behavior.SetClashImportance(1.0)
	WiggleAT(seg)
	WiggleAT(seg,"s",1)
	behavior.SetClashImportance(0.6)
	WiggleAT(seg)
	behavior.SetClashImportance(1.0)
	WiggleAT(seg)
	FakeRecentBestRestore()
	SaveBest(seg)
end

function getNear(seg)
	if(getScore() < getTotalScore - 1000) then
		selection.Deselect(seg)
		behavior.SetClashImportance(0.75)
		--ds(1)
		WiggleSimple(1, "s")
		--structure.WiggleSelected(1,false,true)
		WiggleSimple(1, "ws")
		selection.Select(seg)
		behavior.SetClashImportance(1.0)
	end
	if(getScore() < getTotalScore - 1000) then
		if doFixBands == true then
			fixBands(seg)
		else
			FakeRecentBestRestore()
			SaveBest(seg)
			return false
		end
	end
	return true
end

function sidechainTweak(worklist)
	print("Pass 1 of 3: Sidechain tweak")
	worklist = worklist or workOnBIS
	--for i = segStart, segEnd do
	for j = 1, #worklist do
		local i = worklist[j]
		if usableAA(i) then
			selection.DeselectAll()
			selection.Select(i)
			local ss = getScore()
			getTotalScore = getScore()
			behavior.SetClashImportance(0)
			--ds(2)
			WiggleSimple(2, "s") -- changed to original 2 24/8/2017
			behavior.SetClashImportance(1.0)
			SelectSphere(i, sphereSize)
			if (getNear(i) == true) then
				wiggle_out(i)
			end
		end
	end
end

function sidechainTweakAround(worklist)
	print("Pass 2 of 3: Sidechain tweak around")
	--for i = segStart, segEnd do
	worklist = worklist or workOnBIS
	--for i = segStart, segEnd do
	for j = 1, #worklist do
		local i = worklist[j]
		if usableAA(i) then
			selection.DeselectAll()
			for n = 1, numSegments do
				listSegmentEnergyScore[n] = current.GetSegmentEnergyScore(n)
			end
			selection.Select(i)
			local ss = getScore()
			getTotalScore = getScore()
			behavior.SetClashImportance(0)
			--ds(2)
			WiggleSimple(2, "s") -- changed to original 2 24/8/2017
			behavior.SetClashImportance(1.0)
			SelectSphere(i, sphereSize)
			if(getScore() > getTotalScore - 30) then
				wiggle_out(i)
			else
				selection.DeselectAll()
				for n = 1, numSegments do
					if(current.GetSegmentEnergyScore(n) < listSegmentEnergyScore[n] - 1) then
						selection.Select(n)
					end
				end
				selection.Deselect(i)
				behavior.SetClashImportance(0.1)
				--ds(1)
				WiggleSimple(1, "s") -- new function BK 8/4/2013
				SelectSphere(i, sphereSize, true)
				behavior.SetClashImportance(1.0)
				if (getNear(i) == true) then
					wiggle_out(i)
				end
			end
		end
	end
end

-- debugged:
function sidechainManipulate(worklist)   -- negative scores avoided
	print("Last chance: bruteforce sidechain manipulate on best segments")
	maximo = maximo + 10 -- new BK 14/12/13 because rotamers need best segments
	worklist = worklist or workOnBIS
	for j = 1, #worklist do
		local i = worklist[j]
		if usableAA(i) then
			selection.DeselectAll()
			rotamers = rotamer.GetCount(i)
			save.Quicksave(4)
			if(rotamers > 1) then
				local ss = getScore()
				--print("Sgmnt: ", i," rotamers: ",rotamers, " Score= ", ss)
				for r = 1, rotamers do
					--print("Sgmnt: ", i," position: ",r, " Score= ", ss)
					save.Quickload(4)
					getTotalScore = getScore()
					rotamer.SetRotamer(i,r)
					behavior.SetClashImportance(1.0)
					if(getScore() > getTotalScore - 30) then
						SelectSphere(i,sphereSize)
						wiggle_out(i) -- this can change the number of rotamers
					end
					if rotamers > rotamer.GetCount(i) then
						break
					end --if nb of rotamers changed
				end
			end
		end
	recentbest.Restore()-- because rotamers can puzzle everything
	end
	maximo = maximo - 10 -- new BK 14/12/13 einitiaization of current maximo
end
-- end debugged

-- To be implemented via Dialog Box
-- Only segments that have to be used OVERRIDES all below
-- ie {18,150,151,205,320,322,359,361,425,432,433}
		--{382}
useThat = {}

-- Ranges that have to be used OVERRIDES BOTH LOWER OPTIONS
--ie 	{{12,24},
--		{66,66}}
useOnly = {}

 --Ranges that should be skipped
-- ie	{{55,58},
--		{12,33}}
doNotUse = {}

 -- AA codes to skip
 -- Default skiping Alanine and Glycine, as they have no sidechains (and therefore no rotamers)
skipAA = {'a', 'g',}

-- Option to easy set start and end of AT work to-- to be implemented in dialog
startSegment = 1 -- First segment
endSegment = nil --end of protein if nil
--END TO BE IMPLEMENTED VIA DIALOG BOX

includeWorstInSphere = false -- include worst segments in sphere
includeWorstInSphereValue = 0

function Run() -- this is the MAIN
	puzzleProperties()-- new BK 21/10/2013
	behavior.SetClashImportance(1.0)
	--recentbest.Restore()
	FakeRecentBestRestore()
	save.Quicksave(3)
	s1 = getScore()
	if tweek == true then
		StartChrono = os.clock()
		sidechainTweak()
		s2 = getScore()
		print("Tweak gain: ", round(s2 - s1))
	end
	if tweekAround == true then
		s2 = getScore()
		StartChrono = os.clock()
		sidechainTweakAround()
		s3 = getScore()
		print("Around gain: ", round(s3 - s2))
	end
		if manipulate == true then
		StartChrono = os.clock()
		s3 = getScore()
		sidechainManipulate()
		s4 = getScore()
		if s4 - s3 < 0 then
			FakeRecentBestRestore()
		end --against the bug !!!
		print("Manipulate gain: ", round(s4 - s3))
		end
		selection.SelectAll() -- or 2 lines in one structure.WiggleAll(4,true,true)
		WiggleSimple(2, "wa")
		WiggleSimple(2, "ws")
		selection.SelectAll()
		WiggleSimple(2, "wa")
		--recentbest.Restore()
		FakeRecentBestRestore()
		s5 = getScore()
		--print("Start score Loop ", loop,": ", round(s1))
		--print("Tweak gain: ", round(s2 - s1))
		--print("Around gain: ", round(s3 - s2))
		--print("Manipulate gain: ", round(s4 - s3))
		print("Total Acid gain Loop ", loop,": ", round(s5 - s1))
		--print("End score: ",r ound(s5))
end

sphereSize = 8
minimo = 600 -- score for working with worst segments. Don't use, usually worst segs have no rotts

if startEnergyPerSegment < -100 then
	maximo = -100 -- NEW BK 8/10/2013 (filters not considered here before dialog)
elseif startEnergyPerSegment < -5 then
	maximo = -50
elseif startEnergyPerSegment < 10 then
	maximo = -10
else
	maximo = 10
end

doMutate = false -- Don't use, very bad results yet (TODO)
doRebuild = true -- for very end in a puzzle, rebuild segment before tweak
doFixBands = false -- if you want to try with the worst segments
doFast = false

phases = 7 --Mode: (1)Tweek (2)Tweek around (3)Rotamers (4)1&2 (5)2&3 (6)1&3 (7)All
tweek = false
tweekAround = false
manipulate = false -- test rottamers

if probableFilter and not isContactMap and not isHydrogenBonds then
	filterManagement = true
end

function GetParam()
	local dlg = dialog.CreateDialog(scriptName)
	dlg.doFast = dialog.AddCheckbox("Fast mode (gain 25% less)", false)
	dlg.doFixBands = dialog.AddCheckbox("Fix geometry with bands when score breaks down", false)
	--dlg.manipulate = dialog.AddCheckbox("Brute force in phase 3", true)
	dlg.label0 = dialog.AddLabel("Mode: (1) Tweek (2) Tweek around (3) Rotamers")
	dlg.label01 = dialog.AddLabel("      (4) 1&2 (5) 2&3 (6) 1&3 (7) All")
	dlg.phases = dialog.AddSlider("Mode: ", phases, 0, 7, 0)
	dlg.includeWorstInSphere = dialog.AddCheckbox("Include worst segments in sphere", false)
	dlg.doRebuild = dialog.AddCheckbox("Rebuild before search rotts, for very end only", true)
	dlg.segStart = dialog.AddTextbox("From seg ", segStart)
	dlg.segEnd = dialog.AddTextbox("To seg ", segEnd)
	if flagLigand then
		textligand = ("Ligand is seg nb. " .. segEnd + 1)
		dlg.l1aaaa = dialog.AddLabel(textligand)
	end
	dlg.l1aaa = dialog.AddLabel("1=up; 2=back; 3=random; 4=out; 5=in; 6=slice")
	dlg.mixtables = dialog.AddSlider("Order: ", mixtables, 1, 6, 0)
	dlg.label1 = dialog.AddLabel("Skip segments scoring less than: ")
	dlg.maximo = dialog.AddSlider("min pts/seg: ",maximo, -100, 30, 0)
	--dlg.minimo = dialog.AddSlider("more than",minimo,30,600,0)
	if probableFilter then
		dlg.filterManagement = dialog.AddCheckbox("Disable filter during wiggle", filterManagement) -- default true
		dlg.genericFilter = dialog.AddCheckbox("Always disable filter, unless for scoring", genericFilter) -- default false
		dlg.doMutate = dialog.AddCheckbox("Mutate, no shake", doMutate) -- default false (it's not recommended)
	end
	dlg.ok = dialog.AddButton("OK", 1)
	dlg.cancel = dialog.AddButton("Cancel", 0)
	if dialog.Show(dlg) > 0 then
		doFast = dlg.doFast.value
		doFixBands = dlg.doFixBands.value
		--manipulate = dlg.manipulate.value
		phases = dlg.phases.value
		print("Mode =" .. phases)
		includeWorstInSphere = dlg.includeWorstInSphere.value
		doRebuild = dlg.doRebuild.value
		segStart = dlg.segStart.value
		segEnd = dlg.segEnd.value
		--minimo = dlg.minimo.value
		maximo = dlg.maximo.value
		if probableFilter then
			genericFilter = dlg.genericFilter.value
			filterManagement = dlg.filterManagement.value
			doMutate = dlg.doMutate.value
		end
		if genericFilter then
			filterManagement = false -- because reduntant and to avoid enabling filters after wiggles
			mutateClass(structure, false) -- genericFilter bug: should be turned true again ASAP
			mutateClass(band, false)
			mutateClass(current, true)
			mutateClass(recentbest, true)
			mutateClass(save, true)
			print("Always disable filter, unless for scoring")
		end
		if filterManagement then
			print("Disable filter during wiggle")
		end
		-- Actions
		if phases == 1 or phases == 4 or phases > 5 then
			tweek = true
		end
		if phases == 2 or phases == 4 or phases ==5 or phase == 7 then
			tweekAround = true
		end
		if phases == 3 or phases > 4 then
			manipulate = true
		end
		--For MIXTABLES
		mixtables = dlg.mixtables.value
		workOnBIS = {} -- reset / the table to use is a simple list of segments in any order
		local counterVar = 0
		for i = segStart, segEnd do -- basic list of segments (reset of workOnBIS)
			counterVar = counterVar + 1
			workOnBIS[counterVar] = i
		end
		if mixtables == 2 then
			workOnBIS = Reverselist(workOnBIS)
			print("Backward walk")
		elseif mixtables == 3 then
			randomly = true
			workOnBIS = ShuffleTable(workOnBIS)
			print("Random walk")
		elseif mixtables == 4 then
			workOnBIS = OutwardTable(workOnBIS)
			print("Outward walk")
		elseif mixtables == 5 then
			workOnBIS = InwardTable(workOnBIS)
			print("Inward walk")
		elseif mixtables == 6 then
			workOnBIS = MixInwardTable(workOnBIS)
			print("Slice walk")
		end -- else normal from first to last in the list

		return true
	end
	return false
end

--It's only here that genericFilter starts to make effect !!
if GetParam() == false then
	return
end

--recentbest.Save() -- filter enabled ? NO because of Foldit BUG.
FakeRecentBestSave() -- should work properly on all situations

initialScore = getScore() -- ok filter enabled here
print("Acid Tweeker starting at score: " .. initialScore) -- note: if genericFilter, always on !!
if filter.AreAllEnabled() then
	print("... without the filters")
end
bestScore = getScore() -- for savebest, reset with default genericFilter parameters (filter enabled or not)

loop = 0
hop = 0

function main()
	while(true) do
		print("")
		local startLoopTime = os.clock()
		local startLoopScore = getScore()
		loop = loop + 1
		if loop == 2 then
			if not manipulate then
				manipulate = true
				print("Upgrading options: Adding manipulate-----")
			end
		end
		if loop == 3 then
			if not doFixBands then
				doFixBands = true
				print("Upgrading options: Adding Fixing bands----------")
			end
		end
		if loop == 4 then
			if doFast then
				doFast = false
				print("Upgrading options: Disabling doFast----------")
			end
			if probableFilter and doMutate then
				doMutate = false
				print("Upgrading options: Disabling mutate----------")
			end
		end
		if loop == 5 then
			if not doRebuild then
				doRebuild = true
				print("Upgrading options: Adding Rebuild before manipulate---------")
			end
		end
		if loop == 6 then
			if not includeWorstInSphere then
				includeWorstInSphere = true
				print("Upgrading options: Adding sphere-----------")
			end
		end
		if loop == 7 then
			if doFixBands then
				doFixBands = false
				print("Upgrading options: No Fixing bands----------")
			end
		end
		--hop = hop + 1
		print("Loop ", loop, "Options:")
		print("Fast =", doFast,", Fix Bands =", doFixBands, ", Manipulate =", manipulate .. ",")
		print("Rebuild =", doRebuild, ", Worst in Sphere =", includeWorstInSphere, ", Segments =", segStart .. "-" .. segEnd)
		print("Use only segments scoring at least", maximo, "pts")
		if probableFilter then
			print("Mutate =", doMutate, ", Generic Filter =", genericFilter)
			print("Filter Management=", filterManagement)
		end
			print("")
		bestGain = 0
		Run()
		print("Best gain this loop: ", bestGain," pts on seg ", winnerSegment)
		local stopLoopTime = os.clock()
		local stopLoopScore = getScore()
		print("This loop gained", round( stopLoopScore S startLoopScore) .." in " .. round(stopLoopTime - startLoopTime) / 60 .. " minutes")
		--if minimo < 600 then minimo = minimo + 10 end -- good scoring segs will gain much with at
		maximo = maximo - 10 -- worst scoring segs will not gain with at, but if you've so much time, ok we try
		print("Total Gain: ", round(getScore() - initialScore), "Score:", round(getScore()), "Start Score: ", round(initialScore))
		print("CPU time =", round((stopLoopTime - startRecTime) / 60) .." minutes")
	end
end

function cleanup(err)
	start, stop, line, msg = err:find(":(%d+):%s()")
	err = err:sub(msg, #err)
	if err:find('Cancelled') ~= nil then
		print("Cancelled")
	else
		print("Unexpected error detected")
		print("Error line:", line)
		print("Error:", err)
	end
	--recentbest.Restore()
	FakeRecentBestRestore()
	behavior.SetClashImportance(1.0)
	returnToOrigFilterSetting()
end

xpcall(main, cleanup)
