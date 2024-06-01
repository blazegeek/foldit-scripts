scriptName = "SD Multiwalk Forever 2.6.1"
buildNumber = 2
timeStart = 0
timeCycleStart = 0
print(os.date())
userBands = band.GetCount()
numSegments = structure.GetCount()
print(userBands..' user-supplied bands.\n ')

function printTime()
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
end

function KrogWalkerV4(scoreThreshold)
	-- Krog recommends 1-4.
	minWiggleSegments = 1
	maxWiggleSegments = 4
	-- Krog recommends 0.01 for early, 0.001 mid and 0.0001 late - get all you can!
	scoreCondition = scoreThreshold
	doGlobalWiggle = false
	runForever = false

	function wiggle_walk(section_size, score_thresh, global)
		totalGain = 0;
		recentbest.Restore()
		behavior.SetClashImportance(1)
		selection.DeselectAll()
		freeze.UnfreezeAll()
		for i = 1, section_size - 1 do
			selection.Select(i)
		end
		for i = section_size, numSegments do
			selection.Select(i)
			gain = score_thresh
			while gain >= score_thresh do
				last_score = current.GetScore()
				if global then
					structure.LocalWiggleAll(40/section_size)
				else
					structure.LocalWiggleSelected(8)
					recentbest.Restore()
				end
				gain = current.GetScore() - last_score
				totalGain = totalGain + gain
			end
			selection.Deselect(i - section_size + 1)
		end
	end

	run_condition = true
	while run_condition do
		run_condition = runForever
		for j = minWiggleSegments, maxWiggleSegments do
			wiggle_walk(j, scoreCondition, doGlobalWiggle)
		end
	end
end

function M3wiggleSequence(scoreThreshold)
	doWiggleSidechains = 0
	doShakeSidechains = 0
	wiggleCycles = 5
	maxIterations = 10
	-- scoreThreshold = 0.0001
	max_wiggle = 5
	initial_score = current.GetScore()
	save.Quicksave(10)
	recentbest.Restore()
	for seq = 1, max_wiggle do
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
			iteration_count = 0
			while( ((scoreAfter - scoreBefore) > scoreThreshold) and (iteration_count < maxIterations)) do
				recentbest.Restore()
				scoreBefore = scoreAfter
				structure.LocalWiggleSelected(wiggleCycles)
				scoreAfter = current.GetScore()
				if( (scoreAfter - scoreBefore) > scoreThreshold) then
					recentbest.Restore()
				else
					recentbest.Restore()
				end
				iteration_count = iteration_count + 1
			end
			if (doShakeSidechains == 1) then
				structure.ShakeSidechainsSelected(1)
			end
			if (doWiggleSidechains == 1) then
				structure.WiggleAll(1,false,true)
			end
			if ((current.GetScore() - scoreStart) > scoreThreshold) then
			end
			recentbest.Restore()
		end
	end
end

