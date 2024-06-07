scriptName = "SD Multiwalk Forever 2.6.1"
buildNumber = 3

--TO DO: Make each walker function user-selected. Toggle on/off any particular walker(s).

-- this function isn't even used
function round(x)
	return x - x % 0.001
end

function trunc(x)
	return x - x % 1
end

-- TO DO: Update and simplify this function to use current.GetEnergyScore()
function score()
	s = current.GetScore()
		if s == 0 then
			for i = 1, numSegments do
				s = s + current.GetSegmentEnergyScore(i)
			end
			s = s + 8000
		end
	return s
end

function printElapsedTime()
	timeElapsed = os.time() - timeCycleStart
	seconds = timeElapsed % 60
	minutes = ((timeElapsed - seconds) % (60 * 60)) / 60
	hours = (timeElapsed - minutes * 60 - seconds) / 3600
	print(string.format("Elapsed time: %ih %02im %02is at %s", hours, minutes, seconds, os.date()))
end

function deleteBands()
	numBands = band.GetCount()
	if numBands > userBands then
		for i = numBands, userBands + 1, -1 do
			band.Delete(i)
		end
	end
end

function setAllLoops() -- This is the more complicated version of the function
	local ok = false
	for i = 1, numSegments do
		local ss = structure.GetSecondaryStructure(i)
		if ss ~= "L" then
			save.SaveSecondaryStructure()
			ok = true
			break
		end
	end
	if ok then
		selection.SelectAll()
		structure.SetSecondaryStructureSelected("L")
	end
end

-- this seems an unnecessarily clumsy way to print some info
function startWalker(loop, step, total, script, from, startNum, to, howmany)
	local loop = loop or ""
	local step = step or ""
	local total = total or ""
	local script = script or "unknown"
	local from = " from " or ""
	local startNum = startNum or ""
	local to = " to " or ""
	local howmany = howmany or ""
	if startNum == "" then
		from = ""
		to = ""
		howmany =""
	end
	print(loop .. "(" .. step .. "/" .. total .. ") Starting " .. script .. from .. startNum .. to .. howmany .. " ...")
end -- function startWalker(...)

function theKrogWalker4(scoreThreshold)
	-- Krog recommends 1-4.
	minWiggleSegments = 1
	maxWiggleSegments = 4
	-- Krog recommends 0.01 for early, 0.001 mid and 0.0001 late - get all you can!
	doGlobalWiggle = false
	runForever = false

	function wiggleWalk(sectionSize, scoreThreshold, global)
		totalGain = 0
		recentbest.Restore()
		behavior.SetClashImportance(1)
		selection.DeselectAll()
		freeze.UnfreezeAll()
		for i = 1, sectionSize - 1 do
			selection.Select(i)
		end
		for i = sectionSize, numSegments do
			selection.Select(i)
			gain = scoreThreshold
			while gain >= scoreThreshold do
				lastScore = current.GetScore()
				if global then
					structure.LocalWiggleAll(40 / sectionSize)
				else
					structure.LocalWiggleSelected(8)
					recentbest.Restore()
				end
				gain = current.GetScore() - lastScore
				totalGain = totalGain + gain
			end
			selection.Deselect(i - sectionSize + 1)
		end
	end

	runCondition = true
	while runCondition do
		runCondition = runForever
		for j = minWiggleSegments, maxWiggleSegments do
			wiggleWalk(j, scoreThreshold, doGlobalWiggle)
		end
	end
end -- function theKrogWalker4(scoreThreshold)

