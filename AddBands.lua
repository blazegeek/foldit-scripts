scriptName = "BanderScript"
scriptVersion = 1.0
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

function addBands()
	band.AddBetweenSegments(4,40,1,4)
	band.AddBetweenSegments(4,40,4,1)
	band.AddBetweenSegments(6,38,1,4)
	band.AddBetweenSegments(6,38,4,1)
	band.AddBetweenSegments(8,36,1,4)

	band.AddBetweenSegments(37,52,1,4)
	band.AddBetweenSegments(37,52,4,1)
	band.AddBetweenSegments(39,50,1,4)
	band.AddBetweenSegments(39,50,4,1)
	band.AddBetweenSegments(41,48,1,4)
	band.AddBetweenSegments(41,48,4,1)
	band.AddBetweenSegments(43,46,1,4)
	band.AddBetweenSegments(43,46,4,1)

	band.AddBetweenSegments(45,64,4,1)
	band.AddBetweenSegments(47,62,1,4)
	band.AddBetweenSegments(47,62,4,1)
	band.AddBetweenSegments(49,60,1,4)
	band.AddBetweenSegments(49,60,4,1)
	band.AddBetweenSegments(51,58,1,4)
	band.AddBetweenSegments(51,58,4,1)
	band.AddBetweenSegments(53,56,1,4)

	band.AddBetweenSegments(63,66,4,1)
	band.AddBetweenSegments(65,82,1,4)

	band.AddBetweenSegments(68,80,1,4)
	band.AddBetweenSegments(68,80,4,1)
	band.AddBetweenSegments(70,78,1,4)
	band.AddBetweenSegments(70,78,4,1)
	band.AddBetweenSegments(72,76,1,4)
	band.AddBetweenSegments(72,75,4,1)

	band.AddBetweenSegments(77,96,4,1)
	band.AddBetweenSegments(79,94,1,4)
	band.AddBetweenSegments(79,94,4,1)
	band.AddBetweenSegments(81,92,1,4)
	band.AddBetweenSegments(81,92,4,1)
	band.AddBetweenSegments(83,90,1,4)
	band.AddBetweenSegments(83,90,4,1)
	band.AddBetweenSegments(85,88,1,4)
	band.AddBetweenSegments(85,88,4,1)

	band.AddBetweenSegments(89,106,1,4)
	band.AddBetweenSegments(89,106,4,1)
	band.AddBetweenSegments(91,104,1,4)
	band.AddBetweenSegments(91,104,4,1)
	band.AddBetweenSegments(93,102,1,4)
	band.AddBetweenSegments(93,102,4,1)
	band.AddBetweenSegments(95,100,1,4)
	band.AddBetweenSegments(95,99,4,1)

	band.AddBetweenSegments(103,118,1,4)
	band.AddBetweenSegments(103,118,4,1)
	band.AddBetweenSegments(105,116,1,4)
	band.AddBetweenSegments(105,116,4,1)
	band.AddBetweenSegments(107,114,1,4)
	band.AddBetweenSegments(107,114,4,1)
	band.AddBetweenSegments(109,112,1,4)
	band.AddBetweenSegments(109,112,4,1)

	band.AddBetweenSegments(113,128,1,4)
	band.AddBetweenSegments(113,128,4,1)
	band.AddBetweenSegments(115,126,1,4)
	band.AddBetweenSegments(115,126,4,1)
	band.AddBetweenSegments(117,124,1,4)
	band.AddBetweenSegments(117,124,4,1)
	band.AddBetweenSegments(119,122,1,4)
	band.AddBetweenSegments(119,122,4,1)

	band.AddBetweenSegments(125,12,1,4)
	band.AddBetweenSegments(125,12,4,1)
	band.AddBetweenSegments(127,10,1,4)
	band.AddBetweenSegments(127,10,4,1)
	band.AddBetweenSegments(127,9,4,1)
	band.AddBetweenSegments(129,7,1,4)
	band.AddBetweenSegments(127,7,4,1)
	band.AddBetweenSegments(131,5,1,4)
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