function MoonWalker(scoreThreshold)
	function reset_protein()
		behavior.SetClashImportance(1)
		selection.DeselectAll()
		freeze.UnfreezeAll()
	end

	function get_protein_score(segment_count)
		return current.GetScore()
	end

	function wiggle_it_out(wiggle_params)
		selection.DeselectAll()
		selection.SelectAll()
		structure.WiggleAll(wiggle_params.sideChain_count, false, true)
		structure.ShakeSidechainsSelected(wiggle_params.shake)
		structure.LocalWiggleAll(wiggle_params.all_count)
		recentbest.Restore()
	end

	function do_the_local_wiggle_campon(first, last, wiggle_params)
		selection.DeselectAll()
		if last > numSegments then
			last = numSegments
		end
		selection.SelectRange(first, last)
		local end_score = get_protein_score()
		local points_increased = false
		local beginning_score = end_score
		repeat
			start_score = end_score
			structure.LocalWiggleSelected(wiggle_params.local_wiggle)
			recentbest.Restore()
			end_score = get_protein_score()
		until end_score < start_score + wiggle_params.local_tolerance
		if beginning_score + wiggle_params.local_tolerance < end_score then
			points_increased = true
		end
		return points_increased
	end

	function step_wiggle(start, finish, wiggle_params)
		local i
		local reset
		local rewiggle_increment = 1
		local rewiggle_score = get_protein_score() + rewiggle_increment
		i = start
		while i <= finish do
			local j
			local saved_changed
			local points_changed = false
			for j = 1, 3 do
				saved_changed = do_the_local_wiggle_campon(i, i + j - 1, wiggle_params)
				if saved_changed then
					points_changed = true
				end
			end
			if points_changed then
				reset = i - 1
				if reset < start then
					reset = start
				end
				for j = 1, 3 do
					do_the_local_wiggle_campon(reset, reset + j - 1, wiggle_params)
				end
				reset = reset + 1
				if reset <= i then
					for j = 1, 3 do
						do_the_local_wiggle_campon(reset, reset + j - 1, wiggle_params)
					end
				end
			end
			local new_score = get_protein_score()
			if new_score > rewiggle_score then
				wiggle_it_out(wiggle_params)
				rewiggle_score = new_score + rewiggle_increment
			end
			i = i + 1
		end
	end

	reset_protein()
	recentbest.Restore()
	wiggle_params = {}
	wiggle_params.local_wiggle = 12
	wiggle_params.local_tolerance = scoreThreshold
	wiggle_params.sideChain_count = 15
	wiggle_params.shake = 5
	wiggle_params.all_count = 15
	step_wiggle(1, numSegments, wiggle_params)
end

