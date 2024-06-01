-- Sd Multiwalk Forever 2.6

--START Jeff101 suggestions

recipename="Sd Multiwalk Forever 2.6"
start_time = 0
print(os.date())
userbands=band.GetCount()
print(userbands..' user-supplied bands.\n ')


function deletebands() --leave user bands intact
    nbands=band.GetCount()
    if nbands>userbands then
        for i=nbands,userbands+1,-1 do -- count down from nbands to userbands+1
            band.Delete(i)
        end -- for i
    end -- if nbands
end -- function

function StartWalker(loop, step, total, script, from, startNum, to, howmany)
	local loop=loop or ""
	local step=step or ""
	local total= total or ""
	local script = script or "unknown"
	local from= " from " or ""
	local startNum= startNum or ""
	local to= " to " or ""
	local howmany= howmany or ""
	if startNum=="" then from="" to="" howmany="" end
	print(loop.."("..step.."/"..total..") Starting "..script..from..startNum..to..howmany..  " ...")
end

function printTime()
  
  elapsed_time = os.time() - start_time
  seconds = elapsed_time % 60
  minutes = ((elapsed_time - seconds) % (60 * 60)) / 60
  hours = (elapsed_time - minutes * 60 - seconds) / 3600
  print(string.format("Elapsed time: %ih %02im %02is at %s",hours,minutes,seconds,os.date()))
  
end -- function