function theM3WiggleSequence(scoreThreshold)
	doWiggleSidechains = 0
	doShakeSidechains = 0
	wiggleCycles = 5
	maxIterations = 10
	maxWiggle = 5
	initialScore = current.GetScore()
	save.Quicksave(10)
	recentbest.Restore()
	for seq = 1, maxWiggle do
		for sel = 1, (numSegments - seq) do
			selection.DeselectAll()
			for group = 0, seq do
				selection.Select(sel + group)
			end
			scoreBefore = current.GetScore()
			scoreStart = scoreBefore
			scoreAfter = scoreBefore
			structure.LocalWiggleSelected(wiggleCycles)
			if (doShakeSidechains == 1) then
				structure.ShakeSidechainsSelected(1)
			end
			if (doWiggleSidechains == 1) then
				structure.WiggleAll(1,false,true)
			end
			scoreAfter = current.GetScore()
			iterationCount = 0
			while( ((scoreAfter - scoreBefore) > scoreThreshold) and (iterationCount < maxIterations)) do
				recentbest.Restore()
				scoreBefore = scoreAfter
				structure.LocalWiggleSelected(wiggleCycles)
				scoreAfter = current.GetScore()
				if ((scoreAfter - scoreBefore) > scoreThreshold) then
					recentbest.Restore()
				else
					recentbest.Restore()
				end
				iterationCount = iterationCount + 1
			end
			if (doShakeSidechains == 1) then
				structure.ShakeSidechainsSelected(1)
			end
			if (doWiggleSidechains == 1) then
				structure.WiggleAll(1, false, true)
			end
			if ((current.GetScore() - scoreStart) > scoreThreshold) then
			end
			recentbest.Restore()
		end
	end
end -- function theM3WiggleSequence(scoreThreshold)

function theMoonWalker(scoreThreshold)
	function reset_protein()
		behavior.SetClashImportance(1)
		selection.DeselectAll()
		freeze.UnfreezeAll()
	end

	function wiggle_it_out(wiggleParams)
		selection.DeselectAll()
		selection.SelectAll()
		structure.WiggleAll(wiggleParams.sideChain_count, false, true)
		structure.ShakeSidechainsSelected(wiggleParams.shake)
		structure.LocalWiggleAll(wiggleParams.all_count)
		recentbest.Restore()
	end

	function do_the_local_wiggle_campon(first, last, wiggleParams)
		selection.DeselectAll()
		if last > numSegments then
			last = numSegments
		end
		selection.SelectRange(first, last)
		local endScore = score()
		local points_increased = false
		local beginningScore = endScore
		repeat
			startScore = endScore
			structure.LocalWiggleSelected(wiggleParams.local_wiggle)
			recentbest.Restore()
			endScore = score()
		until endScore < startScore + wiggleParams.local_tolerance
		if beginningScore + wiggleParams.local_tolerance < endScore then
			points_increased = true
		end
		return points_increased
	end

	function step_wiggle(start, finish, wiggleParams)
		local i
		local reset
		local reWiggleIncrement = 1
		local reWiggleScore = score() + reWiggleIncrement
		i = start
		while i <= finish do
			local j
			local savedChanged
			local points_changed = false
			for j = 1, 3 do
				savedChanged = do_the_local_wiggle_campon(i, i + j - 1, wiggleParams)
				if savedChanged then
					points_changed = true
				end
			end
			if points_changed then
				reset = i - 1
				if reset < start then
					reset = start
				end
				for j = 1, 3 do
					do_the_local_wiggle_campon(reset, reset + j - 1, wiggleParams)
				end
				reset = reset + 1
				if reset <= i then
					for j = 1, 3 do
						do_the_local_wiggle_campon(reset, reset + j - 1, wiggleParams)
					end
				end
			end
			local new_score = score()
			if new_score > reWiggleScore then
				wiggle_it_out(wiggleParams)
				reWiggleScore = new_score + reWiggleIncrement
			end
			i = i + 1
		end
	end

	reset_protein()
	recentbest.Restore()
	wiggleParams = {}
	wiggleParams.local_wiggle = 12
	wiggleParams.local_tolerance = scoreThreshold
	wiggleParams.sideChain_count = 15
	wiggleParams.shake = 5
	wiggleParams.all_count = 15
	step_wiggle(1, numSegments, wiggleParams)
end -- function theMoonWalker(scoreThreshold)

