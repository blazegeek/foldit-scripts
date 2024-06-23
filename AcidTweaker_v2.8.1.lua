--Acid Tweaker v2.5
--Acid Tweaker  v1.78 by Steven Pletsch
--modded by rav3n_pl;]
-- modded by BitSpawn, March 2012
-- v2.00: LUAV2, thanks Timo
-- modded by B.Kestemont, March 2013
-- v2.1:  bug fixed on rotamers, set default as in v1.78
-- v2.2 Bug fixed on structure.WiggleAll (replaced by structure.WiggleSelected)
-- management of slow filters and cleaned BK 8/4/2013
--adding starting score in the log BK 20 Sept 2013
--v2.2.1 adding range of seg in user inputs BK 20 Sept 2013
--v2.3.0 adding sphere_worst and automatic improvement on further loops in order to get the
--full power of original Acid Tweaker  v1.78 by Steven Pletsch for long run. BK 8 Oct 2013
--adding report with zone of substantial gains.
--reducing info in log to only gaining segments
--adding successive loops management with more and more desperate options
--adapted for exploration puzzle scores  18/10/2013
--added puzzleprop for later & draft adapted for centroid 25/10/2013
--8/4/2013 loops of 2 wiggles in place of 1 end each loop (susume says to wiggle by 2, I obey)
--v2.4.0 public
--v2.4.5 debugged line 73
--v2.5 filters and some small changes for optimisation
--v2.5.1 GENERICFILTER only after dialog (test), FILTERMANAGEMENT in dialog
--v2.5.2 debugged in detectligand (secCnt2 problem)
--v2.5.3 changed default filter management (filters are not always so slow)
-- and I think it's better to keep filters for Contacts and H-Bonds
--v2.6.0 added different walkers (random, reverse etc)
--v2.6.1 fixed MixInwardTable bug on impair puzzles
--v2.6.2 fixed unideal loop GENERICFILTER bug
--v2.6.3 tried to fix GENERICFILTER bug again and added mutate option
--v2.6.4 and tried again to fix GENERICFILTER on recentbest (see feedback discussion, Foldit Bug)
--       replaced by FakeRecentBestSave() and FakeRecentBestRestore()   29/8/2017
--v2.6.5 Ligand detection in dialog
--v2.7  dialog to limit to rotamers (like in pauldun versions of AT).
--v2.7.1 fixed MixInwardTable bug again, thanks to robgee
--       filters to bonuses or objectives recognition
--v2.8 GRRR adapted filter setting to new lua commands: return2GlobalOriginalFilterSetting()
--v2.8.1 original filter setting on start

--		Remembering that before dialog, generic filter doesn't work, so filters are on or off for initial scores.
--        If still BUG, add lines 927-928 ?


--Slots---------------
--3 = best
--4 = best temp rotamer
--5 = recent best archive (for dbugging recentbest Foldit BUG on filtered puzzles)






recipename="Acid Tweaker 2.8.1"
g_segments = structure.GetCount() -- total number of segments in puzzle
g_total_score = 0 -- recent best to compare to and see if score was improved
g_score = {} -- array of segment scores for comparisons (total for segment)
normal= (current.GetExplorationMultiplier() == 0)
startRecTime=os.clock () -- New BK 23/10/13
p=print --a short
OriginalFilterSetting = filter.AreAllEnabled()

--Start MIX TABLE inits

segCnt=structure.GetCount()
flagligand=false
segCnt2=segCnt -- ligands
while structure.GetSecondaryStructure(segCnt2)=="M" do segCnt2=segCnt2-1 end
segStart=1 --start from
segEnd=segCnt2 --end seg
--WORKON={{segStart,segCnt2}}
WORKONBIS={} -- the table to use is a simple list of segments in any order
compteur=0
	for i = segStart, segEnd do -- basic list of segments (init of WORKONBIS)
			compteur=compteur+1
			WORKONBIS[compteur]=i
	end
mixtables=1
randomly=false
--End MIX TABLE inits

segCount=segCnt

--TO DO: some wiggle in order to activate the filter bug ?

--check for filter bug 24/8/2018
if not OriginalFilterSetting then
	print("Filter disabled on start, is that intended ?")
	local function CheckUserFilterPrefDIALOG()
		local dlg = dialog.CreateDialog("Are you sure ?")
		dlg.L1=dialog.AddLabel("Filter disabled on start, is that intended ?!?")
		dlg.ok = dialog.AddButton("YES", 0)
		dlg.cancel = dialog.AddButton("NO !", 1)
		
		if dialog.Show(dlg) > 0 then
			print("Enabling filter by default")
			filter.EnableAll()		
		end
	end
	CheckUserFilterPrefDIALOG()
end


FILTERMANAGEMENT=false
CENTROID=false -- new BK 20/10/2013
CONTACTS = false
HBONDS= false
badpuzzle={'999'} -- list of not implemented puzzles - to be edited on each bug with puzzle nb

