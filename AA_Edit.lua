--[[
	AA Edit - get and set primary structure

	The primary structure of a protein is the sequence of the amino acids that make up the protein.

	AA Edit displays the current primary structure as a sequence of single-character amino acid codes. (Similar codes are used for DNA and RNA, see "SPECIAL CASES" below.)

	The displayed value can be selected and cut or copied.

	The string of single-character codes is similar to the FASTA format accepted by many protein related tools. FASTA also allows for header information, which some tools, such as BLAST, require.

	If there are any "mutable" segments, the "Change" button is displayed, and a a new value can be pasted in. If there are no mutable segments, any input to the "seq" box is ignored.

	When the "Change" button is clicked, the currently displayed primary structure is applied to the protein. The input amino acid codes are converted to lower case.

	The recipe checks each amino acid code against the list of 20 amino acids used in Foldit. Any input not found in the list is ignored, and the corresponding segment is left unchanged.

	Some puzzles have a mix of mutable and non-mutable segments. The recipe does not attempt to change any non-mutable segments.

	If the structure list is longer than the protein, AA Edit discards the extra entries at the end of the list.

	If the structure list is shorter than the protein, AA Edit applies the list to the first *n* segments of the protein, where *n* is the length of the list. Any remaining segments are unchanged.

	All changes are written to the scriptlog.

	SPECIAL CASES
	-------------

	Some puzzles contain two or more separate protein chains. The "insulin mutant" puzzle, which appears periodically as a revisiting puzzle, is an example.

	AA Edit detects the beginning and end of a protein chain by checking the atom count. Each chain is presented separately, identified by a chain id: "A", "B", "C", and so on.

	All the normal rules apply to each chain.

	Some puzzles have one or more ligands, each represented by a segment which returns "x" or "unk" for its amino acid type. This code and anything else not found in the normal list of 20 amino acids is changed to "x" for the purposes of this recipe.

	Segments with an "x" for their amino acid code in the replacment string are not changed.

	Each ligand is presented as a separate chain.

	Very rarely, Foldit puzzles may contain RNA or DNA. These are chains of nucleobases instead of amino acids. Each segment is one nucleobase. Foldit uses two-character codes for RNA and DNA. AA Edit translates these codes into single-character codes. The single-character codes are ambiguous, for example, RNA adenine is code "ra" in Foldit, and DNA adenine is "da". Both become "a" externally, which is also used for alanine in a protein.

	AA Edit treats each DNA or RNA section as a separate chain. This allows it to keep the ambiguous codes straight.

	The handling of RNA and DNA has only been tested for RNA. So far, RNA has only appeared on one science puzzle, and the RNA was not mutable in that puzzle. DNA has appeared only in intro puzzles, which don't allow recipes. It's possible that problems may appear if there are ever for-credit DNA or RNA puzzles again.

	An even rarer case was in found in puzzle 879, segment 134, and puzzle 1378b, segment 30, where an amino acid was modified by a glycan.

	The code "unk" was used for these modified amino acids, but they did not have the secondary structure code "M" used for ligands.

	A modified amino acid like this is treated as protein, and does not break the amino acid chain.

	See "AA Copy Paste Compare v 1.1.1 -- Brow42" for a full-function recipe that works with primary and primary structures.
]]--

-- Globals
scriptName = "AA Edit"
scriptVersion = 2.0.2.1
buildNumber = 1

isMutable = false -- true if any mutable segments found

aaLong = 1 -- Unused variable
aaCode = 2 -- Redundant for proteins, needed for DNA and RNA
aaAtom = 3
aaType = 4

--[[
			Third element is mid-chain atom count

			[NOTE: N-Terminus and C-Terminus amino acids will have different atom counts]

					N-Terminus has an extra Hydrogen atom on the first Nitrogen atom
					(This DOES NOT affect heavy atom count: the the extra H is the last atom)

					C-Terminus has an extra Oxygen atom (and extra Hydrogen)
					(This DOES affect heavy atom count: the beta carbon will be atom 6 instead of 5, shifting all other heaavy atoms up by one)
]]--