function thePiWalkerCampon2(scoreThreshold)
	function mynextmode(number, maximum)
		number = number + 1
		if number > maximum then
			number = 1
		end
		return number
	end

	function rotate_pattern(patternList)
		local last = #patternList
		local i
		if last > 1 then
			local patternSave = patternList[1]
			for i = 1, last do
				patternList[i]  = patternList[i+1]
			end
			patternList[last] = patternSave
		end
		return patternList
	end

	function unfreeze_protein()
		freeze.UnfreezeAll()
	end

	function freeze_segments(start_index, patternList)
		unfreeze_protein()
		local patternLength = #patternList
		local currentSegment = start_index
		local currentPattern = 1
		selection.DeselectAll()
		while currentSegment < numSegments do
			selection.Select(currentSegment)
			currentSegment = currentSegment + patternList[currentPattern]
			currentPattern = mynextmode(currentPattern,patternLength)
		end
		freeze.FreezeSelected(true,true)
	end

	function do_the_local_wiggle_campon(first, last, wiggleParams)
		selection.DeselectAll()
		selection.SelectRange(first,last)
		local endScore = score()
		local points_increased = false
		local beginningScore = endScore
		repeat
			startScore = endScore
			structure.LocalWiggleSelected(wiggleParams.local_wiggle)
			recentbest.Restore()
			endScore = score()
		until endScore < startScore + wiggleParams.local_campon_tolerance
		if beginningScore + wiggleParams.local_campon_tolerance < endScore then
			points_increased = true
		end
		--recentbest.Restore()
		return points_increased
	end

	function do_a_local_wiggle(currentPattern, currentSegment, endSegment, last_currentSegment, last_endSegment, patternList, wiggleParams)
		local savedChanged
		savedChanged = do_the_local_wiggle_campon(currentSegment, endSegment, wiggleParams)
		if savedChanged then
			if last_currentSegment ~= nil then
				do_the_local_wiggle_campon(last_currentSegment, last_endSegment, wiggleParams)
				do_the_local_wiggle_campon(currentSegment, endSegment, wiggleParams)
			end
		end
		last_currentSegment = currentSegment
		last_endSegment = endSegment
		currentSegment = endSegment + 2
		endSegment = currentSegment + patternList[currentPattern] - 2
		currentPattern = mynextmode(currentPattern,patternLength)
		return currentPattern, currentSegment, endSegment, last_currentSegment, last_endSegment
	end

	function local_wiggle_segments(first_frozen_segment, patternList, wiggleParams)
		local currentSegment = 0
		local currentPattern = 1
		local endSegment
		local patternLength = #patternList
		local last_currentSegment, last_endSegment
		if first_frozen_segment == 1 then
			currentSegment = 2
			endSegment =  currentSegment + patternList[1]-2
			currentPattern = mynextmode(currentPattern,patternLength)
		else
			currentSegment = 1
			endSegment = first_frozen_segment - 1
		end
		local savedChanged
		repeat
		currentPattern, currentSegment, endSegment, last_currentSegment, last_endSegment = do_a_local_wiggle(currentPattern, currentSegment, endSegment, last_currentSegment, last_endSegment, patternList, wiggleParams)
		until endSegment > numSegments

		if currentSegment <= numSegments then
			do_a_local_wiggle(currentPattern, currentSegment, numSegments, last_currentSegment, last_endSegment, patternList, wiggleParams)
		end
	end

	function freeze_wiggle(patternList, wiggleParams)
		local i
		for i = 1,patternList[1] do
			freeze_segments(i, patternList)
			recentbest.Restore()
			local_wiggle_segments(i, patternList, wiggleParams)
		end
	end

	function verify_patternList(patternList, maximum)
		if patternList == nil or maximum == nil then
			return false
		end
		local result = true
		patternLength = # patternList
		local count = 0
		for count = 1, patternLength do
			if patternList[count] == 1 or patternList[count] > maximum then
				result = false
				break
			end
		end
		return result
	end

	patternList = {2,3,3,4} -- Distance between frozen segments. Experiment 2,2,3,3,4,4, whatever.
	patternLength = #patternList
	patternList_ok = verify_patternList(patternList,numSegments)

	wiggleParams = {}
	wiggleParams.local_wiggle = 12
	wiggleParams.local_campon_tolerance = scoreThreshold
	if patternList_ok then
		for pattern_count = 1, patternLength do
			freeze_wiggle(patternList, wiggleParams)
		end
		unfreeze_protein()
	else
	end
