--v 3.3 Extended sliders for Sketchbook (BK)
--v 3.4 Added AFK.BounceWiggle.Risky. When failed interations end, takes credidBest and starts again.
--		This shoul give a succession of "second best selection from all iterations" when MinGain is huge.
--		I think it should be good for end Sketchbook game
--		Added quick steps in cleanup for use of undos, deleted long lasting original cleanup (deselects & unfreezes)
--v 3.4.1 fixed an error (stopping after first gain) due to mispelling of save.Quicksave (not save.QuickSave)
--v 3.5 fixed the min ci to 0.10 and faster shake and mutate iterations (ZL7)


--SLOTS
-- 98 = best score
-- 10-50 = jumps
-- 51-90 = creditbest scores
BestSlot= 98
JumpSlot=10
JumpCredit=50



AFK = {}
AFK.BounceWiggle = {}
AFK.Debug = {}
AFK.Init = {}
AFK.Init.IsSelected = {}
AFK.Init.IsFrozen = {}
AFK.BounceWiggle.DoShake = false
AFK.IsMutable = false
AFK.BounceWiggle.DoMutate = false
AFK.BounceWiggle.Iterations = 1000
AFK.BounceWiggle.MinGain = 0
AFK.BounceWiggle.Risky = false
AFK.BounceWiggle.SkipCIMaximization = true
AFK.Debug.DoDebug=false
SKETCHBOOK = false

function detectfilterandmut() -- BK 13/2/2015
	local descrTxt=puzzle.GetDescription()
	local puzzletitle=puzzle.GetName()
	if #descrTxt>0 and (descrTxt:find("Sketchbook") or descrTxt:find("Sketchbook")) then
		SKETCHBOOK =true
	end
	if #puzzletitle>0 and puzzletitle:find("Sketchbook") then -- new BK 17/6/2013
		SKETCHBOOK =true
	end
	if #descrTxt>0 and (descrTxt:find("filter") or descrTxt:find("filters") or descrTxt:find("contact") or descrTxt:find("Contacts")) then
		PROBABLEFILTER=true
		FILTERMANAGE=true -- default yes during wiggle (will always be activate when scoring)
		GENERICFILTER=false -- actually not recommended
	end
	if #descrTxt>0 and (descrTxt:find("design") or descrTxt:find("designs")) then
		HASMUTABLE=true
		IDEALCHECK=true
	end
	if #descrTxt>0 and (descrTxt:find("De-novo") or descrTxt:find("de-novo") or descrTxt:find("freestyle")
		or descrTxt:find("prediction") or descrTxt:find("predictions")) then
		IDEALCHECK=true
	end

	if #puzzletitle>0 then
		if (puzzletitle:find("Sym") or puzzletitle:find("Symmetry") or puzzletitle:find("Symmetric")
				or puzzletitle:find("Dimer") or puzzletitle:find("Trimer") or puzzletitle:find("Tetramer")
				or puzzletitle:find("Pentamer")) then
			PROBABLESYM=true
			if puzzletitle:find("Dimer") and not puzzletitle:find("Dimer of Dimers") then sym=2
			elseif puzzletitle:find("Trimer") or puzzletitle:find("Tetramer") then sym=3
			elseif puzzletitle:find("Dimer of Dimers") or puzzletitle:find("Tetramer") then sym=4
			elseif puzzletitle:find("Pentamer") then sym=5
			else sym=6
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
	--print resulting sym info
	if PROBABLESYM then
		print("Symmetric")
		if sym==2 then
			print("Dimer")
		elseif sym==3 then
			print("Trimer")
		elseif sym==4 then
			print("Tetramer")
		elseif sym==5 then
			print("Pentamer")
		elseif sym>5 then
			print("Terrible polymer")
		end
	else print("Monomer")
	end

	if #puzzletitle>0 and puzzletitle:find("Sepsis") then -- new BK 17/6/2013
		SEPSIS=true
		--p(true,"-Sepsis")
		print("Sepsis")
	end
	if #puzzletitle>0 and puzzletitle:find("Electron Density") then -- for Electron Density
		--p(true,"-Electron Density")
		ELECTRON=true
		print("Electron density")
	end
	if #puzzletitle>0 and puzzletitle:find("Centroid") then -- New BK 20/10/2013
		--p(true,"-Centroid")
		CENTROID=true
		print("Centroid")
	end
	if #puzzletitle>0 and puzzletitle:find("Hotspot") then -- New BK 21/01/2014
	HOTSPOT=true
	print("Hotspot")
	end



	return