-- x = {"amino acid name", "single-letter-code", mid-chain atom count, "amino acid type"}
aaNames = {
	a = {"alanine", "a", 10, "P",},
	c = {"cysteine", "c", 11, "P",},
	d = {"aspartate", "d", 12, "P",},
	e = {"glutamate", "e", 15, "P",},
	f = {"phenylalanine", "f", 20, "P",},
	g = {"glycine", "g",  7, "P",},
	h = {"histidine", "h", 17, "P",},
	i = {"isoleucine", "i", 19, "P",},
	k = {"lysine", "k", 22, "P",},
	l = {"leucine", "l", 19, "P",},
	m = {"methionine", "m", 17, "P",},
	n = {"asparagine", "n", 14, "P",},
	p = {"proline", "p", 15, "P",},
	q = {"glutamine", "q", 17, "P",},
	r = {"arginine", "r", 24, "P",},
	s = {"serine", "s", 11, "P",},
	t = {"threonine", "t", 14, "P",},
	v = {"valine", "v", 16, "P",},
	w = {"tryptophan", "w", 24, "P",},
	y = {"tyrosine", "y", 21, "P",},

	-- Codes for ligands ("x" is common, but "unk" is historic)
	x   = {"ligand", "x",  0, "M",},
	unk = {"ligand", "x",  0, "M",},

	-- RNA nucleotides
	ra = {"adenine", "a",  0, "R",},
	rc = {"cytosine", "c",  0, "R",},
	rg = {"guanine", "g",  0, "R",},
	ru = {"uracil", "u",  0, "R",},

	-- DNA nucleotides (as seen in PDB, not confirmed for Foldit)
	da = {"adenine", "a",  0, "D",},
	dc = {"cytosine", "c",  0, "D",},
	dg = {"guanine", "g",  0, "D",},
	dt = {"thymine", "t",  0, "D",},
}

-- Modified AA if over this count
aaAtomMax = 27

-- Tables for converting external nucleobase codes to Foldit internal codes
rnaIn = {a = "ra", c = "rc", g = "rg", u = "ru",}
dnaIn = {a = "da", c = "dc", g = "dg", t = "dt",}
cTypes = {P = "protein", D = "DNA", R = "RNA", M = "ligand",}

-- Common section used by all safe functions
safefun = {}

--[[
	commonError -- common routine used by safe functions, checks for common errors checks for errors like bad segment and bad band index even for functions where they don't apply (efficiency not a key concern here)
	Any error that appears more than once gets tested here. First return codes may not be unique.
]]--

safefun.commonError = function(errmsg)
	local badSegment = "Segment index out of bounds"
	local agrumentCount = "Expected %d+ arguments."
	local badArgument = "Bad argument #%d+ to '%?' (%b())"
	local notExpected = "Expected, Got"
	local badAtom = "Atom number out of bounds"
	local badBand = "Band index out of bounds"
	local badSymmetry = "Symmetry index out of bounds"
	local badAminoAcid = "Invalid argument, unknown AA code"

	local errp, errq = errmsg:find(badSegment)
	if errp ~= nil then
		return -1, errmsg
	end

	-- "Bad Argument" messages include: argument type errors and some types of argument value errors.
	-- Trap only the argument type errors here
	local errp, errq, errd = errmsg:find(badArgument)
	if errp ~= nil then
		local errp2 = errd:find(notExpected)
		if errp2 ~= nil then
			return -997, errmsg -- Argument type error
		end
	end
	local errp, errq = errmsg:find(agrumentCount)
	if errp ~= nil then
		return -998, errmsg
	end
	local errp, errq = errmsg:find(badAtom)
	if errp ~= nil then
		return -2, errmsg
	end
	local errp, errq = errmsg:find(badBand)
	if errp ~= nil then
		return -3, errmsg
	end
	local errp, errq = errmsg:find(badAminoAcid)
	if errp ~= nil then
		return -2, errmsg
	end
	local errp, errq = errmsg:find(badSymmetry)
	if errp ~= nil then
		return -3, errmsg
	end
	return 0, errmsg
