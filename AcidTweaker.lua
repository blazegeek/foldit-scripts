scriptName ="Acid Tweaker"
scriptVersion = 2.8.1
scriptBuild = 3

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
	print("Filter disabled on start... is that intended?")
	local function checkUserFilterPrefDialog()
		local dlg = dialog.CreateDialog("Are you sure?")
		dlg.L1 = dialog.AddLabel("Filter disabled on start... is that intended?")
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

function trunc(x)
	--return x - x % 1
	return math.floor(x * 1000) / 1000
end

function round(x)
	return x - x % 0.001
end

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

function copyTable(orig)
	local copy = {}
	for originalKey, originalValue in pairs(orig) do
		copy[originalKey] = originalValue
	end
	return copy
end

function setFiltersOn()
	if filter.AreAllEnabled() then
		filter.EnableAll()
	end
end

function setFiltersOff()
	if not filter.AreAllEnabled() then
		filter.DisableAll()
	end
end

function mutateFunction(func)
	local currentFunction = func
	local function mutateFunc(func, newfunc)
		local lastFunction = currentFunction
		currentFunction = function(...)
			return newfunc(lastFunction, ...)
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
	myClassCopy[numClassesCopied] = copyTable(theClass)
	local myClass = myClassCopy[numClassesCopied]
	for originalKey, originalValue in pairs(theClass) do
		myFunc, mutateFunc = mutateFunction(myClass[originalKey])
		if withFilters == true then
			mutateFunc(myFunc, function(...)
				setFiltersOn()
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
				setFiltersOff()
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
	local puzzleTitle = puzzle.GetName()
	if #puzzleTitle > 0 then
		for i = 1, #badPuzzle do
			if puzzleTitle:find(i) then -- check if not bizarre puzzle
			notImplemented = true
			end
		end
		if (puzzleTitle:find("Sym") or puzzleTitle:find("Symmetry") or puzzleTitle:find("Symmetric")
				or puzzleTitle:find("Dimer") or puzzleTitle:find("Trimer") or puzzleTitle:find("Tetramer")
				or puzzleTitle:find("Pentamer")) then
			probableSymmetry = true
			if puzzleTitle:find("Dimer") and not puzzleTitle:find("Dimer of Dimers") then sym = 2
			elseif puzzleTitle:find("Trimer") or puzzleTitle:find("Tetramer") then sym = 3
			elseif puzzleTitle:find("Dimer of Dimers") or puzzleTitle:find("Tetramer") then sym = 4
			elseif puzzleTitle:find("Pentamer") then sym = 5
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
	if #puzzleTitle > 0 and puzzleTitle:find("Sepsis") then
		isSepsis = true
	end
	if #puzzleTitle > 0 and puzzleTitle:find("Electron Density") then
		isElectronDensity = true
	end
	if #puzzleTitle > 0 and puzzleTitle:find("Centroid") then
		--print(true,"-Centroid")
		isCentroid = true
	end
	if #puzzleTitle > 0 and puzzleTitle:find("Contacts") then
		isContactMap = true
	end
	if #puzzleTitle > 0 and puzzleTitle:find("H-Bonds") then
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
function fakeRecentBestSave()
	if probableFilter then
		save.Quicksave(11)
	else
		recentbest.Save()
	end
end

-- Is this still a necessary bugfix?
function fakeRecentBestRestore()
	if probableFilter then
		local scoreBefore = getScore()
		recentbest.Restore()
		local scoreAfter = getScore()
		if scoreAfter > scoreBefore then
			save.Quicksave(11)
		end
		save.Quickload(11)
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

function wiggleSimple(val, how)
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

function wiggleAT(ss, how, iters, minppi)
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
		wiggleSimple(val, how)
		local checkEndScore = getScore()
		local interimGain = checkEndScore - checkStartScore
		if how ~= "s" then
			if interimGain > minppi then
				wiggleAT(ss, how, iters, minppi)
			end
		end
	end
end

function selectSphere(currentSegment, radius, nodeselect)
	if nodeselect ~= true then
		selection.DeselectAll()
	end
	for i = 1, numSegments do
		if structure.GetDistance(currentSegment, i) < radius then
			selection.Select(i)
		end
		if includeWorstInSphere == true then
			if current.GetSegmentEnergyScore(i) < includeWorstInSphereValue then
				selection.Select(i)
			end
		end
	end
end

function fixBands(currentSegment)
	if doFixBands == true then
		local numBands = 1
		for i = 1, numSegments do
			checkDistance = structure.GetDistance(currentSegment, i)
			if checkDistance < 12 and checkDistance > 6 then
				local cband = band.GetCount()
				band.AddBetweenSegments(currentSegment, i)
				if cband < band.GetCount() then
					band.SetGoalLength(numBands, checkDistance)
					numBands = numBands + 1
				end
			end
		end
		wiggleSimple(1, "wa")
		band.DeleteAll()
	end
end

-- Really good seed made by rav3n_pl
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

function shuffleTable(tab) -- Randomize order of elements
	local cnt = #tab
	for i = 1, cnt do
		local r = math.random(cnt) -- Not very convincing: it gives always the same number on same puzzle
		tab[i],tab[r] = tab[r],tab[i]
	end
	return tab
end

function mixInwardTable(tab) -- 1234567 = 7254361 WARNING: if done twice, it returns to the original table
	local cnt = #tab -- 1234567 = 7254361; 123456 = 624351
	local mid = trunc(cnt / 2)
	local result = tab -- in order to avoid any nil segment numbers (fixing a bug)
	local pair = true
	for i = 1, mid do
		pair = not pair
		if pair then
			result[i], result[cnt + 1 - i] = tab[i], tab[cnt + 1 - i] -- pair segs are kept untouched
		else
			result[i], result[cnt + 1 - i] = tab[cnt + 1 - i], tab[i] -- impairs segs are shifted (loop starts with last segment)
		end
	end
	return result
end

function inwardTable(tab) -- 1234567 = 7162534 WARNING: if done twice, it mixes everything like a feuillete bakery
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
			result[i] = tab[cnt] -- impairs segs are taken from end (loop starts with last segment)
			cnt = cnt - 1
		end
	end
	return result
end

function reverseList(tab) -- 1234567 = 7654321
	local cnt = #tab
	local result = {}
	for i = 1, #tab do -- simply inverts the table 7162534 = 4536271
		result[i] = tab[cnt + 1 - i]
	end
	return result
end

function outwardTable(tab) --1234567 = 4352617
	local result = {}
	result = reverseList(inwardTable(tab))
	return result
end

-- Better to enable filter during setup => these scores will be reset after dialog
returnToOrigFilterSetting() -- any time score is calcultated on first read, this is verified (for filter bug)
bestScore = getScore()
startEnergyPerSegment = (segmentgetScore() - 8000) / segEnd
winnerSegment = 2 -- arbitrary

-- TO DO: Simplify output, and add more frequent 'no gain' messages (ie output something for every segment)
function saveBest(currentSegment)
	local score = getScore()
	local gain = score - bestScore
	local WaitingTime = os.clock() --StartChrono
	if gain > 0 then
		if gain >= 0.001 then
			print("Gained " .. round(g) .. " points on segment " .. currentSegment .. " scoring: " .. round(segmentScore) .. " (Total score: " .. score .. ")")
		elseif WaitingTime > 300 then
			StartChrono = os.clock()
			print("No gain up to segment " .. currentSegment .."/" ..segEnd .. " (Score: " .. s .. ")")
		end
		bestScore = score
		save.Quicksave(3)
		if gain > bestGain then
			bestGain = gain
			winnerSegment = currentSegment
		end
	end
end

function usableAA(segmentNumber)
	local usable = false -- To start, no segment is usable unless it satisfied one of the conditions below
	segmentScore = current.GetSegmentEnergyScore(segmentNumber)
	if segmentScore > minSegScore then
		return usable
	end
	if segmentScore < maxSegScore then
		return usable
	end
	if doRebuild == true then
		selection.DeselectAll()
		selection.Select(segmentNumber)
		structure.RebuildSelected(2)
		usable = true
		return usable
	end
	if #useThat > 0 then
		for i = 1, #useThat do
			if segmentNumber == useThat[i] then
				usable = true
				break
			end
		end
	else
		if #useOnly > 0 then
			for i = 1, #useOnly do
				local startSegment = useOnly[i][1]
				local endSegment = useOnly[i][2]
				for checkSegment = startSegment, endSegment do
					if checkSegment == segmentNumber then
						usable = true
						break
					end
				end
			end
		else
			usable = true
			if #doNotUse > 0 then
				for i = 1, #doNotUse do
					local startSegment = doNotUse[i][1]
					local endSegment = doNotUse[i][2]
					for checkSegment = startSegment, endSegment do
						if checkSegment == segmentNumber then
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
				local currentAminoAcid = structure.GetAminoAcid(segmentNumber)
				for i = 1, #skipAA do
					if currentAminoAcid == skipAA[i] then
						usable = false
						break
					end
				end
			end
		end
	end
	local endSegment = numSegments
	if endSegment ~= nil then
		endSegment = endSegment
	end
	if segmentNumber < startSegment or segmentNumber > endSegment then
		usable = false
	end
	return usable
end

function wiggle_out(currentSegment)
	behavior.SetClashImportance(0.6)
	wiggleSimple(2, "wa")
	behavior.SetClashImportance(1.0)
	wiggleAT(currentSegment)
	wiggleAT(currentSegment, "s", 1)
	behavior.SetClashImportance(0.6)
	wiggleAT(currentSegment)
	behavior.SetClashImportance(1.0)
	wiggleAT(currentSegment)
	fakeRecentBestRestore()
	saveBest(currentSegment)
end

function getNear(currentSegment)
	if(getScore() < getTotalScore - 1000) then
		selection.Deselect(currentSegment)
		behavior.SetClashImportance(0.75)
		--ds(1)
		wiggleSimple(1, "s")
		--structure.WiggleSelected(1,false,true)
		wiggleSimple(1, "ws")
		selection.Select(currentSegment)
		behavior.SetClashImportance(1.0)
	end
	if(getScore() < getTotalScore - 1000) then
		if doFixBands == true then
			fixBands(currentSegment)
		else
			fakeRecentBestRestore()
			saveBest(currentSegment)
			return false
		end
	end
	return true
end

function sidechainTweak(worklist)
	print("Pass 1 of 3: Sidechain Tweak")
	worklist = worklist or workOnBIS
	for j = 1, #worklist do
		local i = worklist[j]
		if usableAA(i) then
			selection.DeselectAll()
			selection.Select(i)
			local startScore = getScore()
			getTotalScore = getScore()
			behavior.SetClashImportance(0)
			--ds(2)
			wiggleSimple(2, "s")
			behavior.SetClashImportance(1.0)
			selectSphere(i, sphereSize)
			if (getNear(i) == true) then
				wiggle_out(i)
			end
		end
	end
end

function sidechainTweakAround(worklist)
	print("Pass 2 of 3: Sidechain Tweak Around")
	worklist = worklist or workOnBIS
	for j = 1, #worklist do
		local i = worklist[j]
		if usableAA(i) then
			selection.DeselectAll()
			for n = 1, numSegments do
				listSegmentEnergyScore[n] = current.GetSegmentEnergyScore(n)
			end
			selection.Select(i)
			local startScore = getScore()
			getTotalScore = getScore()
			behavior.SetClashImportance(0)
			--ds(2)
			wiggleSimple(2, "s")
			behavior.SetClashImportance(1.0)
			selectSphere(i, sphereSize)
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
				wiggleSimple(1, "s")
				selectSphere(i, sphereSize, true)
				behavior.SetClashImportance(1.0)
				if (getNear(i) == true) then
					wiggle_out(i)
				end
			end
		end
	end
end

function sidechainManipulate(worklist)   -- negative scores avoided
	print("Last chance: bruteforce sidechain doManipulate on best segments")
	maxSegScore = maxSegScore + 10
	worklist = worklist or workOnBIS
	for j = 1, #worklist do
		local i = worklist[j]
		if usableAA(i) then
			selection.DeselectAll()
			rotamers = rotamer.GetCount(i)
			save.Quicksave(4)
			if(rotamers > 1) then
				local startScore = getScore()
				--print("Sgmnt: " .. i .. " rotamers: " .. rotamers .. " Score =  " .. startScore)
				for r = 1, rotamers do
					--print("Sgmnt: " .. i .. " position: " .. r ..  " Score = " .. startScore)
					save.Quickload(4)
					getTotalScore = getScore()
					rotamer.SetRotamer(i, r)
					behavior.SetClashImportance(1.0)
					if(getScore() > getTotalScore - 30) then
						selectSphere(i,sphereSize)
						wiggle_out(i) -- this can change the number of rotamers
					end
					if rotamers > rotamer.GetCount(i) then
						break
					end --if number of rotamers changed
				end
			end
		end
	recentbest.Restore()
	end
	maxSegScore = maxSegScore - 10
end

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
startSegment = 1
endSegment = numSegments -- or maybe numSegments2, until that code is simplified
--endSegment = nil --end of protein if nil -- this seems needlessly convoluted

includeWorstInSphere = false -- include worst segments in sphere
includeWorstInSphereValue = 0

function run()
	puzzleProperties()
	behavior.SetClashImportance(1.0)
	fakeRecentBestRestore()
	save.Quicksave(3)
	scoreStart = getScore()
	if doTweek == true then
		StartChrono = os.clock()
		sidechainTweak()
		interimScoreA = getScore()
		print("Tweak gain: ", round(interimScoreA - scoreStart))
	end
	if doTweekAround == true then
		interimScoreA = getScore()
		StartChrono = os.clock()
		sidechainTweakAround()
		interimScoreB = getScore()
		print("Tweak Around gain: ", round(interimScoreB - interimScoreA))
	end
	if doManipulate == true then
		StartChrono = os.clock()
		interimScoreB = getScore()
		sidechainManipulate()
		interimScoreC = getScore()
		if interimScoreC - interimScoreB < 0 then
			fakeRecentBestRestore()
		end
		print("Manipulate gain: ", round(interimScoreC - interimScoreB))
	end
	selection.SelectAll()
	wiggleSimple(2, "wa")
	wiggleSimple(2, "ws")
	selection.SelectAll()
	wiggleSimple(2, "wa")
	fakeRecentBestRestore()
	scoreEnd = getScore()
	--print("Start score Loop ", loop,": ", round(scoreStart))
	--print("Tweak gain: ", round(interimScoreA - scoreStart))
	--print("Around gain: ", round(interimScoreB - interimScoreA))
	--print("Manipulate gain: ", round(interimScoreC - interimScoreB))
	print("Total Acid gain Loop ", loop,": ", round(scoreEnd - scoreStart))
	--print("End score: ",r ound(scoreEnd))
end

sphereSize = 8
minSegScore = 600 -- score for working with worst segments. Don't use, usually worst segs have no rotts

if startEnergyPerSegment < -100 then
	maxSegScore = -100
elseif startEnergyPerSegment < -5 then
	maxSegScore = -50
elseif startEnergyPerSegment < 10 then
	maxSegScore = -10
else
	maxSegScore = 10
end

doMutate = false -- Don't use, very bad results yet (TODO)
doRebuild = true -- For very end of puzzle; rebuild segment before tweak
doFixBands = false -- If you want to try with the worst segments
doFast = false

modePhases = 7 -- Mode: (1) Tweek (2) Tweek Around (3) Manipulate Rotamers (4) 1 & 2 (5) 2 & 3 (6) 1 & 3 (7) All
doTweek = false
doTweekAround = false
doManipulate = false -- test rottamers

if probableFilter and not isContactMap and not isHydrogenBonds then
	filterManagement = true
end

function getParameters()
	local dlg = dialog.CreateDialog(scriptName)
	dlg.doFast = dialog.AddCheckbox("Fast Mode (gain 25% less)", false)
	dlg.doFixBands = dialog.AddCheckbox("Fix geometry with bands when score breaks down", false)
	--dlg.doManipulate = dialog.AddCheckbox("Brute force in phase 3", true)
	dlg.labelModeSelectA = dialog.AddLabel("Mode: (1) Tweek (2) Tweek Around (3) Manipulate Rotamers")
	dlg.labelModeSelectB = dialog.AddLabel("(4) 1 & 2", "(5) 2 & 3", "(6) 1 & 3", "(7) All")
	dlg.modePhases = dialog.AddSlider("Mode: ", modePhases, 0, 7, 0)
	dlg.includeWorstInSphere = dialog.AddCheckbox("Include worst segments in sphere", false)
	dlg.doRebuild = dialog.AddCheckbox("Rebuild before search rotamers. For very end only", true)
	dlg.segStart = dialog.AddTextbox("From segment ", segStart)
	dlg.segEnd = dialog.AddTextbox("To segment ", segEnd)
	if flagLigand then
		dlg.labelLigand = dialog.AddLabel("Ligand is segment:  " .. segEnd + 1)
		--textligand = ("Ligand is segment:  " .. segEnd + 1)
		--dlg.l1aaaa = dialog.AddLabel(textligand)
	end
	dlg.labelOrder = dialog.AddLabel("(1) Up", "(2) Back", "(3) Random", "(4) Out", "(5) In", "(6) Slice")
	dlg.mixtables = dialog.AddSlider("Order: ", mixtables, 1, 6, 0)
	dlg.labelSkipSemgents = dialog.AddLabel("Skip segments scoring less than: ")
	dlg.maxSegScore = dialog.AddSlider("Min points/segment: ",maxSegScore, -100, 30, 0)
	--dlg.minSegScore = dialog.AddSlider("more than",minSegScore,30,600,0)
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
		--doManipulate = dlg.doManipulate.value
		modePhases = dlg.modePhases.value
		print("Mode =" .. modePhases)
		includeWorstInSphere = dlg.includeWorstInSphere.value
		doRebuild = dlg.doRebuild.value
		segStart = dlg.segStart.value
		segEnd = dlg.segEnd.value
		--minSegScore = dlg.minSegScore.value
		maxSegScore = dlg.maxSegScore.value
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
		if modePhases == 1 or modePhases == 4 or modePhases > 5 then
			doTweek = true
		end
		if modePhases == 2 or modePhases == 4 or modePhases ==5 or phase == 7 then
			doTweekAround = true
		end
		if modePhases == 3 or modePhases > 4 then
			doManipulate = true
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
			workOnBIS = reverseList(workOnBIS)
			print("Backward Walk")
		elseif mixtables == 3 then
			randomly = true
			workOnBIS = shuffleTable(workOnBIS)
			print("Random Walk")
		elseif mixtables == 4 then
			workOnBIS = outwardTable(workOnBIS)
			print("Outward Walk")
		elseif mixtables == 5 then
			workOnBIS = inwardTable(workOnBIS)
			print("Inward Walk")
		elseif mixtables == 6 then
			workOnBIS = mixInwardTable(workOnBIS)
			print("Sliceward Walk")
		end -- else normal from first to last in the list

		return true
	end
	return false
end

--It's only here that genericFilter starts to make effect !!
if getParameters() == false then
	return
end

--recentbest.Save() -- filter enabled ? NO because of Foldit BUG.
fakeRecentBestSave() -- should work properly on all situations

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
			if not doManipulate then
				doManipulate = true
				print("Upgrading options: Adding doManipulate-----")
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
				print("Upgrading options: Adding Rebuild before doManipulate---------")
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
		print("Fast =", doFast,", Fix Bands =", doFixBands, ", Manipulate =", doManipulate .. ",")
		print("Rebuild =", doRebuild, ", Worst in Sphere =", includeWorstInSphere, ", Segments =", segStart .. "-" .. segEnd)
		print("Use only segments scoring at least", maxSegScore, "points")
		if probableFilter then
			print("Mutate =", doMutate, ", Generic Filter =", genericFilter)
			print("Filter Management=", filterManagement)
		end
			print("")
		bestGain = 0
		run()
		print("Best gain this loop: ", bestGain," points on segment ", winnerSegment)
		local stopLoopTime = os.clock()
		local stopLoopScore = getScore()
		print("This loop gained", round( stopLoopScore S startLoopScore) .." in " .. round(stopLoopTime - startLoopTime) / 60 .. " minutes")
		--if minSegScore < 600 then minSegScore = minSegScore + 10 end -- good scoring segs will gain much with at
		maxSegScore = maxSegScore - 10 -- worst scoring segs will not gain with at, but if you've so much time, ok we try
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
	fakeRecentBestRestore()
	behavior.SetClashImportance(1.0)
	returnToOrigFilterSetting()
end

xpcall(main, cleanup)