end
detectfilterandmut()


if creditbest.GetScore() > current.GetScore() then
	print("???????????")
	print("WARNING not starting from creditbest score")
	print("Risky endless on your own risk !")
	print("???????????")

end

AFK.CreateBounceWiggleStrategicDialog = function()

    local currentDialog = dialog.CreateDialog("BounceWiggleStrategy")

    currentDialog.sketchbooklabel = dialog.AddLabel("Sketchbook automatic")

    currentDialog.BlankLabel1 = dialog.AddLabel("")

    currentDialog.TwoMoves = dialog.AddButton("2 moves", 1)
    currentDialog.TenMoves = dialog.AddButton("7 moves", 2)
	currentDialog.Custom = dialog.AddButton("Custom", 3)

    currentDialog.CancelButton = dialog.AddButton("Cancel", 0)

    local choice = dialog.Show(currentDialog)

    return choice
end


AFK.CreateBounceWiggleDialog = function()
    for n=1,structure.GetCount() do
        if(structure.IsMutable(n)) then
            AFK.IsMutable = true
        end
        if(selection.IsSelected(n)) then
            AFK.Init.IsSelected[n] = true
        else
            AFK.Init.IsSelected[n] = false
        end
        if(freeze.IsFrozen(n)) then
            AFK.Init.IsFrozen[n] = true
        else
            AFK.Init.IsFrozen[n] = false
        end
    end

    local currentDialog = dialog.CreateDialog("BounceWiggle")
    currentDialog.IterationsLabel = dialog.AddLabel("Failed Iterations before ending")
    currentDialog.IterationsSlider = dialog.AddSlider("Failure Iterations", AFK.BounceWiggle.Iterations, 0, 1000, 0)

    currentDialog.BlankLabel1 = dialog.AddLabel("")
    currentDialog.DiscardLabel = dialog.AddLabel("(Sketchbook) Discard gains less than")
    currentDialog.DiscardSlider = dialog.AddSlider("Discard <", AFK.BounceWiggle.MinGain, 0, 500, 2)
    currentDialog.Risky = dialog.AddCheckbox("Risky endless using CreditBest", AFK.BounceWiggle.Risky)

    currentDialog.BlankLabel2 = dialog.AddLabel("")
    currentDialog.SkipMaximization = dialog.AddCheckbox("Skip CI=1 Maximization", AFK.BounceWiggle.SkipCIMaximization)

    currentDialog.NoShakeButton = dialog.AddButton("No Shake", 1)
    currentDialog.ShakeButton = dialog.AddButton("Shake", 2)
    if(AFK.IsMutable) then
        currentDialog.MutateButton = dialog.AddButton("Mutate", 3)
    end
    currentDialog.CancelButton = dialog.AddButton("Cancel", 0)

    local choice = dialog.Show(currentDialog)

    AFK.BounceWiggle.Iterations = currentDialog.IterationsSlider.value
    AFK.BounceWiggle.MinGain = currentDialog.DiscardSlider.value
	AFK.BounceWiggle.Risky = currentDialog.Risky.value
    AFK.BounceWiggle.SkipCIMaximization = currentDialog.SkipMaximization.value

    if(AFK.BounceWiggle.Iterations < 1) then
        AFK.BounceWiggle.Iterations = -1
    end

	AFK.BounceWiggle.IterationsReset = AFK.BounceWiggle.Iterations -- init if further rounds needed

    if (choice > 2) then
        print("AFK3(BounceWiggleMutate) started. "..AFK.BounceWiggle.Iterations.." Failed Iterations before ending")
        AFK.BounceWiggle.DoMutate = true
    elseif (choice > 1) then
        print("AFK3(BounceWiggleShake) started. "..AFK.BounceWiggle.Iterations.." Failed Iterations before ending")
        AFK.BounceWiggle.DoShake = true
    elseif (choice > 0) then
        print("AFK3(BounceWiggleNoShake) started. "..AFK.BounceWiggle.Iterations.." Failed Iterations before ending")
    else
        print("Dialog cancelled")
    end
    return choice
end