function PiWalkerCamponV2(scoreThreshold)
	g_segments = structure.GetCount()

	function mynextmode(number, maximum)
		number = number + 1
		if number > maximum then
			number = 1
		end
		return number
	end

	function get_protein_score(segment_count)
		return current.GetScore()
	end

	function rotate_pattern(pattern_list)
		local last = #pattern_list
		local i
		if last > 1 then
			local pattern_save = pattern_list[1]
			for i = 1, last do
				pattern_list[i]  = pattern_list[i+1]
			end
			pattern_list[last] = pattern_save
		end
		return pattern_list
	end

	function unfreeze_protein()
		freeze.UnfreezeAll()
	end

	function freeze_segments(start_index, pattern_list)
		unfreeze_protein()
		local pattern_length = #pattern_list
		local current_segment = start_index
		local current_pattern = 1
		selection.DeselectAll()
		while current_segment < g_segments do
			selection.Select(current_segment)
			current_segment = current_segment + pattern_list[current_pattern]
			current_pattern = mynextmode(current_pattern,pattern_length)
		end
		freeze.FreezeSelected(true,true)
	end

	function do_the_local_wiggle_campon(first, last, wiggle_params)
		selection.DeselectAll()
		selection.SelectRange(first,last)
		local end_score = get_protein_score()
		local points_increased = false
		local beginning_score = end_score
		repeat
			start_score = end_score
			structure.LocalWiggleSelected(wiggle_params.local_wiggle)
			recentbest.Restore()
			end_score = get_protein_score()
		until end_score < start_score + wiggle_params.local_campon_tolerance
		if beginning_score + wiggle_params.local_campon_tolerance < end_score then
			points_increased = true
		end
		--recentbest.Restore()
		return points_increased
	end

	function do_a_local_wiggle(current_pattern, current_segment, end_segment, last_current_segment, last_end_segment, pattern_list, wiggle_params)
		local saved_changed
		saved_changed = do_the_local_wiggle_campon(current_segment, end_segment, wiggle_params)
		if saved_changed then
			if last_current_segment ~= nil then
				do_the_local_wiggle_campon(last_current_segment, last_end_segment, wiggle_params)
				do_the_local_wiggle_campon(current_segment, end_segment, wiggle_params)
			end
		end
		last_current_segment = current_segment
		last_end_segment = end_segment
		current_segment = end_segment + 2
		end_segment = current_segment + pattern_list[current_pattern] - 2
		current_pattern = mynextmode(current_pattern,pattern_length)
		return current_pattern, current_segment, end_segment, last_current_segment, last_end_segment
	end

	function local_wiggle_segments(first_frozen_segment, pattern_list, wiggle_params)
		local current_segment = 0
		local current_pattern = 1
		local end_segment
		local pattern_length = #pattern_list
		local last_current_segment, last_end_segment
		if first_frozen_segment == 1 then
			current_segment = 2
			end_segment =  current_segment + pattern_list[1]-2
			current_pattern = mynextmode(current_pattern,pattern_length)
		else
			current_segment = 1
			end_segment = first_frozen_segment - 1
		end
		local saved_changed
		repeat
		current_pattern, current_segment, end_segment, last_current_segment, last_end_segment = do_a_local_wiggle(current_pattern, current_segment, end_segment, last_current_segment, last_end_segment, pattern_list, wiggle_params)
		until end_segment > g_segments

		if current_segment <= g_segments then
			do_a_local_wiggle(current_pattern, current_segment, g_segments, last_current_segment, last_end_segment, pattern_list, wiggle_params)
		end
	end

	function freeze_wiggle(pattern_list, wiggle_params)
		local i
		for i = 1,pattern_list[1] do
			freeze_segments(i, pattern_list)
			recentbest.Restore()
			local_wiggle_segments(i, pattern_list, wiggle_params)
		end
	end

	function verify_pattern_list(pattern_list, maximum)
		if pattern_list == nil or maximum == nil then
			return false
		end
		local result = true
		pattern_length = # pattern_list
		local count = 0
		for count = 1, pattern_length do
			if pattern_list[count] == 1 or pattern_list[count] > maximum then
				result = false
				break
			end
		end
		return result
	end

	pattern_list = {2,3,3,4} -- Distance between frozen segments. Experiment 2,2,3,3,4,4, whatever.
	pattern_length = #pattern_list
	pattern_list_ok = verify_pattern_list(pattern_list,g_segments)

	wiggle_params = {}
	wiggle_params.local_wiggle = 12
	wiggle_params.local_campon_tolerance = scoreThreshold
	if pattern_list_ok then
		for pattern_count = 1, pattern_length do
			freeze_wiggle(pattern_list, wiggle_params)
		end
		unfreeze_protein()
	else
	end
end -- function PiWalkerCamponV2(scoreThreshold)

function Power_Walker_fn()
	g_segments = structure.GetCount() -- total number of segments in puzzle, last seg
	g_total_score = 0 -- Recent best to compare to and see if score was improved
	g_startSeg = 1 -- Segment to start with

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
		if ((seg + step) == g_segments) then
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
end -- function Power_Walker_fn()

function Precise_LWS_fn()
	local function score()
		s = current.GetScore()
			if s == 0 then
				for i = 1, structure.GetCount() do
					s = s + current.GetSegmentEnergyScore(i)
				end
				s = s + 8000
			end
		return s
	end

	local function getworst()
		worst = {}
		for i = 1, structure.GetCount() do
			sc = current.GetSegmentEnergyScore(i)
			worst[i]=sc
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
		maxi = structure.GetCount()
		if s + 1 <= maxi then
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
				if s + b + 1 <= maxi then
					selection.Select(s + b + 1)
				end
				if s - 1 >= 1 then
					selection.Select(s - 1)
				end
				freeze.FreezeSelected(true, true)
				selection.DeselectAll()
				if s + b > maxi then
					selection.SelectRange(s, maxi)
				else selection.SelectRange(s, s + b)
				end
				wig(mingain)

				if s + 1 <= maxi then
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

				if s + b + 1 <= maxi then
					selection.Select(s + b + 1)
				end
				if s - b - 1 >= 1 then
					selection.Select(s - b - 1)
				end
				freeze.FreezeSelected(true, true)
				selection.DeselectAll()
				if s + b > maxi then
					selection.SelectRange(s, maxi)
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
			for f = 2,structure.GetCount() do
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
end -- function Precise_LWS_fn()

