scriptName = "Read Bands"
scriptVersion = 1.0
scriptBuild = 1
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
	print(scriptName, "build: " .. scriptBuild)
	readBands()
end

xpcall(main, cleanup)