AFK.BounceWiggle.Init = function()
-- dialog stuff
    local choice = 3 -- default to normal dialog

	if SKETCHBOOK then -- sketchbook dialog choices 1 or 2
		choice = AFK.CreateBounceWiggleStrategicDialog()
	end

	if(choice < 1) then return -- stops the recipe

	elseif choice <2 then -- 2 moves
		AFK.BounceWiggle.DoShake = false
		AFK.BounceWiggle.DoMutate = false
		AFK.BounceWiggle.Iterations = 1000
		AFK.BounceWiggle.MinGain = 500
		AFK.BounceWiggle.Risky = false
	elseif choice <3 then -- 7 moves
		AFK.BounceWiggle.DoShake = true
		if HASMUTABLE then AFK.BounceWiggle.DoMutate = true end
		AFK.BounceWiggle.Iterations = 100
		AFK.BounceWiggle.MinGain = 500
		AFK.BounceWiggle.Risky = true
	elseif choice <4 then -- custom (normal dialog)
		choice = AFK.CreateBounceWiggleDialog() -- normal dialog
		if(choice < 1) then return end
	end
-- end dialog stuff

	AFK.BounceWiggle.IterationsReset = AFK.BounceWiggle.Iterations -- init if further rounds needed

    local currentScore = AFK.StartScore
    local tempScore = currentScore
    local tempScore2 = tempScore
    save.Quicksave(BestSlot)
    recentbest.Save()
    behavior.SetClashImportance(1)

    local init = true
    if(AFK.BounceWiggle.SkipCIMaximization == false) then
        print("Maximizing Wiggle Score at Clashing Impotance = 1. Please wait.")
        while(current.GetEnergyScore() > currentScore or init == true) do
            init = false
            currentScore = current.GetEnergyScore()
            tempScore = currentScore
            tempScore2 = tempScore

            selection.SelectAll()
            structure.WiggleAll(25)
            recentbest.Restore()
            tempScore = current.GetEnergyScore()
            if(tempScore > (tempScore2 + AFK.BounceWiggle.MinGain)) then
                save.Quicksave(BestSlot)
                tempScore2 = tempScore
            else
                save.Quickload(BestSlot)
                tempScore = current.GetEnergyScore()
            end

            structure.LocalWiggleAll(25)
            recentbest.Restore()
            tempScore = current.GetEnergyScore()
            if(tempScore > (tempScore2 + AFK.BounceWiggle.MinGain)) then
                save.Quicksave(BestSlot)
                tempScore2 = tempScore
            else
                save.Quickload(BestSlot)
                tempScore = current.GetEnergyScore()
            end

            structure.WiggleSelected(25)
            recentbest.Restore()
            tempScore = current.GetEnergyScore()
            if(tempScore > (tempScore2 + AFK.BounceWiggle.MinGain)) then
                save.Quicksave(BestSlot)
                tempScore2 = tempScore
            else
                save.Quickload(BestSlot)
                tempScore = current.GetEnergyScore()
            end

            structure.LocalWiggleSelected(25)
            recentbest.Restore()
            tempScore = current.GetEnergyScore()
            if(tempScore > (tempScore2 + AFK.BounceWiggle.MinGain)) then
                save.Quicksave(BestSlot)
                tempScore2 = tempScore
            else
                save.Quickload(BestSlot)
                tempScore = current.GetEnergyScore()
            end
        end
        currentScore = current.GetEnergyScore()
    end

    if(currentScore > AFK.StartScore)then
        print ("script started: + "..(currentScore - AFK.StartScore).." -- "..currentScore)
    else
        print("script started: "..currentScore)
    end

    init = true
    while(init == true or AFK.BounceWiggle.Iterations > 0 or AFK.BounceWiggle.Iterations < 0) do
        init = false
        currentScore = current.GetEnergyScore()
        if(AFK.Debug.DoDebug == true) then
            print("Debug")
        end
        AFK.BounceWiggle.Run()

        if(current.GetEnergyScore() > currentScore + AFK.BounceWiggle.MinGain)then
            print (AFK.BounceWiggle.Iterations..": + "..(current.GetEnergyScore() - currentScore).." -- "..current.GetEnergyScore())
			JumpSlot=JumpSlot+1
			if(AFK.Debug.DoDebug == true) then
                --print ("CI("..ci..") "..co.."("..ce..") ".." CI(1) "..ca.."("..cu..") ")
				print ("JumpSlot ("..JumpSlot..") ")
            end
			if JumpSlot>50 then JumpSlot=10 end
			save.Quicksave(JumpSlot)
            if(AFK.BounceWiggle.Iterations > 0) then
                AFK.BounceWiggle.Iterations = AFK.BounceWiggle.Iterations + 1
            end
			if(AFK.Debug.DoDebug == true) then
                --print ("CI("..ci..") "..co.."("..ce..") ".." CI(1) "..ca.."("..cu..") ")
				print ("Iterations("..AFK.BounceWiggle.Iterations..") ")
            end
        else
            if(AFK.Debug.DoDebug == true) then
                --print ("CI("..ci..") "..co.."("..ce..") ".." CI(1) "..ca.."("..cu..") ")
				print ("Iterations("..AFK.BounceWiggle.Iterations..") ")
            end

			if (AFK.BounceWiggle.Iterations == 25) or (AFK.BounceWiggle.Iterations == 50) or (AFK.BounceWiggle.Iterations == 100)
				or (AFK.BounceWiggle.Iterations == 200) or (AFK.BounceWiggle.Iterations == 400) then
				print (AFK.BounceWiggle.Iterations.." --  (creditbest= ".. creditbest.GetScore()..")")
			end

        end

        if(AFK.BounceWiggle.Iterations > 0) then AFK.BounceWiggle.Iterations = AFK.BounceWiggle.Iterations - 1 end

		if AFK.BounceWiggle.Risky and (AFK.BounceWiggle.Iterations == 1) then
			AFK.BounceWiggle.Iterations = AFK.BounceWiggle.IterationsReset
			print("Starting over with creditbest scoring",creditbest.GetScore())
			creditbest.Restore()
			JumpCredit=JumpCredit+1
			if JumpCredit>90 then JumpCredit=51 end
			save.Quicksave(JumpCredit)
		end



    end

    init = true
    currentScore = current.GetEnergyScore()
    if(AFK.BounceWiggle.SkipCIMaximization == false) then
        print("Maximizing Wiggle Score at Clashing Impotance = 1. Please wait.")
        while(current.GetEnergyScore() > currentScore or init == true) do
            init = false
            currentScore = current.GetEnergyScore()
            tempScore = currentScore
            tempScore2 = tempScore

            selection.SelectAll()
            structure.WiggleAll(25)
            recentbest.Restore()
            tempScore = current.GetEnergyScore()
            if(tempScore > (tempScore2 + AFK.BounceWiggle.MinGain)) then
                save.Quicksave(BestSlot)
                tempScore2 = tempScore
            else
                save.Quickload(BestSlot)
                tempScore = current.GetEnergyScore()
            end

            structure.LocalWiggleAll(25)
            recentbest.Restore()
            tempScore = current.GetEnergyScore()
            if(tempScore > (tempScore2 + AFK.BounceWiggle.MinGain)) then
                save.Quicksave(BestSlot)
                tempScore2 = tempScore
            else
                save.Quickload(BestSlot)
                tempScore = current.GetEnergyScore()
            end

            structure.WiggleSelected(25)
            recentbest.Restore()
            tempScore = current.GetEnergyScore()
            if(tempScore > (tempScore2 + AFK.BounceWiggle.MinGain)) then
                save.Quicksave(BestSlot)
                tempScore2 = tempScore
            else
                save.Quickload(BestSlot)
                tempScore = current.GetEnergyScore()
            end

            structure.LocalWiggleSelected(25)
            recentbest.Restore()
            tempScore = current.GetEnergyScore()
            if(tempScore > (tempScore2 + AFK.BounceWiggle.MinGain)) then
                save.Quicksave(BestSlot)
                tempScore2 = tempScore
            else
                save.Quickload(BestSlot)
                tempScore = current.GetEnergyScore()
            end
        end
    end
    if(current.GetEnergyScore() > currentScore)then
        print ("script complete: + "..(current.GetEnergyScore() - AFK.StartScore).." -- "..current.GetEnergyScore())
    else
        print("script complete:"..current.GetEnergyScore())
    end
    AFK.Cleanup()