function return2GlobalOriginalFilterSetting()
	if OriginalFilterSetting then -- if true, all filters are default enabled
		filter.EnableAll()	--Enables all filters
	else
		filter.DisableAll()	--Disables all filters
	end

end

--START Generic Filter Management by BitSpawn 21/12/2014
--Source: http://fold.it/portal/node/1998917
PROBABLEFILTER=false
GENERICFILTER=false
--identifying filtered puzzles
function detectfilter()
	local descrTxt=puzzle.GetDescription()
	if #descrTxt>0 and (descrTxt:find("filter") or descrTxt:find("filters") or descrTxt:find("Bonus") or descrTxt:find("bonuses")
	  or descrTxt:find("bonus") or descrTxt:find("Objectives") or descrTxt:find("Filters")) then
		PROBABLEFILTER=true
		print("Bonus active")
	end
	return
end
detectfilter()

-- function to copy class/table


function CopyTable(orig)

    local copy = {}

    for orig_key, orig_value in pairs(orig) do

        copy[orig_key] = orig_value  

    end

    return copy

end

-- functions for filters

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

-- function to overload a funtion

function mutFunction(func)

    local currentfunc = func

    local function mutateFunc(func, newfunc)

        local lastfunc = currentfunc

        currentfunc = function(...) return newfunc(lastfunc, ...) end

    end

    local wrapper = function(...) return currentfunc(...) end

    return wrapper, mutateFunc

end

-- function to overload a class

-- to do: set the name of function

classes_copied = 0

myclcp = {}

function MutClass(cl, filters)

    classes_copied = classes_copied+1

    myclcp[classes_copied] = CopyTable(cl)

    local mycl =myclcp[classes_copied]

    for orig_key, orig_value in pairs(cl) do

        myfunc, mutateFunc = mutFunction(mycl[orig_key])

        if filters==true then

            mutateFunc(myfunc, function(...)

                FiltersOn()

                if table.getn(arg)>1 then

                    -- first arg is self (function pointer), we pack from second argument

                    local arguments = {}

                    for i=2,table.getn(arg) do

                        arguments[i-1]=arg[i] 

                    end

                    return mycl[orig_key](unpack(arguments))

                else

                    --print("No arguments")

                    return mycl[orig_key]()

                end

            end)   

            cl[orig_key] = myfunc

        else

            mutateFunc(myfunc, function(...)

                FiltersOff()

                if table.getn(arg)>1 then

                    local arguments = {} 

                    for i=2, table.getn(arg) do

                        arguments[i-1]=arg[i]  

                    end

                    return mycl[orig_key](unpack(arguments))

                else

                    return mycl[orig_key]()

                end

            end)   

            cl[orig_key] = myfunc
        end
    end
end

-- how to use:
--setting default options if filters BK 4/2/2015
--MutClass(structure, false)
--MutClass(band, false)
--MutClass(current, true)
--[[ it does not work good here, testing it in dialog
if GENERICFILTER then
	MutClass(structure, false)
	MutClass(band, true)
	MutClass(current, true)
	MutClass(recentbest, true)
	MutClass(save, true)
	print("Disabling filters always but for scoring")
end
]]--		
--STOP Generic Filter Management



indexligand={} -- not used here yet
	--Detect ligands (from Jean-Bob)
function DetectLigand()
	local lastSeg1=structure.GetCount()
	local lastSeg2=lastSeg1
   while structure.GetSecondaryStructure(lastSeg1)=="M" do
		flagligand=true
		lastSeg1=lastSeg1-1
	end
	if lastSeg1+1==lastSeg2 then indexligand={lastSeg2}
	else indexligand={lastSeg1, lastSeg2} end
	segCnt2=lastSeg1
end
DetectLigand()

