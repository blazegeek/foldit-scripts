scriptName = "BanderScript"
scriptVersion = 1.0
buildNumber = 3
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

function addBands()
	band.AddBetweenSegments(1,20,4,1)
	band.AddBetweenSegments(3,18,1,4)
	band.AddBetweenSegments(3,18,4,1)
	band.AddBetweenSegments(5,16,1,4)
	band.AddBetweenSegments(5,16,4,1)
	band.AddBetweenSegments(7,14,1,4)
	band.AddBetweenSegments(7,14,4,1)
	band.AddBetweenSegments(9,12,1,4)
	band.AddBetweenSegments(9,12,4,1)

	band.AddBetweenSegments(4,85,4,1)
	band.AddBetweenSegments(6,85,1,4)
	band.AddBetweenSegments(6,87,4,1)
	band.AddBetweenSegments(8,87,1,4)
	band.AddBetweenSegments(8,89,4,1)

	band.AddBetweenSegments(48,91,4,1)
	band.AddBetweenSegments(50,88,1,4)
	band.AddBetweenSegments(50,88,4,1)
	band.AddBetweenSegments(52,86,1,4)
	band.AddBetweenSegments(53,86,1,4)
	band.AddBetweenSegments(53,86,4,1)

	band.AddBetweenSegments(47,76,4,1)
	band.AddBetweenSegments(49,74,1,4)
	band.AddBetweenSegments(49,74,4,1)
	band.AddBetweenSegments(51,72,1,4)

	band.AddBetweenSegments(19,22,4,1)
	band.AddBetweenSegments(24,79,1,4)
	band.AddBetweenSegments(25,76,1,4)
	band.AddBetweenSegments(45,48,4,1)

	band.AddBetweenSegments(55,82,4,1)
	band.AddBetweenSegments(57,80,1,4)
	band.AddBetweenSegments(57,80,4,1)
end

function setBands()
	for i = 1, band.GetCount() do
		band.SetGoalLength(i, 2.75)
		band.SetStrength(i, 2.0)
	end
end

function cleanup(err)
	print(err)
end

function main()
	print(scriptName, buildNumber)
	addBands()
	setBands()
	--readBands()
end

xpcall(main, cleanup)