function s_ws_wa_whatever()
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
end -- function s_ws_wa_whatever()

function SdHowMany(startNum, howmany)
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
		selection.SelectAll()				--reset all segments to a loop
		structure.SetSecondaryStructureSelected('L')
		selection.DeselectAll()
		structure.ShakeSidechainsSelected(1)					--shake and wiggle it out
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
		scoreStart=current.GetScore()
		segF = 1
		segL = structure.GetCount()
		for	hhn = sn,hm do
			HH(hhn, segF, segL)
			recentbest.Restore()
		end
	end -- SdWalkAllHH
	SdWalkAllHH(startNum, howmany)
end -- function SdHowMany(startNum, howmany)

function Stabilize_fn()
	segCount = structure.GetCount()

	function Score()
		return current.GetScore()
	end
	function Round(x)
		return x - x % 0.001
	end
	function Down(x)
		return x - x % 1
	end

	function SelectSphere(sg, radius)
		selection.DeselectAll()
		for i = 1, segCount do
			if structure.GetDistance(sg, i) < radius then
				selection.Select(i)
			end
		end
	end

	function PartialScoreTable()
		local score = {}
		for i = 1, segCount do
			score[i] = current.GetSegmentEnergyScore(i)
		end
		return score
	end

	function GetWorst(sctbl)
		local min = sctbl[1]
		local wrst = 1
		for x = 2, #sctbl do
			if sctbl[x] < min then
			 wrst = x
			 min = sctbl[x]
			end
		end
		sctbl[wrst] = 99999
		return wrst
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
			local sp = Score()
			if jak == "s" then
				structure.ShakeSidechainsSelected(1)
			elseif jak == "wb" then
				structure.WiggleAll(1, true, false)
			elseif jak == "ws" then
				structure.WiggleAll(1, false, true)
			elseif jak == "wa" then
				structure.LocalWiggleAll(1)
			end
			local ep = Score()
			local ig = ep - sp
			if ig > minppi then
				Gibaj(jak, iters, minppi)
			end
		end
	end

	function wss(minppi)
		repeat
			local ss = Score()
			structure.WiggleAll(1, false, true)
			structure.ShakeSidechainsSelected(1)
			g = Score() - ss
		until g < minppi
	end

	function wig(mingain)
		repeat
			local ss = Score()
			structure.LocalWiggleSelected(2)
			local wg = Score() - ss
			if wg < 0 then
			 recentbest.Restore()
			end
		until wg < mingain
	end

	function StabilizeWorstSphere(sgmnts)
		sgmnts = Down(sgmnts)
		recentbest.Restore()
		sctbl = PartialScoreTable()
		for i = 1, sgmnts do
			local found = false
			local wrst = 0
			wrst = GetWorst(sctbl)
			selection.DeselectAll()
			selection.Select(wrst)
			wig(20)
			SelectSphere(wrst, 11)
			wss(1)
			wig(20)
		end
	end

	function Stabilize(maxLoops)
		behavior.SetClashImportance(1)
		local sstart= Score()
		for iters = 1, maxLoops do
			local ss = Score()
			selection.SelectAll()
			wss(2)
			StabilizeWorstSphere(segCount / 20)
			local gain = Score() - ss
			if gain < 200 then
				break
			end
		end
		selection.SelectAll()
		repeat
			local ss = Score()
			wss(2)
			Gibaj()
			local g = Score() - ss
		until g < 20
		send = Score()
	end

	maxLoops = 10
	Stabilize(maxLoops)
end -- function Stabilize_fn()

