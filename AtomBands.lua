-- bandsome: interactively place bands between specific atoms in protein

-- by jeff101 8/11/12
-- edited by Wipf

-- ********** TO DO: Replace wipf. with simpler output and logging, etc. There is no need for this to be stored to a table

scriptName = "Atom Bands"
scriptVersion = 2.0
scriptBuild = 1

function main()
	wipf.logger = print

	-- These should be global
	local residueCount = structure.GetCount()
	local bandCount = band.GetCount()
	print(scriptName .. " " .. scriptVersion, os.date())

	local symCount
	if structure.GetSymCount ~= nil then
		symCount = structure.GetSymCount()
	else
		symCount = 0
	end

	local fromResidue = 1
	local toResidue   = structure.GetCount()

	-- *** TO DO: Move this to a separate function
	local ask = dialog.CreateDialog(scriptName .. " " .. scriptVersion)
	-- This label seems redundant
	--[[
	if symCount > 0 then
		-- Are these bands applied symmetrically among copies?
		ask.labelMonomer = dialog.AddLabel("The first residue is always on the main monomer")
	end
	]]--
	ask.fromResidue = dialog.AddSlider("From Residue:", fromResidue, 1, residueCount, 0)
	ask.fromAtom = dialog.AddLabel("From Atom")
	if symCount > 0 then
		ask.toMonomer = dialog.AddSlider("To Monomer", 0, 1, symCount, 0)
		ask.labelMonomer = dialog.AddLabel("Monomer 0 is the main monomer,\nthe others are its symmetric copies")
	end
	ask.toResidue = dialog.AddSlider("To Residue", toResidue, 1, residueCount, 0)
	ask.toAtom = dialog.AddLabel("To Atom")
	ask.length = dialog.AddSlider("Goal Length", 3, 0, 10, 1)
	ask.strength = dialog.AddSlider("Band Strength", 2, 0, 10, 1)
	ask.keepLast = dialog.AddSlider("Keep Last: ", 0, -1, 2, 0)
	-- *** TO DO: Change range from -1 to 2 .... to 0 to 3
	ask.Label7a = dialog.AddLabel("-1: Remove all existing bands\n 0: Replace previous band")
	ask.Label7c = dialog.AddLabel(" 1: Keep previous band")
	ask.Label7d = dialog.AddLabel(" 2: Quit now without adding a new band\n ")
	ask.labelDestMonomerA = dialog.AddLabel("Different residues have different numbers of atoms")
	ask.labelDestMonomerB = dialog.AddLabel("Use the Update button after selecting the residues\nto update the atom slider ranges")
	ask.update = dialog.AddButton("Update", 2)
	ask.OK = dialog.AddButton("OK", 1)

	function logToDialog(message)
		print(message)
		ask.message.label = message
	end
	wipf.logger = logToDialog

	-- 0 is always the alpha-carbon
	local toMonomer
	local fromAtom = 0
	local toAtom = 0
	local bandNumber = 0
	local bandLength
	local bandStrength

	-- Get input values
	while true do
		-- Verify atom numbers are in range
		local fromAtomCount = structure.GetAtomCount(fromResidue)
		local toAtomCount = structure.GetAtomCount(toResidue)
		if fromAtom > fromAtomCount then
			fromAtom = fromAtomCount
		end
		if toAtom > toAtomCount then
			toAtom = toAtomCount
		end

		---- Update dialog
		ask.fromAtom = dialog.AddSlider( "From Atom", fromAtom, 0, fromAtomCount, 0)
		ask.toAtom = dialog.AddSlider("To Atom", toAtom, 0, toAtomCount, 0)
		local answer = dialog.Show(ask)
		ask.message.label = ""
		if answer == 0 then
			break
		end

		if symCount > 0 then
			toMonomer = ask.toMonomer.value
		end
		fromResidue = ask.fromResidue.value
		toResidue = ask.toResidue.value
		fromAtom = ask.fromAtom.value
		toAtom = ask.toAtom.value
		bandLength = ask.length.value
		bandStrength = ask.strength.value
		local keepLast = ask.keepLast.value

		-- Update button: skip band deletion and creation
		-- This could be simplified
		if answer ~= 2 then
			-- Delete / Add bands
			if keepLast == -1 then
				print("Deleting all bands")
				band.DeleteAll()
			elseif keepLast == 0 then
				if bandNumber > 0 then
					print("Deleting band " .. bandNumber)
					band.Delete(bandNumber)
				end
			elseif keepLast == 2 then
				break
			end

			local aa1 = structure.GetAminoAcid(fromResidue)
			local aa2 = structure.GetAminoAcid(toResidue)
			-- WHY? Why do we need the secondary structure?
			--local ss1 = structure.GetSecondaryStructure(fromResidue)
			--local ss2 = structure.GetSecondaryStructure(toResidue)
			print("Adding band between atom "  ..  fromAtom  .. " on "  ..  aa1  ..  fromResidue  .. "\n and atom " .. toAtom .. " on " .. aa2 .. toResidue .. " with strength " .. bandStrength .. "\n goal length " .. bandLength)
				bandNumber = wipf.AddBandBetweenSegments(fromResidue, toResidue, fromAtom, toAtom, toMonomer)
			if bandNumber > 0 then
				band.SetGoalLength(bandNumber,bandLength)
				band.SetStrength(bandNumber,bandStrength)
				print("Band Added")
			else
				print("Failed to add new band")
			end
		end
	end
	cleanup()
end

-- Table for Wipf"s functions and variables
wipf = {}

-- Safety wrapper around band.AddBetweenSegments to prevent the game from hanging up
function wipf.AddBandBetweenSegments(fromResidue, toResidue, fromAtom, toAtom, toMonomer)
	-- check atom indices
	if fromAtom ~= nil then
		if fromAtom < 0 or fromAtom > structure.GetAtomCount(fromResidue) then
			if wipf.logger ~= nil then
				wipf.logger(string.format("Invalid atom index %d for residue %d (it has %d atoms)!", fromAtom, fromResidue, structure.GetAtomCount(fromResidue)))
			end
			return 0
		end
	end
	if toAtom ~= nil then
		if toAtom < 0 or toAtom > structure.GetAtomCount(toResidue) then
			if wipf.logger ~= nil then
				wipf.logger(string.format("Invalid atom index %d for residue %d (it has %d atoms)!", toAtom, toResidue, structure.GetAtomCount(toResidue)))
			end
			return 0
		end
	end
	if structure.GetSymCount ~= nil then
		return band.AddBetweenSegments(fromResidue, toResidue, fromAtom, toAtom, toMonomer)
	else
		return band.AddBetweenSegments(fromResidue, toResidue, fromAtom, toAtom)
	end
end

function round(val)
	return val - val % 0.001
end

function trunc(val)
	return math.floor(val * 1000) / 1000
end

function cleanup(error)
	local reason, start, stop, line, msg
	if nil == error then
		reason = "Complete"
	else
		start, stop, line, msg = error:find(":(%d+):%s()")
		if msg ~= nil then
			error = error:sub(msg)
		end
		if error:find("Cancelled") ~= nil then
			reason = "Cancelled"
		else
			reason = "Error"
			print("Script Error")
			print("Line: ", line)
			print("Error message:", error)
		end
	end
end

xpcall(main, cleanup)
