scriptName = "ListBonds 1.0"
buildNumber = 2
numSegments = structure.GetCount()

function getBonds()
	bondTable = structure.GetHBonds()
	return bondTable
end

function checkDisulfides()
	disulfideBridgeCount = 0
	if #bondTable == 0 then
		getBonds()
	end
	for i = 1, #bondTable do
		if bondTable[i]["bond_type"] == 1 then
			disulfideBridgeCount = disulfideBridgeCount + 1
		end
	end
end

function printBonds()
	if #bondTable == 0 then
		getBonds()
	end
	print("HYDROGEN BONDS")
	for i = 1, #bondTable do
		if bondTable[i]["bond_type"] == 0 then
			print("Bond: " . i, bondTable[i]["bond_type"], bondTable[i]["res1"], bondTable[i]["atom1"], bondTable[i]["res2"], bondTable[i]["atom2"], bondTable[i]["width"])
		end
	end
	if disulfideBridgeCount ~= 0 then
		print("DISULFIDE BRIDGES")
		for i = 1, #bondTable do
			if bondTable[i]["bond_type"] == 1 then
				print("Bond: " . i, bondTable[i]["bond_type"], bondTable[i]["res1"], bondTable[i]["atom1"], bondTable[i]["res2"], bondTable[i]["atom2"], bondTable[i]["width"])
			end
		end
	end
end

function cleanup(err)
	print(err)
end

function main()
	print(scriptName, buildNumber)
	getBonds()
	printBonds()
end

xpcall(main, cleanup)