end

--  structure.SafeGetAminoAcid uses pcall to call structure.GetAminoAcid, returning a numeric return code.
--  If the return code is non-zero, an error message is also returned.
--[[
	The return codes are:
		0 		= Successful. Second returned value is the one-letter AA code of the specified segment (string).
		-1 		= bad segment index
		-99x 	= other error
]]--

structure.SafeGetAminoAcid = function(...)
	local good, errmsg = pcall(structure.GetAminoAcid, unpack(arg))
	if good then
		return 0, errmsg
	else
		local crc, err2 = safefun.commonError(errmsg)
		if crc ~= 0 then
			return crc, err2
		end
		return -999, err2
	end
end

function getAA(seg)
	local good, errmsg = structure.SafeGetAminoAcid(seg)
	if good ~= 0 then
		errmsg = "unk"
	end
	return errmsg
end

--[[
	Begin proteinInfo Beta package version 0.2a

	Version 0.2a is packaged as a psuedo-class or psuedo-module containing a mix of data fields and functions
		* All entries must be terminated with a comma to keep Lua happy
		* The commas aren't necessary if only function definitions are present
		* Removed some items found in 0.1 not needed here, added N-terminus and C-terminus checks, first and last analysis
		* This version depends on the external aaNames table and associated codes, so still a work in progress

	Version 0.2a contains a quick fix for Proline at N-terminus
		* Need to reconcile this version with the more extensive version in print protein
]]--