function TotalLWS(scoreThreshold)
		local function score()
			return current.GetScore()
		end

		function AllLoop()
			selection.SelectAll()
			structure.SetSecondaryStructureSelected("L")
		end

		function freezeT(start, len)
			freeze.UnfreezeAll()
			selection.DeselectAll()
			for f = start, maxs, len + 1 do
				if f <= maxs then
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
			for i = start, maxs, len + 1 do
				selection.DeselectAll()
				local ss = i+1
				local es = i + len
				if ss >= maxs then
					ss = maxs
				end
				if es >= maxs then
					es = maxs
				end
				selection.SelectRange(ss, es)
				lw(minppi)
			end
		end

		function totalLwsInternal(minlen, maxlen, minppi)
			freeze.UnfreezeAll()
			selection.DeselectAll()
			behavior.SetClashImportance(1)
			save.SaveSecondaryStructure()
			AllLoop()
			maxs = structure.GetCount()
			local ssc = score()
			for l = minlen, maxlen do
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
end -- function TotalLWS(scoreThreshold)

function walker_1point1_fn()
	segCount = structure.GetCount()

	function Score()
		return current.GetScore()
	end

	bestScore = Score()

	function round(x)
		return x - x % 0.001
	end

	function SelectSphere(sg, radius, nodeselect)
		if nodeselect ~= true then
			selection.DeselectAll()
		end
		for i = 1, segCount do
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
			local sp = Score()
			if jak == "s" then
				structure.ShakeSidechainsSelected(1)
			elseif jak == "wb" then
				structure.WiggleAll(1, true, false)
			elseif jak == "ws" then
				structure.WiggleAll(1, false, true)
			elseif jak == "wa" then
				structure.LocalWiggleAll(1)
			end
			local ep = Score()
			local ig = ep - sp
			if ig > minppi then
				Gibaj(jak, iters, minppi)
			end
		end
	end

	function wig(mingain)
		repeat
			local ss = Score()
			structure.LocalWiggleSelected(2)
			local se = Score()
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
			local ss = Score()
			if nows == false then
				structure.WiggleAll(1, false, true)
			end
			if shake == true then
				structure.ShakeSidechainsSelected(1)
			end
			local shs = Score()
			structure.WiggleAll(2, false, true)
			local ws = Score()
			local g = ws - ss
			nows = true
			if ws - shs < minppi / 10 then
				break
			end
		until g < minppi
	end

	function test()
		local gain = Score() - bestScore
		if gain > 0 then
			bestScore = Score()
			save.Quicksave(3)
		elseif gain < 0 then
			save.Quickload(3)
		end
	end

	function Walker()
		local ss = Score()
		if endS == nil then
			endS = segCount
		end

		recentbest.Restore()
		save.Quicksave(3)
		behavior.SetClashImportance(1)

		for l = minlen, maxlen do
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
	minlen = 1
	maxlen = 9
	doWSW = true -- Set to true if it have to shake/wiggle sidechains too
	shake = false
	Walker()
end -- function walker_1point1_fn()

function WormLWS(scoreThreshold)
	segCount = structure.GetCount()
	local function Score()
		return current.GetScore()
	end
	function round(x)
		return x - x % 0.001
	end

	function AllLoop()
		local ok = false
		for i = 1, segCount do
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

	function lw(minppi)
		local gain = true
		while gain do
			local ss = Score()
			structure.LocalWiggleSelected(2)
			local g = Score() - ss
			if g < minppi then
				gain = false
			end
			if g < 0 then
				recentbest.Restore()
			end
		end
	end

	function Worm()
		if sEnd == nil then
			sEnd=segCount
		end
		AllLoop()
		recentbest.Restore()
		save.Quicksave(3)
		local ss = Score()
		for w = 1, #pattern do
			len = pattern[w]
			local sw = Score()
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