end -- function thePiWalkerCampon2(scoreThreshold)

function thePowerWalker()
	g_total_score = 0
	g_startSeg = 1

	function walk_it(seg, step, time)
		selection.DeselectAll()
		selection.SelectRange(seg, (seg + step))
		g_total_score = current.GetScore()
		structure.LocalWiggleSelected(time)
		recentbest.Restore()
		if ((current.GetScore() - g_total_score) >= 0.05) then
			last_seg(seg, step,time)
		else
			next_seg(seg, step,time)
		end
	end

	function next_seg(seg, step,time)
		if ((seg + step) == numSegments) then
			return nil
		else
			if (step == 1) then
				step = 2
			else
				step = 1
				seg = seg + 1
			end
		end
		walk_it(seg, step,time)
	end

	function last_seg(seg, step,time)
		if (step == 2) then
			step = 1
		else
			seg = seg - 1
		end
		if (seg == 0) then
			seg = 1
		end
		walk_it(seg, step,time)
	end

	function end_it_all()
		print(finished)
	end

	g_total_score = current.GetScore()
	selection.DeselectAll()
	freeze.UnfreezeAll()
	recentbest.Restore()
	walk_it(g_startSeg,1,5)
	behavior.SetClashImportance(0.8)
	selection.SelectAll()
	structure.LocalWiggleAll(1)
	behavior.SetClashImportance(1.)
	structure.LocalWiggleAll(5)
	walk_it(g_startSeg,1,10)
	behavior.SetClashImportance(0.8)
	selection.SelectAll()
	structure.LocalWiggleAll(1)
	behavior.SetClashImportance(1.)
	structure.LocalWiggleAll(5)
	walk_it(g_startSeg,1,20)
	behavior.SetClashImportance(0.8)
	selection.SelectAll()
	structure.LocalWiggleAll(1)
	behavior.SetClashImportance(1.)
	structure.LocalWiggleAll(5)
	walk_it(g_startSeg,1,30)
end -- function thePowerWalker()

function thePreciseLWS()
	local function getworst()
		worst = {}
		for i = 1, numSegments do
			sc = current.GetSegmentEnergyScore(i)
			worst[i] = sc
		end
		return worst
	end

	local function wig(mingain)
		repeat
			ss = score()
			structure.LocalWiggleSelected(1)
			se = score()
			wg = se - ss
			if wg < 0 then
				recentbest.Restore()
			end
		until wg < mingain
		selection.DeselectAll()
		freeze.UnfreezeAll()
	end

	local function wiggle(s, mingain, buddies)
		selection.DeselectAll()
		freeze.UnfreezeAll()
		sgs = score()
		if s + 1 <= numSegments then
			selection.Select(s + 1)
		end
		if s - 1 >= 1 then
			selection.Select(s - 1)
		end
		freeze.FreezeSelected(true, true)
		selection.DeselectAll()
		selection.Select(s)
		wig(mingain)

		if buddies > 0 then
			for b = 1, buddies do
				if s + b + 1 <= numSegments then
					selection.Select(s + b + 1)
				end
				if s - 1 >= 1 then
					selection.Select(s - 1)
				end
				freeze.FreezeSelected(true, true)
				selection.DeselectAll()
				if s + b > numSegments then
					selection.SelectRange(s, numSegments)
				else selection.SelectRange(s, s + b)
				end
				wig(mingain)

				if s + 1 <= numSegments then
					selection.Select(s + 1)
				end
				if s - b - 1 >= 1 then
					selection.Select(s - b - 1)
				end
				freeze.FreezeSelected(true, true)
				selection.DeselectAll()
				if s - b < 1 then
					selection.SelectRange(1, s)
				else selection.SelectRange(s - b, s)
				end
				wig(mingain)

				if s + b + 1 <= numSegments then
					selection.Select(s + b + 1)
				end
				if s - b - 1 >= 1 then
					selection.Select(s - b - 1)
				end
				freeze.FreezeSelected(true, true)
				selection.DeselectAll()
				if s + b > numSegments then
					selection.SelectRange(s, numSegments)
				else selection.SelectRange(s, s + b)
				end
				if s - b < 1 then
					selection.SelectRange(1, s)
				else selection.SelectRange(s - b, s)
				end
				wig(mingain)
			end
		end
		sge = score()
	end

	function wiggleworst(howmany, mingain, buddies)
		behavior.SetClashImportance(1)
		freeze.UnfreezeAll()
		selection.DeselectAll()
		recentbest.Restore()
		sscore = score()
		worst = getworst()
		for i = 1, howmany do
			min = worst[1]
			seg = 1
			for f = 2, numSegments do
				if min > worst[f] then
					min = worst[f]
					seg = f
				end
			end
			wiggle(seg, mingain, buddies)
			worst[seg] = 9999 -- never again same one
		end
		escore = score()
	end

	howmany = 20 -- How many worst segments to process
	mingain = 0.1 -- Minimum gain per wiggle iterations (if more per 1 wiggle wiggles again)
	buddies = 4 -- How many adjacent segments should be wiggled too
	wiggleworst(howmany, mingain, buddies)