--END Jeff101 suggestions
	
	function KrogWalkerV4(threshold)
		--
		--print("Starting Krog walker V4...")
		-- *** SET OPTIONS HERE ***

		-- How many segments to wiggle. Starts at min, stop at max. 
		-- Krog recommends 1-4.
		min_segs_to_wiggle = 1
		max_segs_to_wiggle = 4

		-- How much the score must improve at each iteration to try that section again. 
		-- Krog recommends 0.01 for early, 0.001 mid and 0.0001 late - get all you can!
		score_condition = threshold --0.001

		-- If true, do a smoother, global wiggle - much slower but might squeeze extra points
		should_global_wiggle = false

		-- Set to true if you want it to run forever - good for overnighting
		-- Krog recommends a SUPER low score condition if this is true.
		should_run_forever = false

		-- **********************************************************************
		-- *** Dont edit below this line unless you know what you're doing :) ***
		-- **********************************************************************

			function wiggle_walk(section_size, score_thresh, global)
			  total_gain = 0;
			  recentbest.Restore()
			  behavior.SetClashImportance(1)
			  selection.DeselectAll()
			  freeze.UnfreezeAll()
			  segs = structure.GetCount()
			  for i = 1, section_size - 1 do
				selection.Select(i)
			  end
			  for i = section_size, segs do
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
				  total_gain = total_gain + gain
				  --print("Section ", i - section_size + 1, "/", segs - section_size + 1, "   Improvement: ", gain)
				  --print(" Total Improvement: ", total_gain)
				end
				selection.Deselect(i - section_size + 1)  
			  end
			end -- wiggle walk


		run_condition = true
		while run_condition do
		  run_condition = should_run_forever
		  for j = min_segs_to_wiggle, max_segs_to_wiggle do
			wiggle_walk(j, score_condition, should_global_wiggle)
		  end
		end
	end -- Krog Walker

	function M3wigglwSequence(threshold)
		--
		--print("starting M3 Wiggle sequence...")
		-- Foldit Script "Wiggle Sequence"
		-- 01-09-2010
		-- V1.0
		-- MooMooMan

		-- If 1 then wiggle sidechains.
		sidechains_flag = 0

		-- If 1 then shake
		shake_flag = 0

		-- Set number of wiggle cycles per iteration
		wiggle_cycles = 5

		-- Set number of iterations to gain points.
		max_iterations = 10

		-- Set termination threshold.
		--threshold = 0.0001

		-- Obtain the number of segments in the protein.
		segments = structure.GetCount()

		-- Maximum number of segments to wiggle.
		max_wiggle = 5

		-- Get the starting score.
		initial_score = current.GetScore()

		-- print a title.
		--print("Wiggle Sequence")

		-- Save the current structure in slot 10
		save.Quicksave(10)

		-- Reset the recent best so we can use crtl N
		recentbest.Restore()

		-- Loop for the wiggle length
		for seq = 1, max_wiggle do
			
			-- Loop for the selected segments.
			for sel = 1, (segments-seq) do
			
				--print("Seq ", seq, "/", max_wiggle, " : AA ", sel, "/", segments)
			
				-- Make sure nothing is selected.
				selection.DeselectAll()
				
				-- Iterate over the segments we want to select.
				for group = 0, seq do
					selection.Select(sel + group)
				end
				
				-- Get the score before changing.
				scoreBefore = current.GetScore()
				scoreStart = current.GetScore()
				scoreAfter = scoreBefore
				
				-- Now wiggle those segments selected.
				structure.LocalWiggleSelected(wiggle_cycles)
				
				-- Shake if selected.
				if (shake_flag == 1) then
					structure.ShakeSidechainsSelected(1)
				end
				
				-- Wiggle sidechains if selected
				if (sidechains_flag == 1) then
					structure.WiggleAll(1,false,true)
				end
				
				-- Get score after operations.
				scoreAfter = current.GetScore()
				
				-- Check to see if we should iterate to get more points.
				
				iteration_count = 0
				while( ((scoreAfter - scoreBefore) > threshold) and (iteration_count < max_iterations)) do
					
					--print ("Iterating... ", iteration_count, "/", max_iterations)
					
					-- Reset the recent best structure..
					recentbest.Restore()
					
					-- Reset the before score.
					scoreBefore = scoreAfter
					
					-- Now wiggle those segments selected.
					structure.LocalWiggleSelected(wiggle_cycles)
					
					-- Score after operations.
					scoreAfter = current.GetScore()
					
					-- Test to see if we should keep the structure.
					if( (scoreAfter - scoreBefore) > threshold) then
						recentbest.Restore()
					else
						recentbest.Restore()
					end
					
					iteration_count = iteration_count + 1
								
				end
				
				-- Shake if selected.
				if (shake_flag == 1) then
					structure.ShakeSidechainsSelected(1)
				end
				
				-- Wiggle sidechains if selected
				if (sidechains_flag == 1) then
					structure.WiggleAll(1,false,true)
				end
				
				if ((current.GetScore() - scoreStart) > threshold) then
					--print("Gain +", current.GetScore() - scoreStart)
				end
				
				recentbest.Restore()
				
			end
		end
	end -- M3 wiggle sequence

	function MoonWalker(threshold)
		--print("Starting moon walker...")

		-- step walker refresh. Original ideas from Datstandin.

		-- updated by smith92clone 31May2010

		-- Perform a local wiggle /w campon for each segment, with 1, 2 and 3 segments selected
		-- If a wiggle increases in points, backup one segment and wiggle again. Could run a long time.

		g_segments = structure.GetCount()

			function reset_protein()
			   behavior.SetClashImportance(1)
			   selection.DeselectAll()
			   freeze.UnfreezeAll()
			end -- reset protein

			function get_protein_score(segment_count)
				return current.GetScore()
			end -- get protein score

			function wiggle_it_out(wiggle_params)
				selection.DeselectAll()
				selection.SelectAll()
				structure.WiggleAll(wiggle_params.sideChain_count, false, true)
				structure.ShakeSidechainsSelected(wiggle_params.shake)
				structure.LocalWiggleAll(wiggle_params.all_count)
				recentbest.Restore()
			end --wiggle it out

			function do_the_local_wiggle_campon(first,last,wiggle_params)
				selection.DeselectAll()
				if last > g_segments then
					last = g_segments
				end
				selection.SelectRange(first,last)
				local end_score = get_protein_score()
				local points_increased = false
				local beginning_score = end_score
				repeat
					start_score = end_score
					structure.LocalWiggleSelected(wiggle_params.local_wiggle)
					recentbest.Restore()
					end_score = get_protein_score()
					--print("    start ",start_score," end ", end_score)
				until end_score < start_score + wiggle_params.local_tolerance
				if beginning_score + wiggle_params.local_tolerance < end_score then
					points_increased = true
				end
				--recentbest.Restore()
				return points_increased
			end --do_the_local_wiggle_campon

			function step_wiggle(start,finish,wiggle_params)
				local i
				local reset
				local rewiggle_increment = 1 -- points
				local rewiggle_score = get_protein_score() + rewiggle_increment
				i = start
				while i <= finish do
					 local j
					 local saved_changed
					 local points_changed = false
					 for j = 1,3 do
						 --print("seg:",i," of ",finish," wiggle Length: ",j)
						 saved_changed = do_the_local_wiggle_campon(i,i+j-1,wiggle_params)
						 if saved_changed then
							 points_changed = true
						 end
					 end
					 if points_changed then
						 reset = i - 1 -- we want to go back to the previous segment
						 if reset < start then
							 reset = start
						 end
						 for j=1,3 do
							--print("retry seg:",reset," of ",finish," wiggle Length: ",j)
							do_the_local_wiggle_campon(reset,reset+j-1,wiggle_params)
						 end
						 reset = reset + 1
						 if reset <= i then
							-- let's not get ahead of ourselves. Only really an issue when we are retrying 1
							for j=1,3 do
								--print("retry seg:",reset," of ",finish," wiggle Length: ",j)
								do_the_local_wiggle_campon(reset,reset+j-1,wiggle_params)
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
			end -- step wiggle

		reset_protein()
		recentbest.Restore()
		wiggle_params = {}
		wiggle_params.local_wiggle = 12
		wiggle_params.local_tolerance = threshold
		wiggle_params.sideChain_count = 15
		wiggle_params.shake = 5
		wiggle_params.all_count = 15

		step_wiggle(1,g_segments,wiggle_params)
	end -- moon walker

	function PiWalkerCamponV2(threshold)
		--
		--print("Starting pi walker campon V2...")

		-- rewrite of pi_walker_campon
		-- author srssmith92 6June2010
		-- (LF/TAB converted)

		g_segments = structure.GetCount()

			function mynextmode(number,maximum)
				number = number + 1
				if number > maximum then
					number = 1
				end
				return number
			end -- mynextmode

			function get_protein_score(segment_count)
				return current.GetScore()
			end --get protein score

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
			end -- rotate pattern

			function unfreeze_protein()
				freeze.UnfreezeAll()
			end -- unfreeze protein

			function freeze_segments(start_index,pattern_list)
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
			end -- freeze segments

			function do_the_local_wiggle_campon(first,last,wiggle_params)
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
					--print("    start ",start_score," end ", end_score)
				until end_score < start_score + wiggle_params.local_campon_tolerance
				if beginning_score + wiggle_params.local_campon_tolerance < end_score then
					points_increased = true
				end
				--recentbest.Restore()
				return points_increased
			end -- do the local wiggle campon

			function do_a_local_wiggle(current_pattern, current_segment, end_segment, last_current_segment, last_end_segment, pattern_list, wiggle_params)
				local saved_changed
				saved_changed = do_the_local_wiggle_campon(current_segment, end_segment, wiggle_params)
				if saved_changed then
					-- now back up the pattern list
					if last_current_segment ~= nil then
						--print("retry segs: ", last_current_segment, " to ", last_end_segment)
						do_the_local_wiggle_campon(last_current_segment, last_end_segment, wiggle_params)
						--print("retry segs: ", current_segment, " to ", end_segment)
						do_the_local_wiggle_campon(current_segment, end_segment, wiggle_params)
					end
				end
				last_current_segment = current_segment
				last_end_segment = end_segment
				current_segment = end_segment + 2
				end_segment = current_segment + pattern_list[current_pattern] - 2
				current_pattern = mynextmode(current_pattern,pattern_length)
				return current_pattern, current_segment, end_segment, last_current_segment, last_end_segment
			end -- do a local wiggle

			function local_wiggle_segments(first_frozen_segment,pattern_list,wiggle_params)
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
					--print("segs: ", current_segment, " to ", end_segment)
				current_pattern, current_segment, end_segment, last_current_segment, last_end_segment = do_a_local_wiggle(current_pattern, current_segment, end_segment, last_current_segment, last_end_segment, pattern_list, wiggle_params)
				until end_segment > g_segments

				if current_segment <= g_segments then
					--print("last segs: ", current_segment, " to ", end_segment)
					do_a_local_wiggle(current_pattern, current_segment, g_segments, last_current_segment, last_end_segment, pattern_list, wiggle_params)
				end
			end -- local wiggle segments

			function freeze_wiggle(pattern_list, wiggle_params)
				local i
				for i = 1,pattern_list[1] do
					freeze_segments(i, pattern_list)
					recentbest.Restore()
					local_wiggle_segments(i, pattern_list, wiggle_params)
				end
			end -- freeze wiggle

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
			end --verify pattern list

		pattern_list = {2,3,3,4} -- distance between frozen segments. Change this to what you want. Experiment 2,2,3,3,4,4, whatever
		pattern_length = #pattern_list
		pattern_list_ok = verify_pattern_list(pattern_list,g_segments)

		wiggle_params = {}
		wiggle_params.local_wiggle = 12
		wiggle_params.local_campon_tolerance = threshold
		if pattern_list_ok then
			for pattern_count = 1, pattern_length do
				freeze_wiggle(pattern_list, wiggle_params)
			end
			unfreeze_protein()
		else
			--print("Pattern list contains a 1, or an element greater than ", g_segments, " quitting")
		end
	end --pi walker campon

	function Power_Walker_fn()
		--print("Starting Power Walker...")
		g_segments = structure.GetCount() --total number of segments in puzzle, last seg
		g_total_score = 0   --  recent best to compare to and see if score was improved
		g_startSeg = 1 		--  segment to start with
		----------------------------- Begin walk_it() -------------------------------

		-- Global Variable Dependencies: g_total_score
		-- Function Dependencies: last_seg(), next_seg()

		function walk_it(seg,step,time)
		 selection.DeselectAll()
		 selection.SelectRange(seg, (seg+step))
		 g_total_score = current.GetScore()
		 structure.LocalWiggleSelected(time)
		 recentbest.Restore()
		 if((current.GetScore() - g_total_score) >= 0.05)then
		  last_seg(seg, step,time)
		 else
		  next_seg(seg, step,time)
		 end
		end

		----------------------------- Begin next_seg() -------------------------------

		-- Global Variable Dependencies: N/A
		-- Function Dependencies: walk_it()

		function next_seg(seg, step,time)
		if((seg + step) == g_segments)then
		   return nil
		else
		 if(step == 1)then
		  step = 2
		 else
		  step = 1
		  seg = seg + 1
		 end
		end
		 walk_it(seg, step,time)
		end

		----------------------------- Begin last_seg() -------------------------------

		-- Global Variable Dependencies: N/A
		-- Function Dependencies: N/A

		function last_seg(seg, step,time)
		 if(step == 2)then
		  step = 1
		 else
		  seg = seg - 1
		 end
		 if(seg == 0)then
		  seg = 1
		 end
		 walk_it(seg, step,time)
		end

		---------------------------- Begin end_it_all() ----------------------------------

		function end_it_all()
		print (finished)
		end

		--------------------------- Script Execution Begin -----------------------------
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
			
	end -- Power_Walker_fn
	
	function Precise_LWS_fn()
		--print("Starting PreciseLWS 1.761...")
		--Precise LWS by rav3n_pl
		--searches and wiggles worst segments
		--options at end of script

		local function p(s1,s2,s3,s4,s5) --"quicker" print ;]
			print(s1,s2,s3,s4,s5)
		end
		local function score() --score of puzzle
			s=current.GetScore()
				if s==0 then
					for i=1, structure.GetCount() do
						s=s+current.GetSegmentEnergyScore(i)
					end
					s=s+8000	
				end
			return s
		end

		local function getworst() --fill score table
			worst={}
			for i=1, structure.GetCount() do 
				sc=current.GetSegmentEnergyScore(i)
				worst[i]=sc
			end
			return worst
		end

		local function wig(mingain)	--score conditioned wiggle,
			repeat					--wiggles selected segments
				ss=score()
				structure.LocalWiggleSelected(1)
				se=score()
				wg=se-ss
				--p("Wiggle gain: ",wg)
				if wg<0 then
					--p("Restored...")
					recentbest.Restore()
				end
			until wg<mingain 
			selection.DeselectAll()
			freeze.UnfreezeAll()
		end

		local function wiggle(s, mingain, buddies)
			--p("Wigglin segment ",s)
			selection.DeselectAll()
			freeze.UnfreezeAll()
			sgs=score()
			maxi=structure.GetCount()
			if s+1<=maxi then selection.Select(s+1)end
			if s-1>=1 then selection.Select(s-1)end 
			freeze.FreezeSelected(true, true)
			selection.DeselectAll()
			selection.Select(s)
			wig(mingain)
			
			if buddies > 0 then --select buddies
				for b=1, buddies do
				
					if s+b+1<=maxi then selection.Select(s+b+1)end
					if s-1>=1 then selection.Select(s-1)end 
					freeze.FreezeSelected(true, true)
					selection.DeselectAll()
					if s+b>maxi then selection.SelectRange(s,maxi)
					else selection.SelectRange(s,s+b)end
					wig(mingain)

					if s+1<=maxi then selection.Select(s+1)end
					if s-b-1>=1 then selection.Select(s-b-1)end 
					freeze.FreezeSelected(true, true)
					selection.DeselectAll()
					if s-b<1 then selection.SelectRange(1,s)
					else selection.SelectRange(s-b,s)end
					wig(mingain)

					if s+b+1<=maxi then selection.Select(s+b+1)end
					if s-b-1>=1 then selection.Select(s-b-1)end 
					freeze.FreezeSelected(true, true)
					selection.DeselectAll()
					if s+b>maxi then selection.SelectRange(s,maxi)
					else selection.SelectRange(s,s+b)end
					if s-b<1 then selection.SelectRange(1,s)
					else selection.SelectRange(s-b,s)end
					wig(mingain)
				end
			end
			sge=score()
			--p("Segment gain: ",sge-sgs)
		end

		function wiggleworst(howmany, mingain, buddies)
			behavior.SetClashImportance(1)
			freeze.UnfreezeAll()
			selection.DeselectAll()
			recentbest.Restore()
			sscore=score()
			worst=getworst()
			for i=1, howmany do
			--p(howmany+1-i, " segments left to do.")
				min=worst[1]
				seg=1
				for f=2,structure.GetCount() do
					if min>worst[f] then 
						min=worst[f]
						seg=f
					end
				end
				wiggle(seg, mingain, buddies)
				worst[seg]=9999--never again same one
			end
			escore=score()
			--p("Total gain: ", escore-sscore, " pts")
		end

		howmany = 20 	--how many worst segments to process
		mingain = 0.1 	--minimum gain per wiggle iterations (if more per 1 wiggle wiggles again)
		buddies = 4 	--how many segments aside should be wibbled too
						--ie worst segment is no 44 and buddies set to 1 then
						-- willging seg 44 then 43+44; later seg 44+45 and finally 43+44+45
		wiggleworst(howmany, mingain, buddies)
	end -- Precise_LWS_fn

	function s_ws_wa_whatever()
		--print("Starting s_ws_wa_whatever...")
		selection.SelectAll()
		i=0
		while true do
			behavior.SetClashImportance(1)
			i=i+1
			ss=current.GetScore()
			--print("Iter ",i," start at score ",ss)
			structure.ShakeSidechainsSelected(1)
			structure.WiggleAll(1,false,true)
			structure.LocalWiggleAll(1)
			behavior.SetClashImportance(0.2)
			structure.MutateSidechainsSelected(1)
			behavior.SetClashImportance(1)
			structure.LocalWiggleAll(2)
			gain=current.GetScore()-ss
			--print("Gain:  ",gain)
			if gain<0.1 then break end
		end
	end -- s_ws_wa_whatever

	function SdHowMany(startNum, howmany)
		--startNum is the HH to start with
		--howmany is the highest HH to execute.  Range is from 2 to numSegs/2	
		--print("Starting SdHowmany from ", startNum, " to ", howmany,  " ...")
		--[[
			SdWalkAllHH version 1.0
			Roughly LUA HH2 through HH?? executed consecutively
			This code is based on a LUA version of the Helix Hula scripts.  
		]]--

			function HH(h,segFirst,segLast)	--this is based on a LUA version of the HelixHula code
				for g=0,h-1 do				--for each starting position 
					--print('  Beginning with position ',g+1)
					recentbest.Restore()
					for j=segFirst+g,segLast,h do		--do a local wiggle on each of the segments
						k=j-h+1
						m=j+h-1
						if k<1 then k=1 end
						if m>segLast then m=segLast end
						selection.SelectRange(k,m)			
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
				--sn is the starting HH.  hm is the highest HH to execute.  Range is from 2 to numSegs/2	
				behavior.SetClashImportance(1)
				freeze.UnfreezeAll()
				deletebands()
				selection.SelectAll()					--set everything to a loop
				structure.SetSecondaryStructureSelected('L')  					
				selection.DeselectAll()
				recentbest.Restore()
				scoreStart=current.GetScore()
				--print('Starting at score ', scoreStart)
				segF=1							--the first segment number to be processed
				segL=structure.GetCount()		--the last segment number to be processed
				for	hhn=sn,hm do					--main loop, each iteration is roughly one HH
					--print('Executing HH',hhn)	
					HH(hhn,segF,segL)
					recentbest.Restore()
					--print('Score at end of HH', hhn, ' is ', current.GetScore())
				end
				--print('Score improved by: ', current.GetScore() - scoreStart)
				--print('And all done!')
			end -- SdWalkAllHH
		SdWalkAllHH(startNum, howmany)
	end -- SdHowMany
	
	function Stabilize_fn()
		--print("Starting Stabilize 3.0.7...")

		segCount=structure.GetCount()

		function Score()
		   return current.GetScore()
		end 

		function Round(x)--cut all afer 3-rd place
		   return x-x%0.001
		end
		function Down(x)--cut all afer comma
		   return x-x%1
		end

		function SelectSphere(sg, radius)
		   selection.DeselectAll()
		   for i=1, segCount do
			  if structure.GetDistance(sg,i)<radius then selection.Select(i) end
		   end
		end

		function PartialScoreTable() --fill score table
		   local scr={}
		   for i=1, segCount do
			  scr[i]=current.GetSegmentEnergyScore(i)--get partial scores
		   end
		   return scr
		end

		function GetWorst(sctbl)
		   local min=sctbl[1]
		   local wrst=1
		   for x=2, #sctbl do
			  if sctbl[x]<min then 
				 wrst=x
				 min=sctbl[x]
			  end
		   end
		   sctbl[wrst]=99999
		   return wrst
		end

		function Gibaj(jak, iters, minppi) --score conditioned recursive wiggle/shake
		   if jak==nil then jak="wa" end
		   if iters==nil then    iters=6 end
		   if minppi==nil then minppi=0.4 end
		   
		   if iters>0 then
			  iters=iters-1
			  local sp=Score()
			  if jak == "s" then structure.ShakeSidechainsSelected(1)
				 elseif jak == "wb" then structure.WiggleAll(1,true, false)
				 elseif jak == "ws" then structure.WiggleAll(1,false,true)
				 elseif jak == "wa" then structure.LocalWiggleAll(1) 
			  end
			  local ep = Score()
			  local ig=ep-sp
			  if ig > minppi then Gibaj(jak, iters, minppi) end
		   end
		end

		function wss(minppi)
		   repeat
			  local ss=Score()
			  structure.WiggleAll(1,false,true)
			  structure.ShakeSidechainsSelected(1)
			  g=Score()-ss
		   until g<minppi
		end

		function wig(mingain)   --score conditioned local wiggle,
		   repeat               --wiggles selected segments
			  local ss=Score()
			  structure.LocalWiggleSelected(2)
			  local wg=Score()-ss
			  if wg<0 then
				 recentbest.Restore()
			  end
		   until wg<mingain 
		end

		function StabilizeWorstSphere(sgmnts)
		   sgmnts=Down(sgmnts)
		   recentbest.Restore()
		   sctbl=PartialScoreTable()
		   for i=1, sgmnts do
			  local found=flase
			  local wrst=0
			  wrst=GetWorst(sctbl)
			  --P(sgmnts+1-i," more spheres to fix. Now fixing: ",wrst)
			  selection.DeselectAll()
			  selection.Select(wrst)
			  wig(20)
			  SelectSphere(wrst,11)
			  wss(1)
			  wig(20)
		   end
		end

		function Stabilize(maxLoops)
		   behavior.SetClashImportance(1)
		   local sstart= Score()
		   --P("Starting score: ",Round(sstart))
		   for iters = 1, maxLoops do
			  local ss=Score()
			  selection.SelectAll()
			  wss(2)
			  StabilizeWorstSphere(segCount/20)
			  local gain=Score()-ss
			  --P("WSS LWS loop ",iters," gain: ",Round(gain))
			  if gain<200 then break end
		   end 
		   selection.SelectAll()
		repeat
		local ss=Score()
		wss(2)
		   Gibaj()
		local g=Score()-ss
		until g<20
		   send=Score()
		   --P("Total improved by: ", Round(send-sstart), " points.")
		   --P("End score: ", Round(send))
		end 
		maxLoops=10
		Stabilize(maxLoops)
	end -- Stabilize_fn

	function TotalLWS(threshold)
		--print("Starting Total LWS...")
		--total lws
		--totalLwsInternal(minlen,maxlen, minpp)
		--minlen - minimum lenggh of sgmnts - if you have done lws by 1 and 2 you may want set it to 3
		--maxlen - maximum lenght of sgments - more than 7 looks useless
		--minppi - minimum gain per local wiggle iter

		--P=print --"quicker" print ;]

			local function score() --score of puzzle
				return current.GetScore()
			end -- score

			function AllLoop()
				selection.SelectAll()
				structure.SetSecondaryStructureSelected("L")
			end -- allLoop

			function freezeT(start, len)
				freeze.UnfreezeAll()
				selection.DeselectAll()
				for f=start, maxs, len+1 do
					if f<= maxs then selection.Select(f) end
				end
				freeze.FreezeSelected(true, false)
			end -- freeze

			function lw(minppi)
				local gain=true
				while gain do
					local ss=score()
					structure.LocalWiggleSelected(2)
					local g=score()-ss
					if g<minppi then gain=false end
					if g<0 then recentbest.Restore() end
				end
			end -- lw

			function wiggle(start, len,minppi)
				if start>1 then
					selection.DeselectAll()
					selection.SelectRange(1,start-1)
					lw(minppi)
				end
				for i=start, maxs, len+1 do
					selection.DeselectAll()
					local ss = i+1
					local es=i+len
					if ss >= maxs then ss=maxs end
					if es >= maxs then es=maxs end
					selection.SelectRange(ss,es)
					lw(minppi)
				end
			end -- wiggle

			function totalLwsInternal(minlen,maxlen, minppi)
				freeze.UnfreezeAll()
				selection.DeselectAll()
				behavior.SetClashImportance(1)
				save.SaveSecondaryStructure()
				AllLoop()
				maxs=structure.GetCount()
				local ssc=score()
				--print("Starting Total LWS: ",ssc)
				--print("Lenght: ",minlen," to ",maxlen," ;minimum ppi: ",minppi)
				for l=minlen, maxlen do
					for s=1, l+1 do
						--print("Len: ",l," ,start point: ",s)
						local sp=score()
						freezeT(s,l)
						recentbest.Restore()
						wiggle(s,l,minppi)
						--print("Gained: ",score()-sp)
						save.Quicksave(3)
					end
				end
				--print("Finished! Total gain: ",score()-ssc)
				save.LoadSecondaryStructure()
			end -- total lws

		--totalLwsInternal(minlen,maxlen, minpp)
		--minlen - minimum lenggh of sgmnts - if you have done lws by 1 and 2 you may want set it to 3
		--maxlen - maximum lenght of sgments - more than 7 looks useless
		--minppi - minimum gain per local wiggle iter
		totalLwsInternal(1,7,threshold)
	end -- total LWS

	function walker_1point1_fn()
		--print("Starting Walker 1.1...")
		segCount = structure.GetCount()

		function Score()
			return current.GetScore()
		end 

		bestScore=Score()

		function round(x)--cut all afer 3-rd place
			return x-x%0.001
		end

		function SelectSphere(sg, radius,nodeselect)
			if nodeselect~=true then selection.DeselectAll() end
			for i=1, segCount do
				if structure.GetDistance(sg,i)<radius then selection.Select(i) end
			end
		end

		function Gibaj(jak, iters, minppi) --score conditioned recursive wiggle/shake
			if jak==nil then jak="wa" end
			if iters==nil then 	iters=6 end
			if minppi==nil then minppi=0.04 end
			
			if iters>0 then
				iters=iters-1
				local sp=Score()
				if jak == "s" then structure.ShakeSidechainsSelected(1)
					elseif jak == "wb" then structure.WiggleAll(1,true, false)
					elseif jak == "ws" then structure.WiggleAll(1,false,true)
					elseif jak == "wa" then structure.LocalWiggleAll(1) 
				end
				local ep = Score()
				local ig=ep-sp
				if ig > minppi then Gibaj(jak, iters, minppi) end
			end
		end

		function wig(mingain)	--score conditioned local wiggle,
			repeat					--wiggles selected segments
				local ss=Score()
				structure.LocalWiggleSelected(2)
				local se=Score()
				local wg=se-ss
				if wg<0 then
					recentbest.Restore()
				end
			until wg<mingain 
		end

		function wsw(minppi)
			behavior.SetClashImportance(1)
			local nows=false
			repeat
				local ss=Score()
				if nows==false then structure.WiggleAll(1,false,true) end
		if shake==true then structure.ShakeSidechainsSelected(1) end
				local shs=Score()
				structure.WiggleAll(2, false, true)
				local ws=Score()
				local g=ws-ss
				nows=true
				if ws-shs<minppi/10 then break end
			until g<minppi
		end

		function test()
			local gain = Score() - bestScore
			if gain > 0 then 
				--print("Improved by: ", round(gain))
				bestScore = Score()
				save.Quicksave(3)
			elseif gain<0 then 
				save.Quickload(3)
			end
		end

		function Walker()
			local ss=Score()
			if endS==nil then endS=segCount end
			
			recentbest.Restore()
			save.Quicksave(3)
			behavior.SetClashImportance(1)

			--print("Walker started.")
			for l=minlen,maxlen do
				for i=startS, endS-l do
					--print("Sgmnt ",i," len: ",l)
					selection.DeselectAll()
					selection.SelectRange(i,i+l-1)
					if doWSW then wsw(minppi) end
					wig(minppi)
					test()	
				end
			end
			
			--print("Totoal improved by: ",round(Score()-ss))
		end

		minppi=0.0002
		startS=1 --start segment to walk
		endS=nil --end segment to walk -nil=end of protein
		minlen=1
		maxlen=13
		doWSW=true --false --set to true if it have to shake/wiggle sidechains too
		shake=false

		Walker()
	end -- walker_1-1_fn
	
	function WormLWS(threshold)
		--
		--print("Starting worm LWS...")
		--[[
		Worm LWS
		Performin "worm" LWS by given patterns, no freezing
		]]--

		p=print --"quicker" print ;]
		segCount=structure.GetCount()

			local function Score() --Score of puzzle
				return current.GetScore()
			end -- score
			function round(x)
				return x-x%0.001
			end -- round

			function AllLoop()
				local ok=false
				for i=1, segCount do
					local ss=structure.GetSecondaryStructure(i)
					if ss~="L" then 
						save.SaveSecondaryStructure()
						ok=true
						break
					end
				end
				if ok then
					selection.SelectAll()
					structure.SetSecondaryStructureSelected("L")
				end
			end -- allLoop

			function lw(minppi)
				local gain=true
				while gain do
					local ss=Score()
					structure.LocalWiggleSelected(2)
					local g=Score()-ss
					if g<minppi then gain=false end
					if g<0 then recentbest.Restore() end
				end
			end -- lw

			function Worm()
				if sEnd==nil then sEnd=segCount end
				AllLoop()
				recentbest.Restore()
				save.Quicksave(3)
				local ss=Score()
				for w=1,#pattern do
					len=pattern[w]
					local sw=Score()
					--print("Starting Worm of len ",len,", score: ",round(Score()))
					for s=sStart,sEnd-len+1 do
						selection.DeselectAll()
						selection.SelectRange(s,s+len-1)
						lw(minppi)
					end
					--print("Pattern gain: ",round(Score()-sw))
					save.Quicksave(3)
				end
				selection.DeselectAll()
				save.LoadSecondaryStructure()
				--print("Total Worm gain: ",round(Score()-ss))
			end -- worm

		pattern={5,2,11,3,13,7,1} --how many segments at once to LWS
		sStart=1 --from segment
		sEnd=nil --to segment, nil=end of it
		minppi=threshold -- 0.0001 --minimum point gain per 2 wiggles, ie 1 for fassst and 0.0001 for loooooooong

		Worm()
	end -- worm LWS

	
	function FinishWalker()
		local scr = current.GetScore()
		print("   **Score at end = ", scr, "**", " (", os.date(), ")")
		behavior.SetClashImportance(1)
		freeze.UnfreezeAll()
		deletebands()
		selection.SelectAll()					--set everything to a loop
		structure.SetSecondaryStructureSelected('L')  					
		selection.DeselectAll()
		if scr < scoreOurCurrent then
			scr = scoreOurCurrent
			save.Quickload(8)
			print("   Resetting to score = ", scr)
		else save.Quicksave(8)
			scoreOurCurrent = scr
		end
		save.LoadSecondaryStructure()
	end -- FinishWalker

