scriptName = "Cut Around Cysteine"
scriptVersion = 1.0
scriptBuild = 1

function checkAndCut(segment)
	-- Check if segment is within range  (to avoid crashing foldit)
	if (segment <= structure.GetCount()) and (segment > 0) then
		-- TO DO: Disable notes
		-- Check if no cut flag in note.
		if not string.find(structure.GetNote(segment), "<NC>") then
			structure.InsertCut(segment)
		end
	end
end

function main()
	-- Iterate through all segments
	for segment = 1, structure.GetCount() do
		-- Check if the segment is cysteine
		if structure.GetAminoAcid(segment) == 'c' then
			-- Cut around segment, but do it safely to avoid crashing.
			checkAndCut(segment)
			checkAndCut(segment - 1)
		end
	end
	print("Done")
end

function cleanup(err)
	if string.find(err, "Cancelled") then
		print("User Cancelled")
	else
		print(err)
	end
	return err
end

xpcall(main, cleanup)