function puzzleprop() -- by Bruno Kestemont 20/10/2013, Simplified for AT
	local descrTxt=puzzle.GetDescription()
	--p(true,descrTxt)
	local puzzletitle=puzzle.GetName()
	--p(true,puzzletitle)
	if #puzzletitle>0 then
		for i=1,#badpuzzle do
			if puzzletitle:find(i) then -- check if not bizarre puzzle
			NOTIMPLEMENTED=true
			end
		end
		if (puzzletitle:find("Sym") or puzzletitle:find("Symmetry") or puzzletitle:find("Symmetric")
				or puzzletitle:find("Dimer") or puzzletitle:find("Trimer") or puzzletitle:find("Tetramer")
				or puzzletitle:find("Pentamer")) then
			PROBABLESYM=true
			if puzzletitle:find("Dimer") and not puzzletitle:find("Dimer of Dimers") then sym=2		
			elseif puzzletitle:find("Trimer") or puzzletitle:find("Tetramer") then sym=3
			elseif puzzletitle:find("Dimer of Dimers") or puzzletitle:find("Tetramer") then sym=4
			elseif puzzletitle:find("Pentamer") then sym=5
			else --SymetryFinder() debugged 03/06/2014
			end
		end
	end
	if #descrTxt>0 and (descrTxt:find("Sym") or descrTxt:find("Symmetry") or descrTxt:find("Symmetric")
			or descrTxt:find("sym") or descrTxt:find("symmetry") or descrTxt:find("symmetric")) then
		PROBABLESYM=true
		if (descrTxt:find("Dimer") or descrTxt:find("dimer"))
			and not (descrTxt:find("Dimer of Dimers") or descrTxt:find("dimer of dimers")) then sym=2 
		elseif descrTxt:find("Trimer") or descrTxt:find("trimer") then sym=3
		elseif (descrTxt:find("Dimer of Dimers") or descrTxt:find("Tetramer"))
			and not (descrTxt:find("dimer of dimers") or descrTxt:find("tetramer"))then sym=4 
		elseif descrTxt:find("Pentamer") or descrTxt:find("pentamer") then sym=5
		end
	end
	if #descrTxt>0 and (descrTxt:find("filter") or descrTxt:find("filters") or descrTxt:find("Bonus") or descrTxt:find("bonuses")
	  or descrTxt:find("bonus") or descrTxt:find("Objectives") or descrTxt:find("Filters")) then
		PROBABLEFILTER=true
		print("Bonus active")
	end
	if #puzzletitle>0 and puzzletitle:find("Sepsis") then -- new BK 17/6/2013
		SEPSIS=true
	end
	if #puzzletitle>0 and puzzletitle:find("Electron Density") then -- for Electron Density
		ELECTRON=true
	end
	if #puzzletitle>0 and puzzletitle:find("Centroid") then -- New BK 20/10/2013
		--p(true,"-Centroid")
		CENTROID=true
	end
	if #puzzletitle>0 and puzzletitle:find("Contacts") then -- New BK 20/10/2013
		CONTACTS=true
	end
	if #puzzletitle>0 and puzzletitle:find("H-Bonds") then -- New BK 20/10/2013
		HBONDS=true
	end
	return
end

-- Score functions -- NEW from tvd for exploration puzzles
function Score(pose)
    if pose==nil then pose=current end
    local total= pose.GetEnergyScore()
    -- FIX for big negatives

        if total < -999999 and total > -1000001 then total=SegScore(pose) end

    if normal then
        return total
    else
        return total*pose.GetExplorationMultiplier()
    end
end

function SegScore(pose) -- only used for big negatives and at init (for maximo setting)
    if pose==nil then pose=current end
    local total=8000
    for i=segStart, segEnd do -- all segments (only used at start recipe)
        total=total+pose.GetSegmentEnergyScore(i)
    end
    return total
end

function RBScore() -- not used yet
    return Score(recentbest)
end

--[[function Score()
    return current.GetEnergyScore()
end]]--

-- END score functions

--START Debugging Recentbest Foldit Bug Temporary solution of Foldit bug (BK 29/8/2017)

function FakeRecentBestSave()
	if PROBABLEFILTER then -- trying to solve the Foldit bug
		save.Quicksave(5)
	else
		recentbest.Save()
	end
end

function FakeRecentBestRestore()
	if PROBABLEFILTER then -- trying to solve the Foldit bug
		local ss=Score()
		recentbest.Restore() -- filter disabled (bug)
		local se=Score() -- now with the filter
		if se > ss then
			save.Quicksave(5)
		end
		save.Quickload(5)
	else
		recentbest.Restore()
	end
end




--END  Debugging Recentbest Foldit Bug


function ds(val)
    if MUTATE==true then
		if FILTERMANAGEMENT then filter.EnableAll() end-- 24/8/2017, always enable filter for mutate
        structure.MutateSidechainsSelected(val+1) -- Note: on GENERICFILTER, it will always be without filters !!
    else
        structure.ShakeSidechainsSelected(val)
    end
end

global_ci=1
function CI(val)
	global_ci=val
    behavior.SetClashImportance(global_ci)
end

function WiggleSimple(val,how)
		if FILTERMANAGEMENT then filter.DisableAll() end-- new BK 8/4/2013, always disable filter here
        if CENTROID then -- new BK 20/10/2013
			if how=="s" or how=="ws" then 
				how="wa"
			end
		end
		if how == "s" then ds(1) -- NB: filter always will be on for mutate, see ds()
            elseif how == "wb" then structure.WiggleSelected(val, true, false) -- backbones
            elseif how == "ws" then structure.WiggleSelected(val, false, true) -- sidechains
            elseif how == "wa" then structure.WiggleSelected(val, true, true) -- all
			elseif how== "lw" then structure.LocalWiggleSelected(val) -- new
			elseif how=="rb" then structure.RebuildSelected(1) -- don't use, it's chaotic
        end
		if FILTERMANAGEMENT then return2GlobalOriginalFilterSetting() end -- new BK 10/10/2013, always back to user settings