--START Archive in Notes, -- New 4/11/2014; 3/12/2015 added a flag for already used recipe

FlagRecipeUsed=false
function recipeUsed(lastnote) -- identifies if the recipe has already been used
	local lastnote=lastnote or "abcdefgh"
	if lastnote:find(recipename)~=nil then
		FlagRecipeUsed=true
		print(recipename .. " already used before")
	end
end

function SelectNote(recipename)
	store={}
	store.label=recipename or "" -- edit here the recipe name
	store.note_number=structure.GetCount()
	for seg=structure.GetCount(),1,-1 do
	  if structure.GetNote(seg)~="" then recipeUsed(structure.GetNote(seg)) break end -- New 3/12/2015
	  store.note_number=seg
	end
	print(string.format("Recording results in Note for segment %i",store.note_number))
	store.starting_score=scoreOurStart
	--structure.SetNote(store.note_number,string.format("(%s) %.3f + FSP",user.GetPlayerName(),store.starting_score))
end

SelectNote(recipename)

function WhriteNote(loop_nb) -- all inits are in SelectNote function
	local loop_count= loop_nb or 1
	structure.SetNote(store.note_number,string.format("(%s) %.3f + %s(%i) %.3f",user.GetPlayerName(),store.starting_score,store.label,loop_count,scoreOurCurrent))