end

AFK.BounceWiggle.Run = function()
    local currentScore = current.GetEnergyScore()
    local tempScore = currentScore
    local tempScore2 = tempScore
    save.Quicksave(BestSlot)

    --truly random numbers are not required
    local wiggle1Type = math.random(1,4)
	local wiggle1Iterations = math.random(1, 3)
	local wiggle1CI = math.random(1, 1000) / 1000
	if(wiggle1CI < 0.10) then
		wiggle1CI = 0.10
		behavior.SetClashImportance(wiggle1CI)
		else
        behavior.SetClashImportance(wiggle1CI)
		end
    local wiggle2Type = math.random(1,4)
    if(AFK.Debug.DoDebug == true) then
        print("wiggle1Type "..wiggle1Type)
        print("wiggle1Iterations "..wiggle1Iterations)
        print("wiggle1CI "..wiggle1CI)
        print("wiggle2Type "..wiggle2Type)
    end

    behavior.SetClashImportance(wiggle1CI)

    if(wiggle1Type > 3) then
        structure.LocalWiggleSelected(wiggle1Iterations)
        --wiggle1Type = "LocalWiggleSelected"
    elseif(wiggle1Type > 2) then
        structure.WiggleSelected(wiggle1Iterations)
        --wiggle1Type = "LocalWiggleSelected"
    elseif(wiggle1Type > 1) then
        structure.LocalWiggleAll(wiggle1Iterations)
        --wiggle1Type = "LocalWiggleSelected"
    else
        structure.WiggleAll(wiggle1Iterations)
        --wiggle1Type = "LocalWiggleSelected"
    end

    if(AFK.BounceWiggle.DoShake == true or AFK.BounceWiggle.DoMutate == true) then
        local shakeType = math.random(1,3)
        local shakeIterations = 4
		local muIterations = 2
        local shakeCI = math.random(1, 1000) / 1000
		if(shakeCI < 0.10) then
		shakeCI = 0.10
		behavior.SetClashImportance(shakeCI)
		else
        behavior.SetClashImportance(shakeCI)
		end

        if(AFK.Debug.DoDebug == true) then
            print("shakeType "..shakeType)
            print("shakeIterations "..shakeIterations)
            print("shakeCI "..shakeCI)
        end
        if(shakeType > 1 and AFK.BounceWiggle.DoMutate == true) then
            structure.MutateSidechainsAll(muIterations)
        elseif(shakeType > 1) then
            structure.ShakeSidechainsAll(shakeIterations)
        else
            selection.DeselectAll()
            local shakeSelectionCount = math.random(1,structure.GetCount())
            if(AFK.Debug.DoDebug == true) then
                print("shakeSelectionCount "..shakeSelectionCount)
            end
            for n=1,shakeSelectionCount do
                local selectSegment = math.random(1,structure.GetCount())
                if(AFK.Debug.DoDebug == true) then
                    print("selectSegment "..selectSegment)
                end
                selection.Select(selectSegment)
            end
            if(AFK.BounceWiggle.DoMutate == true) then
                structure.MutateSidechainsSelected(muIterations)
            else
                structure.ShakeSidechainsSelected(shakeIterations)
            end

            selection.SelectAll()
        end
    end
    behavior.SetClashImportance(1)
    if(AFK.Debug.DoDebug == true) then
        print("wiggle2Type "..wiggle2Type)
    end

    if(wiggle2Type > 3) then
        structure.LocalWiggleSelected(25)
        --wiggle2Type = "LocalWiggleSelected"
    elseif(wiggle2Type > 2) then
        structure.WiggleSelected(25)
        --wiggle2Type = "WiggleSelected"
    elseif(wiggle2Type > 1) then
        structure.LocalWiggleAll(25)
        --wiggle2Type = "LocalWiggleAll"
    else
        structure.WiggleAll(25)
        --wiggle2Type = "WiggleAll"
    end

    recentbest.Restore()
    tempScore = current.GetEnergyScore()
    if(tempScore > (tempScore2 + AFK.BounceWiggle.MinGain)) then
        save.Quicksave(BestSlot)
        tempScore2 = tempScore
    else
        save.Quickload(BestSlot)
        tempScore = current.GetEnergyScore()
    end
end

AFK.StartScore = current.GetEnergyScore()
AFK.StartCI = behavior.GetClashImportance()
function AFK.Cleanup(errorMessage)
    behavior.SetClashImportance(AFK.StartCI)
    recentbest.Restore()
    --selection.DeselectAll()
end

xpcall(AFK.BounceWiggle.Init, AFK.Cleanup)