end

function WiggleAT(ss, how, iters, minppi)
    local valiter=2
    local val=1
    if fast==true then valiter=1 end
    if how==nil then how="wa" end
	if CENTROID then -- new BK 20/10/2013
		if how=="s" or how=="ws" then 
			how="wa"
		end
	end
    if iters==nil then iters=6 end
    minppi=(g_total_score-Score())/100
    if ((minppi==nil) or (minppi<0.001)) then
            minppi=0.001
    end
    if global_ci==1.00 then val=valiter end
    if iters>0 then
        iters=iters-1
        local sp=Score()
		WiggleSimple(val,how)-- new function BK 8/4/2013
        local ep = Score()
        local ig=ep-sp
        if how~="s" then
            if ig > minppi then WiggleAT(ss, how, iters, minppi) end
        end
    end
end

function SelectSphere(sg,radius,nodeselect)
    if nodeselect~=true then selection.DeselectAll() end
    for i=1, segCount do
        if structure.GetDistance(sg,i)<radius then selection.Select(i) end
        if sphere_worst==true then
            if current.GetSegmentEnergyScore(i)<sphere_worst_value then selection.Select(i) end
        end
    end
end

function Fix(sg)
    if fix_band==false then
        return
    end
-- selection.DeselectAll()
    local nb=1
    for i=1, segCount do
        dist=structure.GetDistance(sg,i)
        if (dist<12 and dist>6) then
            local cband=band.GetCount()
            band.AddBetweenSegments(sg, i)
            if cband<band.GetCount() then
                band.SetGoalLength(nb,dist)
                nb=nb+1
            end
-- else if dist>12 then
-- selection.Select(i)
-- end
        end
    end
-- freeze.FreezeSelected(true,true)
-- selection.DeselectAll()
-- SelectSphere(sg,esfera)
    --structure.WiggleSelected(1,true,true)
	WiggleSimple(1,"wa") -- new function BK 8/4/2013
    band.DeleteAll()
-- freeze.UnfreezeAll()
end

function round(x)--cut all afer 3-rd place
    return x-x%0.001
end

--calculate REALLY good seed for the pseudorandom in random (avoids to always have the same sequence)

return2GlobalOriginalFilterSetting() -- 24/8/2017 any time score is calcultated on first read, this is verified (for filter bug)
seed=os.time()/math.abs(Score())
seed=seed%0.001
seed=1/seed
while seed<10000000 do seed=seed*1000 end
seed=seed-seed%1
p("Seed is: "..seed)
math.randomseed(seed)
--REALLY good seed made by rav3n_pl :P


--START MIX TABLE subroutine by Bruno Kestemont 16/11/2015, idea by Puxatudo & Jeff101 from Go Science
function down(x)
    return x-x%1
end

function ShuffleTable(tab) --randomize order of elements
    local cnt=#tab
    for i=1,cnt do
        local r=math.random(cnt) -- not very convincing ! it gives always the same number on same puzzle
        tab[i],tab[r]=tab[r],tab[i]
    end
    return tab
end

function MixInwardTable(tab) -- 1234567 = 7254361 WARNING: if done twice, it returns to the original table
    local cnt=#tab -- 1234567 = 7254361; 123456 = 624351
	local mid=down(cnt/2)
	--local adjust=1 -- case of pair number of segments
	--local result={}
	local result=tab -- in order to avoid any nil seg numbers (fixing a bug)
	local pair=true
	--if mid<cnt/2 or mid==1 then adjust=0 end -- case of impair number of segments
    --for i=1,mid-adjust do -- mid remains untouched if impair cnt
		for i=1,mid do
		pair = not pair
		if pair then
			result[i],result[cnt+1-i]=tab[i],tab[cnt+1-i] -- pair segs are kept untouched
		else
			result[i],result[cnt+1-i]=tab[cnt+1-i],tab[i] -- impairs segs are shifted (loop starts with last seg)
		end
    end
    return result
end

function InwardTable(tab) -- 1234567 = 7162534 WARNING: if done twice, it mixes everything like a feuillete bakery
    local cnt=#tab -- 1234567 = 7162534
	local cntup=1
	local result={}
	local pair=true
    for i=1,#tab do
		pair = not pair
		if pair then
			result[i]=tab[cntup] -- pairs segments are taken from bottom
			cntup=cntup+1
		else
			result[i]=tab[cnt] -- impairs segs are taken from end (loop starts with last seg)
			cnt=cnt-1
		end
    end
    return result
end

function Reverselist(tab) -- 1234567=7654321
	local cnt=#tab
	local result={}
    for i=1,#tab do -- simply inverts the table 7162534=4536271
		result[i]=tab[cnt+1-i]
    end
	return result