end -- function thePreciseLWS()

-- this function isn't used anywhere
function unknownWhateverSWSWA()
	selection.SelectAll()
	i = 0
	while true do
		behavior.SetClashImportance(1)
		i = i + 1
		ss = current.GetScore()
		structure.ShakeSidechainsSelected(1)
		structure.WiggleAll(1, false, true)
		structure.LocalWiggleAll(1)
		behavior.SetClashImportance(0.2)
		structure.MutateSidechainsSelected(1)
		behavior.SetClashImportance(1)
		structure.LocalWiggleAll(2)
		gain = current.GetScore() - ss
		if gain < 0.1 then
			break
		end
	end
end -- function unknownWhateverSWSWA()

function theSDHowMany(startNum, howmany)
	-- TO DO: use more intuitive variable names
	function HH(h, segFirst, segLast) -- This is based on a LUA version of the HelixHula code
		for g = 0, h - 1 do
			recentbest.Restore()
			for j = segFirst + g,segLast, h do
				k = j - h + 1
				m = j + h - 1
				if k < 1 then
					k = 1
				end
				if m > segLast then
					m = segLast
				end
				selection.SelectRange(k, m)
				structure.LocalWiggleSelected(3)
				selection.DeselectAll()
				recentbest.Restore()
			end
		end
		selection.SelectAll() --reset all segments to a loop
		structure.SetSecondaryStructureSelected('L')
		selection.DeselectAll()
		structure.ShakeSidechainsSelected(1) --shake and wiggle it out
		structure.LocalWiggleAll(5)
		structure.ShakeSidechainsSelected(1)
		structure.LocalWiggleAll(25)
	end --HH

	function SdWalkAllHH(sn, hm)
		--'sn' is the starting HH. 'hm' is the highest HH to execute.  Range is from 2 to numSegs/2
		behavior.SetClashImportance(1)
		freeze.UnfreezeAll()
		deleteBands()
		selection.SelectAll()
		structure.SetSecondaryStructureSelected('L')
		selection.DeselectAll()
		recentbest.Restore()
		scoreStart = current.GetScore()
		segF = 1
		for	hhn = sn,hm do
			HH(hhn, segF, numSegments)
			recentbest.Restore()
		end
	end -- SdWalkAllHH

	SdWalkAllHH(startNum, howmany)
end -- function theSDHowMany(startNum, howmany)