function FinishWalker()
	local score = current.GetScore()
	print("   **Score at end = ", score, "**", " (", os.date(), ")")
	behavior.SetClashImportance(1)
	freeze.UnfreezeAll()
	deleteBands()
	selection.SelectAll()
	structure.SetSecondaryStructureSelected('L')
	selection.DeselectAll()
	if score < scoreOurCurrent then
		score = scoreOurCurrent
		save.Quickload(8)
		print("   Resetting to score = ", score)
	else save.Quicksave(8)
		scoreOurCurrent = score
	end
	save.LoadSecondaryStructure()
end

function cleanup(err)
	scoreOurCurrent = current.GetScore()
	print("****Total score change = ", scoreOurCurrent - scoreOurStart, "****")
	deleteBands()
	print(err)
end

function main()
	save.SaveSecondaryStructure()
	behavior.SetClashImportance(1)
	freeze.UnfreezeAll()
	deleteBands()
	selection.SelectAll()
	structure.SetSecondaryStructureSelected('L')
	selection.DeselectAll()
	recentbest.Save()
	save.Quicksave(8)
	scoreOurStart = current.GetScore()
	scoreOurCurrent = scoreOurStart
	print("**Starting score = ", scoreOurStart, "**")
	cntTimes = 0
	while true do
		cntTimes = cntTimes + 1

		timeCycleStart = os.time()
		startWalker(cntTimes, 1, 15, "SdHowMany", from, 2, to, 4)
		SdHowMany(2,4)
		FinishWalker()
		printTime()

		timeCycleStart = os.time()
		startWalker(cntTimes, 2, 15, "Pi Walker Campon V2")
		PiWalkerCamponV2(0.0001)
		FinishWalker()
		printTime()

		timeCycleStart = os.time()
		startWalker(cntTimes, 3, 15, "Worm LWS")
		WormLWS(0.0001)
		FinishWalker()
		printTime()

		timeCycleStart = os.time()
		startWalker(cntTimes, 4, 15, "SdHowMany", from, 8, to, 25)
		SdHowMany(8, 25)
		FinishWalker()
		printTime()

		timeCycleStart = os.time()
		startWalker(cntTimes, 5, 15, "Total LWS")
		TotalLWS(0.0001)
		FinishWalker()
		printTime()

		timeCycleStart = os.time()
		startWalker(cntTimes, 6, 15, "M3 Wiggle sequence")
		M3wiggleSequence(0.0001)
		FinishWalker()
		printTime()

		timeCycleStart = os.time()
		startWalker(cntTimes, 8, 15, "SdHowMany", from, 26, to, 32)
		SdHowMany(26, 32)
		FinishWalker()
		printTime()

		timeCycleStart = os.time()
		startWalker(cntTimes, 9, 15, "Power_Walker_fn")
		Power_Walker_fn()
		FinishWalker()
		printTime()

		timeCycleStart = os.time()
		startWalker(cntTimes, 11, 15, "Precise LWS")
		Precise_LWS_fn()
		FinishWalker()
		printTime()

		timeCycleStart = os.time()
		startWalker(cntTimes, 12, 15, "SdHowMany", from, 5, to, 7)
		SdHowMany(5, 7)
		FinishWalker()
		printTime()

		timeCycleStart = os.time()
		startWalker(cntTimes, 13, 15, "Moon Walker")
		MoonWalker(0.0001)
		FinishWalker()
		printTime()

		timeCycleStart = os.time()
		startWalker(cntTimes, 14, 15, "Stabilize 3.0.7")
		Stabilize_fn()
		FinishWalker()
		printTime()

		timeCycleStart = os.time()
		startWalker(cntTimes, 15, 15, "Krog Walker V4")
		KrogWalkerV4(0.0001)
		FinishWalker()
		printTime()

		timeCycleStart = os.time()
		startWalker(cntTimes, 7, 15, "Walker 1.1")
		walker_1point1_fn()
		FinishWalker()
		printTime()

		timeCycleStart = timeStart
		print("****All walkers done ", cntTimes, " times****", " (", os.date(), ")")
		printTime()
		print("****Total score change so far = ", scoreOurCurrent - scoreOurStart, "****")
	end
end

xpcall(main,cleanup)
