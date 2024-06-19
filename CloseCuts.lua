scriptName = "Close Cuts"
scriptVersion = 1.0
scriptBuild = 1

settings = dialog.CreateDialog("Delete Cuts")
settings.cutoff = dialog.AddSlider("Max Length", 6, 0, 100, 1)
settings.ok = dialog.AddButton("Close Cuts", 1)
settings.cancel = dialog.AddButton("Cancel", 0)

-- TO DO: Disable notes
function checkNoteKC(segment)
	-- Check if <KC> is in a segment's note
	return string.find(structure.GetNote(segment), "<KC>")
end

function main()
	if(dialog.Show(settings) > 0) then
		local distance = 0
		for segment = 1, structure.GetCount() - 1 do
			distance = structure.GetDistance(segment, segment+1)
			if (distance <= settings.cutoff.value or settings.cutoff.value == 0) and not checkNoteKC(segment) and not checkNoteKC(segment + 1) then
				structure.DeleteCut(segment)
			end
		end
	else
		cleanup("Cancelled")
	end
end

function cleanup(err)
	if string.find(err, "Cancelled") then
			print("User Cancelled")
	else
			print(err)
	end
end

xpcall(main, cleanup)