proteinInfo = {
	typeProtein = "P",
	typeLigand = "M",
	typeRNA = "R",
	typeDNA = "D",
	unknownAA = "x",
	unknownNucleobase = "xx",
	aaCysteine = "c",
	aaProline = "p",
	aaCode = {}, -- Amino Acid codes
	ssCode = {}, -- Secondary Structure codes
	atomCount = {}, -- Atom counts
	flagMutable = {}, -- Mutable flag
	ctype = {}, -- Segment type - P, M, R, D
	isFirst = {}, -- True if segment is first in chain
	isLast = {}, -- True if segment is last in chain
	isNTerminus = {}, -- True if protein and if n-terminal
	isCTerminus = {}, -- True if protein and if c-terminal
	outputFASTA = {}, -- External code for FASTA-style output

	setInfo = function()
		local segCnt = structure.GetCount()
		-- Initial scan: retrieve basic information from Foldit
		for ii = 1, segCnt do
			local isNTerminus = false
			local isCTerminus = false

			proteinInfo.aaCode[#proteinInfo.aaCode + 1] = getAA(ii)
			proteinInfo.ssCode[#proteinInfo.ssCode + 1] = structure.GetSecondaryStructure(ii)
			proteinInfo.atomCount[#proteinInfo.atomCount + 1] = structure.GetAtomCount(ii)
			proteinInfo.flagMutable[#proteinInfo.flagMutable + 1] = structure.IsMutable(ii)
			local aatab = aaNames[proteinInfo.aaCode[ii]]
			if aatab ~= nil then
				proteinInfo.ctype[#proteinInfo.ctype + 1] = aatab[aaType]

				-- Special case for puzzles 879, 1378b, and similar (if unknown amino acid, but secondary structure is not ligand, mark it as protein) [Segment 134 in puzzle 879 is the example]
				if proteinInfo.ctype[ii] == proteinInfo.typeLigand and proteinInfo.ssCode[ii] ~= proteinInfo.typeLigand then
					proteinInfo.ctype[ii] = proteinInfo.typeProtein
				end
			else
				proteinInfo.ctype[#proteinInfo.ctype + 1] = proteinInfo.typeLigand
				aaCode = proteinInfo.unknownAA
			end

			-- For proteins: determine n-terminal and c-terminal based on atom count
			if proteinInfo.ctype[ii] == proteinInfo.typeProtein then
				local ttyp = ""
				local noteable = false
				local ac = proteinInfo.atomCount[ii]  -- actual atom count
				local act = aatab[aaAtom]    -- reference mid-chain atom count
					if ac ~= act or (proteinInfo.aaCode[ii] == proteinInfo.aaCysteine and ac == act) then
						ttyp = "non-standard amino acid"
						if ac == act + 2 then
							ttyp = "N-terminal"
							isNTerminus = true
							notable = true
						elseif ac == act + 1 then
							ttyp = "C-terminal"
							isCTerminus = true
							notable = true
						elseif proteinInfo.aaCode[ii] == proteinInfo.aaProline and ac == act + 3 then
							ttyp = "N-terminal"
							isNTerminus = true
							notable = true
						end
						if proteinInfo.aaCode[ii] == proteinInfo.aaCysteine then
							local ds = current.GetSegmentEnergySubscore(ii, "Disulfides")
							if ds ~= 0 and math.abs(ds) > 0.01 then
								isNTerminus = false
								isCTerminus = false
								ttyp = "Disulfide bridge"
								if ac == act + 1 then
									ttyp = "N-terminal"
									isNTerminus = true
								elseif ac == act then
									ttyp = "C-terminal"
									isCTerminus = true
								end
								notable = true
							else
								ttyp = "Unpaired cysteine"
								notable = false
							end
						end
						if notable then
							print(ttyp .. " detected at segment " .. ii .. ", amino acid = \'" .. proteinInfo.aaCode[ii] .. "\', atom count = " .. ac .. ", reference count = " .. act .. ", secondary structure = " .. proteinInfo.ssCode[ii])
						end
					end
			end
			if  proteinInfo.ctype[ii] == proteinInfo.typeLigand then
				print("Ligand detected at segment " .. ii)
			end
			proteinInfo.isNTerminus[#proteinInfo.isNTerminus + 1] = isNTerminus
			proteinInfo.isCTerminus[#proteinInfo.isCTerminus + 1] = isCTerminus

			proteinInfo.outputFASTA[#proteinInfo.outputFASTA + 1] = aatab[aaCode]
		end

		-- Rescan to determine first and last in chain for all types
		-- It's necessary to "peek" at neighbors for DNA and RNA
		for ii = 1, segCnt do
			local isNTerminus = proteinInfo.isNTerminus[ii]
			local isCTerminus = proteinInfo.isCTerminus[ii]
			local isFirst = false
			local isLast = false
			if ii == 1 then
				isFirst = true
			end
			if ii == segCnt then
				isLast = true
			end
			if proteinInfo.ctype[ii] == proteinInfo.typeProtein then
				if proteinInfo.isNTerminus[ii] then
					isFirst = true
				end
				if proteinInfo.isCTerminus[ii] then
					isLast = true
				end
				-- kludge for cases where binder target doesn't have an identifiable C terminal
				if ii < segCnt then
					if   proteinInfo.ctype[ii] == proteinInfo.typeProtein or (proteinInfo.ctype[ii] == proteinInfo.typeProtein and proteinInfo.isNTerminus[ii + 1]) then
						isLast = true
					end
				end

				-- Special case for puzzles 879, 1378b, and similar (if modified AA ends or begins a chain, mark it as C-terminal or N-terminal)
				-- Hypothetical: no way to test so far!
				if aaNames[proteinInfo.aaCode[ii]][aaCode] == proteinInfo.unknownAA then
					if ii > 1 and proteinInfo.ctype[ii - 1] ~= proteinInfo.ctype[ii] then
						isFirst = true
						proteinInfo.isNTerminus[ii] = true
						print("Non-standard amino acid at segment " .. ii .. " marked as N-terminal")
					end
					if ii < segCnt and proteinInfo.ctype[ii + 1] ~= proteinInfo.ctype[ii] then
						isLast = true
						proteinInfo.isCTerminus[ii] = true
						print("Non-standard amino acid at segment " .. ii .. " marked as C-terminal")
					end
				end
			elseif proteinInfo.ctype[ii] == proteinInfo.typeDNA or proteinInfo.ctype[ii] == proteinInfo.typeRNA then
				if ii > 1 and proteinInfo.ctype[ii - 1] ~= proteinInfo.ctype[ii] then
					isFirst = true
				end
				if ii < segCnt and proteinInfo.ctype[ii + 1] ~= proteinInfo.ctype[ii] then
					isLast = true
				end
			else -- ligand
				isFirst = true
				isLast = true
			end
			proteinInfo.isFirst[#proteinInfo.isFirst + 1] = isFirst
			proteinInfo.isLast[#proteinInfo.isLast + 1] = isLast
		end
	end, -- end function setInfo()
} --  end proteinInfo Beta package version 0.2
--  end of globals section

function getChains()
	--[[
	getChains - Build a table of the chains found

	Most Foldit puzzles contain only a single protein (peptide) chain. A few puzzles contain ligands, and some puzzles have had two
	protein chains. Foldit puzzles may also contain RNA or DNA.

	For proteins, the atom count can be used to identify the first (N terminal) and last (C terminal) ends of the chain. The aaNames table has the mid-chain atom counts for each amino acid.

	Cysteine is a special case, since the presence of a disulfide bridge also changes the atom count.

	For DNA and RNA, the beginning and end of the chain is determined by context at present. For example, if the previous segment was protein and this segment is DNA, it's the start of a chain.

	Each ligand is treated as a chain of its own, with a length of 1.

	CHAIN TABLE ENTRIES
	-------------------
	ctype - chain type - "P" for protein, "M" for ligand, "R" for RNA, "D" for DNA
	fasta - FASTA-format sequence, single-letter codes (does not include FASTA header)
	fastab - "backup" of fasta
	start - Foldit segment number of sequence start
	stop - Foldit segment number of sequence end
	len - length of sequence
	chainid - chain id assigned to entry, "A", "B", "C", and so on
	flagMutable - number of mutable segments

	For DNA and RNA, fasta and fastab contain single-letter codes, so "a" for adenine. The codes overlap the amino acid codes (for example, "a" for alanine). The DNA and RNA codes must be converted to the appropriate two-letter codes Foldit uses internally, for example "ra" for RNA adenine and "da" for DNA adenine.

	We're assuming Foldit won't ever have more chains
]]--

	local chainid = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"}
	local chainz = {}
	local chindx = 0
	local curchn = nil

	local segCnt = structure.GetCount()

	for ii = 1, segCnt do
		if proteinInfo.isFirst[ii] then
			chindx = chindx + 1
			chainz[chindx] = {}
			curchn = chainz[chindx]
			curchn.ctype = proteinInfo.ctype[ii]
			curchn.fasta = ""
			curchn.start = ii
			curchn.chainid = chainid[chindx]
			curchn.flagMutable = 0
			curchn.len = 0
		end

		curchn.fasta = curchn.fasta .. proteinInfo.outputFASTA[ii]
		if proteinInfo.flagMutable[ii] then
			curchn.flagMutable = curchn.flagMutable + 1
		end

		if proteinInfo.isLast[ii] then
			curchn.stop = ii
			curchn.len = curchn.stop -(curchn.start - 1)
		end
	end

	for ii = 1, #chainz do
		chainz[ii].fastab = chainz[ii].fasta
	end
	return chainz
end

function setChain(chain)
	local changes = 0
	local errz = 0
	local offset = chain.start - 1

	local fastan = "" -- possibly changed chain
	for ii = 1, chain.stop - (chain.start - 1) do
		local sType = chain.fasta:sub(ii, ii)
		local oType = chain.fastab:sub(ii, ii)

		-- for DNA and RNA, convert FASTA to Foldit
		if chain.ctype == proteinInfo.typeDNA then
			sType = dnaIn[sType]
				if sType == nil then
					sType = proteinInfo.unknownNucleobase
				end
				oType = dnaIn[oType]
				if oType == nil then
					oType = proteinInfo.unknownNucleobase
				end
		elseif chain.ctype == proteinInfo.typeRNA then
			sType = rnaIn[sType]
			if sType == nil then
				sType = proteinInfo.unknownNucleobase
			end
			oType = rnaIn[oType]
			if oType == nil then
				oType = proteinInfo.unknownNucleobase
			end
		end

		if sType ~= oType then
			local sName = aaNames[sType]
			if sName ~= nil then
				if proteinInfo.flagMutable[ii + offset] then
					structure.SetAminoAcid(ii + offset, sType)
					local newaa = structure.GetAminoAcid(ii + offset)
					if newaa == sType then
						changes = changes + 1
						fastan = fastan .. aaNames[sType][aaCode]
					else
						print("Segment " .. ii + offset .. " (" .. chain.chainid .. ":" ..  ii ..	") mutation to type \"" .. sType .. "\" failed")
						errz = errz + 1
						fastan = fastan .. aaNames[oType][aaCode]
					end
				else
					print("Segment " .. ii + offset .." (" .. chain.chainid .. ":" ..  ii .. ") is not mutable, skipping change to type \""	.. sType .. "\"")
					errz = errz + 1
					fastan = fastan .. aaNames[oType][aaCode]
				end
			else
				print("Segment " .. ii + offset .. " ("	.. chain.chainid .. ":" ..  ii ..	"), skipping invalid type \""	.. sType ..	"\"")
				errz = errz + 1
				fastan = fastan .. aaNames[oType][aaCode]
			end
		else
			fastan = fastan .. aaNames[oType][aaCode]
		end
	end
	chain.fasta = fastan
	chain.fastab = fastan
	return changes, errz
end

function GetParameters(chnz, peptides, gchn, minseg, maxseg, totlen, totmut)
	local dlog = dialog.CreateDialog(scriptName)

	dlog.sc0  = dialog.AddLabel("Segment count = " .. structure.GetCount())
	local cwd = "chain"
	if #chnz > 1 then
		cwd = "chains"
	end
	dlog.chz  = dialog.AddLabel(#chnz .. " chains")
	for ii = 1, #chnz do
		local chain = chnz[ii]
		dlog["chn" .. ii .. "l1"] = dialog.AddLabel("Chain " .. chain.chainid .. " ("	.. cTypes[chnz[ii].ctype] .. ")")
		dlog["chn" .. ii .. "l2"] = dialog.AddLabel ("Segments " .. chain.start ..	"-"	.. chain.stop .. ", mutables = " .. chain.flagMutable ..	", length = "	.. chain.len)
		dlog["chn" .. ii .. "ps"] = dialog.AddTextbox("Seq", chain.fasta)
	end

	dlog.u0 = dialog.AddLabel("")
	if isMutable then
		dlog.u1 = dialog.AddLabel("Usage: click in text box, ")
		dlog.u2 = dialog.AddLabel("then use select all and copy, cut, or paste")
		dlog.u3 = dialog.AddLabel("to save or change primary structure")
	else
		dlog.u1 = dialog.AddLabel("Usage: click in text box,")
		dlog.u2 = dialog.AddLabel("then use select all and copy")
		dlog.u3 = dialog.AddLabel("to save primary structure")
	end
	dlog.w0 = dialog.AddLabel("")
	if isMutable then
		dlog.w1 = dialog.AddLabel("Windows: Ctrl + A = select all")
		dlog.w2 = dialog.AddLabel("Windows: Ctrl + X = cut")
		dlog.w3 = dialog.AddLabel("Windows: Ctrl + C = copy")
		dlog.w4 = dialog.AddLabel("Windows: Ctrl + V = paste")
	else
		dlog.w1 = dialog.AddLabel("Windows: Ctrl + A = select all")
		dlog.w3 = dialog.AddLabel("Windows: Ctrl + C = copy")
	end
	dlog.z0 = dialog.AddLabel("")

	if isMutable then
		dlog.ok = dialog.AddButton("Change" , 1)
	end
	dlog.exit = dialog.AddButton("Exit" , 0)

	if dialog.Show(dlog) > 0 then
		for ii = 1, #chnz do
			chnz[ii].fasta = dlog["chn" .. ii .. "ps"].value:lower():sub(1, chnz[ii].len)
		end
		return true
	else
		return false
	end
end

function main()
	print(scriptName)
	print("Puzzle: " .. puzzle.GetName())
	print("Track: " .. ui.GetTrackName())

	proteinInfo.setInfo()

	for ii = 1, structure.GetCount() do
		if proteinInfo.flagMutable[ii] == true then
			isMutable = true
			break
		end
	end

	local changeNum = 0
	local chnTbl = {} -- chains as table of tables
	chnTbl = getChains()
	print(#chnTbl .. " chains and ligands")

	local totlen = 0
	local maxlen = 0
	local chncnt = 0
	local mutchn = 0
	local totmut = 0
	local gchn = ""
	local minseg = 99999
	local maxseg = 0

	for ii = 1, #chnTbl do
		local chain = chnTbl[ii]
		if chain.stop == nil then
			chain.stop = 999999
		end
		if chain.ctype ~= "M" then
			print("chain " .. chain.chainid .. ", start = " .. chain.start .. ", end = " .. chain.stop .. ", length = " .. chain.len .. ", mutables = " .. chain.flagMutable)
			print(chain.fasta)
			gchn = gchn .. chain.fasta
			chncnt = chncnt + 1
			if chain.flagMutable > 0 then
				mutchn = mutchn + 1
			end
			if chain.start < minseg then
				minseg = chain.start
			end
			if chain.stop > maxseg then
				maxseg = chain.stop
			end
			totlen = totlen + chain.len
			if chain.len > maxlen then
				maxlen = chain.len
			end
		else
			print("ligand " .. chain.chainid .. ", segment = " .. chain.start)
		end
	end

	-- Assume the worst if average length is under 25
	local peptides = false
	local newchn = {}
	local avglen = totlen / chncnt
	if avglen < 25 and mutchn == 0 then
		peptides = true
		print("Multiple immutable peptides found")
		print("These are likely fragments of a larger protein")
		print("Combined sequence:")
		print(gchn)
		newchn = {ctype = "P", fasta = gchn, fastab = gchn, start = minseg, stop = maxseg, len = totlen, chainid = "A", flagMutable = totmut,}
	end
	if peptides then
		local mrgchn = {}
		for ii = 1, #chnTbl do
			-- TODO: rewrite the table
		end
	end

	while GetParameters(chnTbl, peptides, gchn, minseg, maxseg, totlen, totmut) do
		for ii = 1, #chnTbl do
			local chain = chnTbl[ii]
			if chain.fasta ~= chain.fastab then
				print("--")
				print("chain " .. chain.chainid .. " changed")

				local old = chain.fastab
				changeNum = changeNum + 1
				local start_time = os.time()

				behavior.SetFiltersDisabled(true)
				local sChg, sErr = setChain(chnTbl[ii])
				behavior.SetFiltersDisabled(false)

				print("Segments changed = " .. sChg .. ", Errors = " .. sErr)
				print("Old chain " .. chain.chainid .. ": ")
				print(old)
				print("New chain " .. chain.chainid .. ": ")
				print(chain.fastab)
			end
		end
	end
	cleanup()
end

function cleanup(errmsg)
	if CLEANUPENTRY ~= nil then
		return
	end
	CLEANUPENTRY = true

	print("---")

	local reason
	local start, stop, line, msg
	if errmsg == nil then
		reason = "complete"
	else
		start, stop, line, msg = errmsg:find(":(%d+):%s()")
		if msg ~= nil then
			errmsg = errmsg:sub(msg, #errmsg)
		end
		if errmsg:find("Cancelled") ~= nil then
			reason = "cancelled"
		else
			reason = "error"
		end
	end

	print(scriptName .. " " .. reason)
	print("Puzzle: " .. puzzle.GetName())
	print("Track: " .. ui.GetTrackName())

	if reason == "error" then
		print ("Unexpected error detected")
		print ("Error line: " .. line)
		print ("Error: \"" .. errmsg .. "\"")
	end
	behavior.SetFiltersDisabled(false)
end

xpcall(main, cleanup)