end

function OutwardTable(tab) --1234567=4352617
	local result={}
	result=Reverselist(InwardTable(tab))
    return result
end

--END MIX TABLE


--Start score management and report
--better to enable filter during setup => these scores will be reset after dialog
return2GlobalOriginalFilterSetting() -- 24/8/2017 any time score is calcultated on first read, this is verified (for filter bug)
bestScore=Score() -- for savebest, I'll reset it after knowing the parameters
startenergypersegment=(SegScore()-8000)/segEnd-- NEW BK 18/10/2013 for maximo settings
winnerseg=2 -- arbitrary

function SaveBest(seg)
    local s=Score()
    local g=s-bestScore
	local WaitingTime=os.clock ()--StartChrono
    if g>0 then
		--local sscore=current.GetSegmentEnergyScore(seg) -- it's global now
        if g>=0.001 then
			p("Gained another ",round(g)," pts on seg ",seg, " scoring: ", round(sscore), ". Total score:",s)
		elseif WaitingTime > 300 then-- in sec, every 5 minutes, show something to make patience
			StartChrono=os.clock ()
			p("No gain up to seg",seg,"/",segEnd,". Score:", s)
		end
        bestScore=s
        save.Quicksave(3)
		if g>bestg then -- NEW BK 9/10/2013
			bestg=g
			winnerseg=seg
		end
    end
end
--End score management and report

function usableAA(sn)
    local usable=false -- a priori, aucun segment n'est utilisable sauf s'il rpond  une des conditions ci-dessous
	sscore=current.GetSegmentEnergyScore(sn)-- NEW BK 9/10/2013 global to print in savebest
---------------------------------------------

        if sscore>minimo then
            return usable -- donc false ici (true si score > minimo = 600)
        end
        if sscore<maximo then -- NEW BK 8/10/2013
            return usable -- donc false ici (true si score < maximo)
        end
    if rebuild==true then -- tous ceux qui restent si rebuild incl. ligands
        selection.DeselectAll()
        selection.Select(sn)
        structure.RebuildSelected(2)
        usable=true
        return usable
    end
	
	--if one of the above condition is met, we verify not further
---------------------------------------------

    if #useThat>0 then
        for i=1,#useThat do
            if sn==useThat[i] then
                usable=true
                break
            end
        end
    else
        if #useOnly > 0 then
            for i=1,#useOnly do
                local ss=useOnly[i][1]
                local se=useOnly[i][2]
                for s=ss,se do
                    if s==sn then
                        usable=true
                        break
                    end
                end
            end
        else
            usable=true -- each segment usable by default
            if #doNotUse>0 then
                for i=1,#doNotUse do
                    local ss=doNotUse[i][1]
                    local se=doNotUse[i][2]
                    for s=ss,se do
                        if s==sn then
                            usable=false
                            break
                        end
                    end
                    if usable==false then break end
                end
            end

            if #skipAA>0 then
                local aa=structure.GetAminoAcid(sn)
                for i=1,#skipAA do
                    if aa==skipAA[i] then
                        usable=false
                        break
                    end
                end
            end
        end
    end

    local se=segCount
    if ATend~=nil then se=ATend end
    if sn<ATstart or sn>se then usable=false end

    return usable
end

function wiggle_out(seg)
    CI(.6)
    --structure.WiggleSelected(1,true,true)
	WiggleSimple(2,"wa") -- new function BK 8/4/2013
    CI(1.)
    WiggleAT(seg)
    WiggleAT(seg,"s",1)
	--selection.SelectAll()
    CI(.6)
    WiggleAT(seg)
    CI(1.)
    WiggleAT(seg)
    --recentbest.Restore()
	FakeRecentBestRestore()
    SaveBest(seg)
end

function getNear(seg)
    if(Score() < g_total_score-1000) then
        selection.Deselect(seg)
        CI(.75)
        --ds(1)
		WiggleSimple(1,"s") -- new function BK 8/4/2013
        --structure.WiggleSelected(1,false,true)
		WiggleSimple(1,"ws") -- new function BK 8/4/2013
        selection.Select(seg)
        CI(1)
    end
    if(Score() < g_total_score-1000) then
        if fix_band==true then
            Fix(seg)
        else
            --recentbest.Restore()
			FakeRecentBestRestore()
            SaveBest(seg)
            return false
        end
    end
    return true
end

function sidechain_tweak(worklist)
    p("Pass 1 of 3: Sidechain tweak")
	worklist=worklist or WORKONBIS
    --for i=segStart, segEnd do
	for j=1,#worklist do
		local i=worklist[j]
        if usableAA(i) then
            selection.DeselectAll()
            selection.Select(i)
            local ss=Score()
            g_total_score = Score()
            CI(0)
            --ds(2)
			WiggleSimple(2,"s") -- changed to original 2 24/8/2017
            CI(1.)
            --p("Try sgmnt ", i)
            SelectSphere(i, esfera)
            if (getNear(i)==true) then
                wiggle_out(i)
            end
        end
    end