function theStabilize()

	function SelectSphere(sg, radius)
		selection.DeselectAll()
		for i = 1, numSegments do
			if structure.GetDistance(sg, i) < radius then
				selection.Select(i)
			end
		end
	end

	function PartialScoreTable()
		local score = {}
		for i = 1, numSegments do
			score[i] = current.GetSegmentEnergyScore(i)
		end
		return score
	end

	function GetWorst(scoreTable)
		local min = scoreTable[1]
		local worst = 1
		for x = 2, #scoreTable do
			if scoreTable[x] < min then
			 worst = x
			 min = scoreTable[x]
			end
		end
		scoreTable[worst] = 99999
		return worst
	end

	function Gibaj(jak, iters, minppi) -- Score conditioned recursive wiggle/shake
		if jak == nil then
			jak = "wa"
		end
		if iters == nil then
			iters = 6
		end
		if minppi == nil then
			minppi = 0.4
		end

		if iters > 0 then
			iters = iters - 1
			local sp = score()
			if jak == "s" then
				structure.ShakeSidechainsSelected(1)
			elseif jak == "wb" then
				structure.WiggleAll(1, true, false)
			elseif jak == "ws" then
				structure.WiggleAll(1, false, true)
			elseif jak == "wa" then
				structure.LocalWiggleAll(1)
			end
			local ep = score()
			local ig = ep - sp
			if ig > minppi then
				Gibaj(jak, iters, minppi)
			end
		end
	end

	function wss(minppi)
		repeat
			local ss = score()
			structure.WiggleAll(1, false, true)
			structure.ShakeSidechainsSelected(1)
			g = score() - ss
		until g < minppi
	end

	function wig(mingain)
		repeat
			local ss = score()
			structure.LocalWiggleSelected(2)
			local wg = score() - ss
			if wg < 0 then
			 recentbest.Restore()
			end
		until wg < mingain
	end

	function StabilizeWorstSphere(sgmnts)
		sgmnts = trunc(sgmnts)
		recentbest.Restore()
		scoreTable = PartialScoreTable()
		for i = 1, sgmnts do
			local found = false
			local worst = 0
			worst = GetWorst(scoreTable)
			selection.DeselectAll()
			selection.Select(worst)
			wig(20)
			SelectSphere(worst, 11)
			wss(1)
			wig(20)
		end
	end

	function Stabilize(maxLoops)
		behavior.SetClashImportance(1)
		local sstart = score()
		for iters = 1, maxLoops do
			local ss = score()
			selection.SelectAll()
			wss(2)
			StabilizeWorstSphere(numSegments / 20)
			local gain = score() - ss
			if gain < 200 then
				break
			end
		end
		selection.SelectAll()
		repeat
			local ss = score()
			wss(2)
			Gibaj()
			local g = score() - ss
		until g < 20
		send = score()
	end

	maxLoops = 10
	Stabilize(maxLoops)
end -- function theStabilize()

function theTotalLWS(scoreThreshold)

	function freezeT(start, len)
		freeze.UnfreezeAll()
		selection.DeselectAll()
		for f = start, numSegments, len + 1 do
			if f <= numSegments then
				selection.Select(f)
			end
		end
		freeze.FreezeSelected(true, false)
	end

	function lw(minppi)
		local gain = true
		while gain do
			local ss = score()
			structure.LocalWiggleSelected(2)
			local g = score() - ss
			if g < minppi then
				gain = false
			end
			if g < 0 then
				recentbest.Restore()
			end
		end
	end

	function wiggle(start, len,minppi)
		if start > 1 then
			selection.DeselectAll()
			selection.SelectRange(1, start - 1)
			lw(minppi)
		end
		for i = start, numSegments, len + 1 do
			selection.DeselectAll()
			local ss = i + 1
			local es = i + len
			if ss >= numSegments then
				ss = numSegments
			end
			if es >= numSegments then
				es = numSegments
			end
			selection.SelectRange(ss, es)
			lw(minppi)
		end
	end

	function totalLwsInternal(minLength, maxLength, minppi)
		freeze.UnfreezeAll()
		selection.DeselectAll()
		behavior.SetClashImportance(1)
		save.SaveSecondaryStructure()
		setAllLoops()
		local ssc = score()
		for l = minLength, maxLength do
			for s = 1, l + 1 do
				local sp = score()
				freezeT(s, l)
				recentbest.Restore()
				wiggle(s, l, minppi)
				save.Quicksave(3)
			end
		end
		save.LoadSecondaryStructure()
	end

	totalLwsInternal(1, 7, scoreThreshold)
