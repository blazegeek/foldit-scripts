scriptName = "Walking AutoIdealize v1.0 RC1"
buildNumber = 1
currentBest = 0
interimScore = 0
saveSlot = 11
numSegments = structure.GetCount()
iterations = 2
idealizeSS = false -- TO DO: Make this a user option (that is, choose whether to idealize backbone or idealize peptide bonds, or both. Also, if both, select the start order (backbone or peptide), and idealize sequentially or interlaced).
totalGain = 0

function truncScore(x)
	return math.floor(x * 1000) / 1000
end

function getScore()
	local score = current.GetEnergyScore()
	return score
end


--[[
	IMPLEMENTATION:

	- Checkbox: Toggle on/off IdealiseSSSelected (Backbone)
	- Checkbox: Toggle on/off IdealizeSelected (Peptide)
	* Error check if no boxes are checked, return to dialog if so (force a selection)

	@ Nest dialogs if both are selected

	- Slider: Select number of residues to idealize together (Min = 1, Max = numSegments)
]]--

function dialogOptions()
	local dialogOptions = dialog.CreateDialog(scriptName .. " build " .. buildNumber)
	dialogOptions.label1 = dialog.AddLabel("Number of Residues to Idealize Together")
	dialogOptions.chunkSize = dialog.AddSlider("Size: ", chunkSize, 1, numSegments, 0)
	dialogOptions.label2 = dialog.AddLabel("Select Idealization:")
	dialogOptions.idealizeSS = dialog.AddCheckbox("Secondary Structure (Backbone): ", true)
	dialogOptions.idealizePep = dialog.AddCheckbox("Peptide Bonds: ", true)
	dialogOptions.label5 = dialog.AddLabel("     ")
	dialogOptions.okay = dialog.Button("OK", 1)
	dialogOptions.cancel = dialog.Button("Cancel", 0)

	if dialog.Show(dialogOptions) > 0 then
		chunkSize = dialogOptions.chunkSizechunkSize
		idealizeSS = dialogOptions.idealizeSS
		idealizePep = dialogOptions.idealizePep

		-- Check that at least 1 idealization option has been selected, otherwise launch dialog again
		if (idealizeSS == false) && (idealizePep == false) then
			dialogOptions.Show()
		else
			return -- or do we need a break statement?
		end

		-- If both idealization options are selected, launch another dialog to select order and seqeuncing
		if (idealizeSS == true) && (idealizePep == true) then
			-- launch dialogIdealizeOptions
			local dialogIdealizeOptions = dialog.CreateDialog("Idealize Options")
			dialogIdealizeOptions.label1 = dialog.AddLabel("Order and Sequencing")
			dialogIdealizeOptions.label2 = dialog.AddLabel("     Idealize Backbone First (otherwise Peptide First")
			dialogIdealizeOptions.idealizeSSFirst = dialog.AddCheckbox("Idealize SS First", true)
			dialogIdealizeOptions.label3 = dialog.AddLabel("     Interlace Idealization Method")
			dialogIdealizeOptions.label4 = dialog.AddLabel("     (otherwise Sequential)")
			dialogIdealizeOptions.doInterlaced = dialog.AddCheckbox("Interlace Methods", false)
			dialogIdealizeOptions.label5 = dialog.AddLabel("    ")
			dialogIdealizeOptions.okay = dialog.Button("OK", 1)
			dialogIdealizeOptions.cancel = dialog.Button("Cancel", 0)

			if dialog.Show(dialogIdealizeOptions) > 0 then
				idealizeSSFirst = dialogIdealizeOptions.idealizeSSFirst
				doInterlaced = dialogIdealizeOptions.doInterlaced
				-- No need to error check
			else
				dialogIdealizeOptions.Show() -- is this what we actually want?
			end
		end
	end
end

function main()
	selection.DeselectAll()
	save.Quicksave(saveSlot)
	currentBest = getScore()
	for i = 1, iterations do
		print("Iteration: " .. i .. "/" .. iterations)
		print("")
		for j = 1, numSegments - 2 do
			selection.SelectRange(j, j + 2) -- TO DO: Make this a user option (that is, choose the number of segments to idealize together)
			if idealizeSS == true then
				structure.IdealSSSelected()
			else
				structure.IdealizeSelected()
			end
			selection.DeselectAll()
			interimScore = getScore()
			gain = interimScore - currentBest
			if gain > 0 then
				totalGain = totalGain + gain
				currentBest = interimScore
				save.Quicksave(saveSlot)
				print("Seg: " .. j .. "/" .. numSegments .. " >> Score: " .. truncScore(currentBest) .. " (Gain +" .. truncScore(gain) .. ") [Total +" .. truncScore(totalGain) .. "]")
			else
				print("Seg: " .. j .. "/" .. numSegments .. " >> Score: " .. truncScore(currentBest) .. " [Total +" .. truncScore(totalGain) .. "]")
				save.Quickload(saveSlot)
			end
		end
		idealizeSS = true
		print("")
	end
end

main()