end

--END Archive in Notes	
	
function Cleanup(err) -- NEW BK 10/10/2013
	scoreOurCurrent = current.GetScore()
	WhriteNote(gen)  -- New 4/11/2014
	print("****Total score change = ", scoreOurCurrent - scoreOurStart, "****")
	deletebands()
    print(err)
end
	
--******main code body****************************************
--******IMPORTAT NOTE uses save.Quicksave slot #8

function MAIN()
	save.SaveSecondaryStructure()
	behavior.SetClashImportance(1)
	freeze.UnfreezeAll()
	deletebands()
	selection.SelectAll()					--set everything to a loop
	structure.SetSecondaryStructureSelected('L')  					
	selection.DeselectAll()
	recentbest.Save()
	save.Quicksave(8)
	scoreOurStart = current.GetScore()
	scoreOurCurrent = scoreOurStart
	print("**Starting score = ", scoreOurStart, "**")
	cntTimes = 0
	while true do --forever!
		cntTimes = cntTimes + 1
		StartWalker(cntTimes, 1, 15, "SdHowMany", from, 2, to, 4);	SdHowMany(2,4);				FinishWalker()
		StartWalker(cntTimes, 2, 15, "Pi Walker Campon V2");		PiWalkerCamponV2(0.0001);	FinishWalker()
		StartWalker(cntTimes, 3, 15, "Worm LWS");					WormLWS(0.0001);			FinishWalker()
		StartWalker(cntTimes, 4, 15, "SdHowMany", from, 8, to, 25);	SdHowMany(8, 25);			FinishWalker()
		StartWalker(cntTimes, 5, 15, "Total LWS");					TotalLWS(0.0001);			FinishWalker()
		StartWalker(cntTimes, 6, 15, "M3 Wiggle sequence");			M3wigglwSequence(0.0001);	FinishWalker()
		StartWalker(cntTimes, 7, 15, "Walker 1.1");					walker_1point1_fn();		FinishWalker()
		StartWalker(cntTimes, 8, 15, "SdHowMany", from,26, to, 32);	SdHowMany(26,32);			FinishWalker()
		StartWalker(cntTimes, 9, 15, "Power_Walker_fn");			Power_Walker_fn();			FinishWalker()
		StartWalker(cntTimes, 10, 15, "s_ws_wa_whatever");			s_ws_wa_whatever();			FinishWalker()
		StartWalker(cntTimes, 11, 15, "Precise LWS");				Precise_LWS_fn();			FinishWalker()
		StartWalker(cntTimes, 12, 15, "SdHowMany", from, 5, to, 7);	SdHowMany(5, 7);			FinishWalker()
		StartWalker(cntTimes, 13, 15, "Moon Walker");				MoonWalker(0.0001);			FinishWalker()
		StartWalker(cntTimes, 14, 15, "Stabilize 3.0.7");			Stabilize_fn();				FinishWalker()
		StartWalker(cntTimes, 15, 15, "Krog Walker V4");			KrogWalkerV4(0.0001);		FinishWalker()
		WhriteNote(cntTimes)
		print("****All walkers done ", cntTimes, " times****", " (", os.date(), ")")
		printTime()
		print("****Total score change so far = ", scoreOurCurrent - scoreOurStart, "****")
	end --main code body
end

xpcall(MAIN,Cleanup)