end -- function theTotalLWS(scoreThreshold)

function theWalker()
	-- Walker 1.1
	bestScore = score()

	function SelectSphere(sg, radius, nodeselect)
		if nodeselect ~= true then
			selection.DeselectAll()
		end
		for i = 1, numSegments do
			if structure.GetDistance(sg, i) < radius then
				selection.Select(i)
			end
		end
	end

	function Gibaj(jak, iters, minppi) -- Score-conditioned recursive wiggle/shake
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
			local sp = score()
			if jak == "s" then
				structure.ShakeSidechainsSelected(1)
			elseif jak == "wb" then
				structure.WiggleAll(1, true, false)
			elseif jak == "ws" then
				structure.WiggleAll(1, false, true)
			elseif jak == "wa" then
				structure.LocalWiggleAll(1)
			end
			local ep = score()
			local ig = ep - sp
			if ig > minppi then
				Gibaj(jak, iters, minppi)
			end
		end
	end

	function wig(mingain)
		repeat
			local ss = score()
			structure.LocalWiggleSelected(2)
			local se = score()
			local wg = se - ss
			if wg < 0 then
				recentbest.Restore()
			end
		until wg < mingain
	end

	function wsw(minppi)
		behavior.SetClashImportance(1)
		local nows = false
		repeat
			local ss = score()
			if nows == false then
				structure.WiggleAll(1, false, true)
			end
			if shake == true then
				structure.ShakeSidechainsSelected(1)
			end
			local shs = score()
			structure.WiggleAll(2, false, true)
			local ws = score()
			local g = ws - ss
			nows = true
			if ws - shs < minppi / 10 then
				break
			end
		until g < minppi
	end

	function test()
		local gain = score() - bestScore
		if gain > 0 then
			bestScore = score()
			save.Quicksave(3)
		elseif gain < 0 then
			save.Quickload(3)
		end
	end

	function Walker()
		local ss = score()
		if endS == nil then
			endS = numSegments
		end

		recentbest.Restore()
		save.Quicksave(3)
		behavior.SetClashImportance(1)

		for l = minLength, maxLength do
			for i = startS, endS - l do
				selection.DeselectAll()
				selection.SelectRange(i, i + l - 1)
				if doWSW then
					wsw(minppi)
				end
				wig(minppi)
				test()
			end
		end
	end

	minppi = 0.0002
	startS = 1
	endS = nil
	minLength = 1
	maxLength = 9
	doWSW = true -- Set to true if it have to shake/wiggle sidechains too
	shake = false
	Walker()
end -- function theWalker()

function theWormLWS(scoreThreshold)
	function lw(minppi)
		local gain = true
		while gain do
			local ss = score()
			structure.LocalWiggleSelected(2)
			local g = score() - ss
			if g < minppi then
				gain = false
			end
			if g < 0 then
				recentbest.Restore()
			end
		end
	end -- theWormLWS(scoreThreshold)

	function Worm()
		if sEnd == nil then
			sEnd = numSegments
		end
		setAllLoops()
		recentbest.Restore()
		save.Quicksave(3)
		local ss = score()
		for w = 1, #pattern do
			len = pattern[w]
			local sw = score()
			for s = sStart, sEnd - len + 1 do
				selection.DeselectAll()
				selection.SelectRange(s, s + len - 1)
				lw(minppi)
			end
			save.Quicksave(3)
		end
		selection.DeselectAll()
		save.LoadSecondaryStructure()
	end

	pattern = {5, 2, 11, 3, 13, 7, 1}
	sStart = 1
	sEnd = nil
	minppi = scoreThreshold
	Worm()
end

function finishWalker()
	local score = current.GetScore()
	print("   **Score at end = ", score, "**", " (", os.date(), ")")
	behavior.SetClashImportance(1)
	freeze.UnfreezeAll()
	deleteBands()
	selection.SelectAll()
	structure.SetSecondaryStructureSelected('L')
	selection.DeselectAll()
	if score < currentScore then
		score = currentScore
		save.Quickload(8)
		print("   Resetting to score = ", score)
	else save.Quicksave(8)
		currentScore = score
	end
	save.LoadSecondaryStructure()