end

function sidechain_tweak_around(worklist)
    p("Pass 2 of 3: Sidechain tweak around")
    --for i=segStart, segEnd do
	worklist=worklist or WORKONBIS
    --for i=segStart, segEnd do
	for j=1,#worklist do
		local i=worklist[j]
        if usableAA(i) then
            selection.DeselectAll()
            for n=1, g_segments do
                g_score[n] = current.GetSegmentEnergyScore(n)
            end
            selection.Select(i)
            local ss=Score()
            g_total_score = Score()
            CI(0)
            --ds(2)
			WiggleSimple(2,"s") -- changed to original 2 24/8/2017
            CI(1. )
            --p("Try sgmnt ", i)
            SelectSphere(i,esfera)
            if(Score() > g_total_score - 30) then
               wiggle_out(i)
            else
                selection.DeselectAll()
                for n=1, g_segments do
                    if(current.GetSegmentEnergyScore(n) < g_score[n] - 1) then
                        selection.Select(n)
                    end
                end
                selection.Deselect(i)
                CI(0.1)
                --ds(1)
				WiggleSimple(1,"s") -- new function BK 8/4/2013
                SelectSphere(i,esfera,true)
                CI(1.0)
                if (getNear(i)==true) then
                    wiggle_out(i)
                end
            end
        end
    end
end


-- debugged:
function sidechain_manipulate(worklist)   -- negative scores avoided
    --p("Dernire chance: manipulateur brutal des chaines latrales")
	p("Last chance: bruteforce sidechain manipulate on best segments")
	maximo=maximo+10 -- new BK 14/12/13 because rotamers need best segments
	
    --for i=segStart, segEnd do
	worklist=worklist or WORKONBIS
    --for i=segStart, segEnd do
	for j=1,#worklist do
		local i=worklist[j]
        if usableAA(i) then
            selection.DeselectAll()
            rotamers = rotamer.GetCount(i)
			save.Quicksave(4)
            if(rotamers > 1) then
                local ss=Score()
				--p("Sgmnt: ", i," rotamers: ",rotamers, " Score= ", ss)
                for r=1, rotamers do
					--p("Sgmnt: ", i," position: ",r, " Score= ", ss)
                    save.Quickload(4)
                    g_total_score = Score()
                    rotamer.SetRotamer(i,r)
                    CI(1.)
                    if(Score() > g_total_score - 30) then
                        SelectSphere(i,esfera)
                        wiggle_out(i) -- this can change the number of rotamers
                    end	
					if rotamers > rotamer.GetCount(i) then break end --if nb of rotamers changed
                end
            end
        end
		recentbest.Restore()-- because rotamers can puzzle everything
    end
	maximo=maximo-10 -- new BK 14/12/13 einitiaization of current maximo
end
-- end debugged

--To BE IMPLEMENTED VIA DIALOG BOX
useThat={ --only segments what have to be used OVERRIDES all below
--18,150,151,205,320,322,359,361,425,432,433 --382
}

useOnly={ --ranges what have to be used OVERRIDES BOTH LOWER OPTIONS
--{12,24},
--{66,66},
}
doNotUse={ --ranges that should be skipped
--{55,58},
--{12,33},
}
skipAA={ --aa codes to skip
'a',
'g',
} -- default skiping these 2 AAs that have no rotamer

--option to easy set start and end of AT work to-- to be implemented in dialog
ATstart=1 --1st segment
ATend=nil --end of protein if nil
--END TO BE IMPLEMENTED VIA DIALOG BOX

sphere_worst=false -- include worst segments in sphere
sphere_worst_value=0


function Run() -- this is the MAIN
	puzzleprop()-- new BK 21/10/2013
    CI(1.00)
    --recentbest.Restore()
	FakeRecentBestRestore()
    save.Quicksave(3)--in save 3 always best solution. Load in case of crash.
	s1=Score()
	if tweek == true then
		StartChrono=os.clock ()
		sidechain_tweak()
		s2=Score()
		p("Tweak gain: ",round(s2-s1))
	end
	if tweekaround == true then
		s2=Score()
		StartChrono=os.clock ()
		sidechain_tweak_around()
		s3=Score()
		p("Around gain: ",round(s3-s2))
	end
    if manipulate==true then
		StartChrono=os.clock ()
		s3=Score()
        sidechain_manipulate()
		s4=Score()
		if s4-s3 <0 then FakeRecentBestRestore() end --against the bug !!!
		p("Manipulate gain: ",round(s4-s3))
    end
    selection.SelectAll() -- or 2 lines in one structure.WiggleAll(4,true,true)
	WiggleSimple(2,"wa") -- new function BK 8/4/2013 BK 15/01/2013 changed 1 to 2
	WiggleSimple(2,"ws") -- new function BK 8/4/2013 BK 15/01/2013 changed 1 to 2
    selection.SelectAll()
	WiggleSimple(2,"wa") -- new function BK 8/4/2013 BK 15/01/2013 changed 1 to 2
	--recentbest.Restore()
	FakeRecentBestRestore()
	s5=Score()
    --p("Start score Loop ",loop,": ",round(s1))
    --p("Tweak gain: ",round(s2-s1))
    --p("Around gain: ",round(s3-s2))
    --p("Manipulate gain: ",round(s4-s3))
    p("Total Acid gain Loop ",loop,": ",round(s5-s1))
    --p("End score: ",round(s5))
