scriptName = "Read Bands v1.0"
buildNumber = 1
numSegments = structure.GetCount()

function readBands()
	for i = 1, band.GetCount() do
		local resB = band.GetResidueBase(i)
		local resE = band.GetResidueEnd(i)
		local atomB = band.GetAtomBase(i)
		local atomE = band.GetAtomEnd(i)
		print("Band: ", i, resB, resE, atomB, atomE)
	end
end

function cleanup(err)
	print(err)
end

function main()
	print(scriptName, "build: " .. buildNumber)
	readBands()
end

xpcall(main, cleanup)