end

function cleanup(err)
	currentScore = current.GetScore()
	print("****Total score change = ", currentScore - startingScore, "****")
	deleteBands()
	print(err)
	-- ? REPLACE WITH:
	-- creditbest.Restore()
	-- save.LoadSecondaryStructure()
	-- band.DeleteAll()
	-- selection.DeselectAll()
end

function main()
	timeStart = os.time()
	print(os.date())
	numSegments = structure.GetCount()
	userBands = band.GetCount()
	print(userBands..' user-supplied bands.\n ')
	save.SaveSecondaryStructure()
	behavior.SetClashImportance(1)
	freeze.UnfreezeAll()
	--deleteBands()
	selection.SelectAll()
	structure.SetSecondaryStructureSelected('L')
	selection.DeselectAll()
	recentbest.Save()
	save.Quicksave(8)
	startingScore = current.GetScore()
	currentScore = startingScore
	print("**Starting score = ", startingScore, "**")
	countCycles = 0
	while true do
		countCycles = countCycles + 1

		timeCycleStart = os.time()
		startWalker(countCycles, 1, 15, "SD How Many", from, 2, to, 4)
		theSDHowMany(2,4)
		finishWalker()
		printElapsedTime()

		timeCycleStart = os.time()
		startWalker(countCycles, 2, 15, "Pi Walker Campon 2")
		thePiWalkerCampon2(0.0001)
		finishWalker()
		printElapsedTime()

		timeCycleStart = os.time()
		startWalker(countCycles, 3, 15, "Worm LWS")
		theWormLWS(0.0001)
		finishWalker()
		printElapsedTime()

		timeCycleStart = os.time()
		startWalker(countCycles, 4, 15, "SD How Many", from, 8, to, 25)
		theSDHowMany(8, 25)
		finishWalker()
		printElapsedTime()

		timeCycleStart = os.time()
		startWalker(countCycles, 5, 15, "Total LWS")
		theTotalLWS(0.0001)
		finishWalker()
		printElapsedTime()

		timeCycleStart = os.time()
		startWalker(countCycles, 6, 15, "M3 Wiggle Sequence")
		theM3WiggleSequence(0.0001)
		finishWalker()
		printElapsedTime()

		timeCycleStart = os.time()
		startWalker(countCycles, 8, 15, "SD How Many", from, 26, to, 32)
		theSDHowMany(26, 32)
		finishWalker()
		printElapsedTime()

		timeCycleStart = os.time()
		startWalker(countCycles, 9, 15, "Power Walker")
		thePowerWalker()
		finishWalker()
		printElapsedTime()

		timeCycleStart = os.time()
		startWalker(countCycles, 11, 15, "Precise LWS")
		thePreciseLWS()
		finishWalker()
		printElapsedTime()

		timeCycleStart = os.time()
		startWalker(countCycles, 12, 15, "SD How Many", from, 5, to, 7)
		theSDHowMany(5, 7)
		finishWalker()
		printElapsedTime()

		timeCycleStart = os.time()
		startWalker(countCycles, 13, 15, "Moon Walker")
		theMoonWalker(0.0001)
		finishWalker()
		printElapsedTime()

		timeCycleStart = os.time()
		startWalker(countCycles, 14, 15, "Stabilize 3.0.7")
		theStabilize()
		finishWalker()
		printElapsedTime()

		timeCycleStart = os.time()
		startWalker(countCycles, 15, 15, "Krog Walker 4")
		theKrogWalker4(0.0001)
		finishWalker()
		printElapsedTime()

		timeCycleStart = os.time()
		startWalker(countCycles, 7, 15, "Walker 1.1")
		theWalker()
		finishWalker()
		printElapsedTime()

		timeCycleStart = os.time()
		print("****All walkers done ", countCycles, " times****", " (", os.date(), ")")
		printElapsedTime()
		print("****Total score change so far = ", currentScore - startingScore, "****")
	end
end

xpcall(main,cleanup)