end


esfera=8

minimo=600 -- score for working with worst segments. Don't use, usually worst segs have no rotts

if startenergypersegment<-100 then maximo=-100 -- NEW BK 8/10/2013 (filters not considered here before dialog)
elseif startenergypersegment<-5 then maximo=-50
elseif startenergypersegment<10 then maximo=-10
else maximo=10
end
MUTATE=false -- Don't use, very bad results yet (TODO)
rebuild=true -- for very end in a puzzle, rebuild segment before tweak
fix_band=false -- if you want to try with the worst segments
fast=false

phases= 7 --Mode: (1)Tweek (2)Tweek around (3)Rotamers (4)1&2 (5)2&3 (6)1&3 (7)All
tweek=false
tweekaround=false
manipulate=false -- test rottamers

if PROBABLEFILTER and not CONTACTS and not HBONDS then
	FILTERMANAGEMENT=true
end

function GetParam()
    local dlg = dialog.CreateDialog(recipename)
    dlg.fast = dialog.AddCheckbox("Fast mode (gain 25% less)", false)
    dlg.fix_band = dialog.AddCheckbox("Fix geometry with bands when score breaks down", false)
    --dlg.manipulate = dialog.AddCheckbox("Brute force in phase 3", true)
	dlg.label0=dialog.AddLabel("Mode: (1) Tweek (2) Tweek around (3) Rotamers")
	dlg.label01=dialog.AddLabel("      (4) 1&2 (5) 2&3 (6) 1&3 (7) All")
	dlg.phases = dialog.AddSlider("Mode: ", phases, 0, 7, 0)
	dlg.sphere_worst = dialog.AddCheckbox("Include worst segments in sphere", false)
    dlg.rebuild = dialog.AddCheckbox("Rebuild before search rotts, for very end only", true)
	dlg.segStart=dialog.AddTextbox("From seg ", segStart)
	dlg.segEnd=dialog.AddTextbox("To seg ", segEnd)
	if flagligand then
		textligand= ("Ligand is seg nb. " .. segEnd+1)
		dlg.l1aaaa=dialog.AddLabel(textligand)
	end
	dlg.l1aaa=dialog.AddLabel("1=up; 2=back; 3=random; 4=out; 5=in; 6=slice")
	dlg.mixtables = dialog.AddSlider("Order: ", mixtables, 1, 6, 0)
	dlg.label1=dialog.AddLabel("Skip segments scoring less than: ")
	dlg.maximo = dialog.AddSlider("min pts/seg: ",maximo,-100,30,0)
	--dlg.minimo = dialog.AddSlider("more than",minimo,30,600,0)
	if PROBABLEFILTER then
		dlg.FILTERMANAGEMENT=dialog.AddCheckbox("Disable filter during wiggle", FILTERMANAGEMENT) -- default true
		dlg.GENERICFILTER=dialog.AddCheckbox("Always disable filter, unless for scoring", GENERICFILTER) -- default false
		dlg.MUTATE= dialog.AddCheckbox("Mutate, no shake", MUTATE) -- default false (it's not recommended)
	end
    dlg.ok = dialog.AddButton("OK", 1)
    dlg.cancel = dialog.AddButton("Cancel", 0)
    
    if dialog.Show(dlg) > 0 then
        fast = dlg.fast.value
        fix_band = dlg.fix_band.value
        --manipulate = dlg.manipulate.value
		phases=dlg.phases.value
		print("Mode ="..phases)
		sphere_worst=dlg.sphere_worst.value
        rebuild = dlg.rebuild.value
		segStart= dlg.segStart.value
		segEnd= dlg.segEnd.value
		--minimo=dlg.minimo.value
		maximo=dlg.maximo.value
		if PROBABLEFILTER then
			GENERICFILTER=dlg.GENERICFILTER.value
			FILTERMANAGEMENT=dlg.FILTERMANAGEMENT.value
			MUTATE=dlg.MUTATE.value
		end
		if GENERICFILTER then
			FILTERMANAGEMENT=false --(because reduntant and to avoid enabling filters after wiggles)
			MutClass(structure, false) -- GENERICFILTER bug: should be turned true again asap !!
			MutClass(band, false)
			MutClass(current, true)
			MutClass(recentbest, true)
			MutClass(save, true)
			print("Always disable filter, unless for scoring")
		end
		if FILTERMANAGEMENT then
			print("Disable filter during wiggle")
		end
		--actions
		if phases== 1 or phases== 4 or phases>5 then tweek=true end
		if phases== 2 or phases== 4 or phases==5 or phase==7 then tweekaround=true end		
		if phases== 3 or phases>4 then manipulate=true end
		--For MIXTABLES
		mixtables=dlg.mixtables.value
		WORKONBIS={} -- reset / the table to use is a simple list of segments in any order
		local compteur=0
		for i = segStart, segEnd do -- basic list of segments (reset of WORKONBIS)
				compteur=compteur+1
				WORKONBIS[compteur]=i
		end
		if mixtables==2 then WORKONBIS=Reverselist(WORKONBIS) print("Backward walk")
		elseif mixtables==3 then randomly=true WORKONBIS=ShuffleTable(WORKONBIS) print("Random walk")
		elseif mixtables==4 then WORKONBIS=OutwardTable(WORKONBIS) print("Outward walk")
		elseif mixtables==5 then WORKONBIS=InwardTable(WORKONBIS) print("Inward walk")
		elseif mixtables==6 then WORKONBIS=MixInwardTable(WORKONBIS) print("Slice walk")
		end -- else normal from first to last in the list
		
		return true
    end
    return false
end

--It's only here that GENERICFILTER starts to make effect !!

if GetParam()==false then
    return
end

--recentbest.Save() -- filter enabled ? NO because of Foldit BUG.
FakeRecentBestSave() -- should work properly on all situations

ini_score=Score() -- ok filter enabled here
print("Acid Tweeker starting at score: "..ini_score) -- note: if GENERICFILTER, always on !!
if filter.AreAllEnabled() then print("... without the filters !") end 
bestScore=Score() -- for savebest, reset with default GENERICFILTER parameters (filter enabled or not)

loop=0
hop=0

function MAINAT()
while(true) do
	print("################################")
	local startlooptime=os.clock ()
	local startloopscore=Score()
	loop=loop+1
	if loop ==2 then if not manipulate then manipulate = true print("Upgrading options: Adding manipulate-----") end end
	if loop ==3 then if not fix_band then fix_band = true print("Upgrading options: Adding Fixing bands----------") end end
	if loop ==4 then
		if fast then fast = false print("Upgrading options: Disabling fast----------") end
		if PROBABLEFILTER and MUTATE then MUTATE = false print("Upgrading options: Disabling mutate----------") end
	end
    if loop ==5 then if not rebuild then rebuild = true print("Upgrading options: Adding Rebuild before manipulate---------") end end
	if loop ==6 then if not sphere_worst then sphere_worst=true print("Upgrading options: Adding sphere-----------") end end
	if loop ==7 then if fix_band then fix_band = false print("Upgrading options: No Fixing bands----------") end end
	--hop=hop+1
	print("Loop ",loop, "Options:")
	print("fast=",fast,", fix_band=",fix_band,", manipulate=",manipulate)
	print(", rebuild=",rebuild, ", sphere=", sphere_worst, ", segs =",segStart,"-",segEnd)
	print("Use only segments scoring at least",maximo,"pts")
	if PROBABLEFILTER then
		print("MUTATE=",MUTATE,"GENERICFILTER=",GENERICFILTER)
		print("FILTERMANAGEMENT=",FILTERMANAGEMENT)
	end
    print("-------------------------------")
	bestg=0
	Run()
	print("Best gain this loop: ",bestg," pts on seg ",winnerseg)
	local stoplooptime=os.clock ()
	local stoploopscore=Score()
	print("This loop gained",round(stoploopscore-startloopscore),"in",round(stoplooptime-startlooptime)/60,"minutes")
	
    --if minimo<600 then minimo=minimo+10 end -- good scoring segs will gain much with at
	maximo=maximo-10 -- worst scoring segs will not gain with at, but if you've so much time, ok we try
    print(">>>Total Gain: ", round(Score()-ini_score), "Score:", round(Score()),"Start score: ", round(ini_score))
	print("CPU time =",round((stoplooptime-startRecTime)/60),"minutes")
end
end

function DumpErr(err)
	start,stop,line,msg=err:find(":(%d+):%s()")
	err=err:sub(msg,#err)
	p('---')
	if err:find('Cancelled')~=nil then
		p("User stop.")
	else
		p("unexpected error detected.")
		p("Error line:", line)
		p("Error:", err)
	end
	LastWish()
end
				
function LastWish()
	--recentbest.Restore()
	FakeRecentBestRestore()
	CI(1)
	return2GlobalOriginalFilterSetting()
end

--MAINAT()

xpcall(MAINAT, DumpErr)
--end
