--[[
        AA Edit - get and set primary structure

        The primary structure of a protein is the sequence of the 
        amino acids that make up the protein.

        AA Edit displays the current primary structure as a sequence
        of single-character amino acid codes. (Similar codes are 
        used for DNA and RNA, see "special cases" below.)

        The displayed value can be selected and cut or copied.

        The string of single-character codes is similar to the 
        FASTA format accepted by many protein related tools. 
        FASTA also allows for header information, which some tools, 
        such as BLAST, require.

        If there are any "mutable" segments, the "Change" button  
        is displayed, and a a new value can be pasted in. If there are 
        no mutable segments, any input to the "seq" box is ignored.
        
        When the "Change" button is clicked, the currently displayed 
        primary structure is applied to the protein. The input amino
        acid codes are converted to lower case.
        
        The recipe checks each amino acid code against the list of 20
        amino acids used in Foldit. Any input not found in the list is 
        ignored, and the corresponding segment is left unchanged.

        Some puzzles have a mix of mutable and non-mutable segments.
        The recipe does not attempt to change any non-mutable segments.

        If the structure list is longer than the protein, AA Edit 
        discards the extra entries at the end of the list. 
        
        If the structure list is shorter than the protein, AA Edit
        applies the list to the first *n* segments of the protein, 
        where *n* is the length of the list. Any remaining segments
        are unchanged.

        All changes are written to the scriptlog.
        
        special cases
        -------------

        Some puzzles contain two or more separate protein chains.
        The "insulin mutant" puzzle, which appears periodically as a 
        revisiting puzzle, is an example. 

        AA Edit detects the beginning and end of a protein chain by 
        checking the atom count. Each chain is presented separately, 
        identified by a chain id: "A", "B", "C", and so on. 

        All the normal rules apply to each chain. 
        
        Some puzzles have one or more ligands, each represented by a segment 
        which returns "x" or "unk" for its amino acid type. This code and 
        anything else not found in the normal list of 20 amino acids
        is changed to "x" for the purposes of this recipe. 

        Segments with an "x" for their amino acid code in the replacment
        string are not changed.

        Each ligand is presented as a separate chain. 

        Very rarely, Foldit puzzles may contain RNA or DNA. These are chains
        of nucleobases instead of amino acids. Each segment is one nucleobase.
        Foldit uses two-character codes for RNA and DNA. AA Edit translates
        these codes into single-character codes. The single-character codes are 
        ambiguous, for example, RNA adenine is code "ra" in Foldit, and DNA 
        adenine is "da". Both become "a" externally, which is also used 
        for alanine in a protein. 

        AA Edit treats each DNA or RNA section as a separate chain. This allows
        it to keep the ambiguous codes straight. 

        The handling of RNA and DNA has only been tested for RNA. So far, RNA has 
        only appeared on one science puzzle, and the RNA was not mutable in 
        that puzzle. DNA has appeared only in intro puzzles, which don't allow 
        recipes. It's possible that problems may appear if there are ever
        for-credit DNA or RNA puzzles again.
        
        An even rarer case was in found in puzzle 879, segment 134, and 
        puzzle 1378b, segment 30, where an amino acid was modified by 
        a glycan. 
        
        The code "unk" was used for these modified amino acids, but they 
        did not have the secondary structure code "M" used for ligands.

        A modified amino acid like this is treated as protein, and does not break
        the amino acid chain.

        See "AA Copy Paste Compare v 1.1.1 -- Brow42" for 
        a full-function recipe that works with primary and
        primary structures.

        version 1.2 -- 2016/12/23 -- LociOiling
        * clone of PS Edit v1.2 
        * enable 1-step undo with undo.SetUndo ( false )

        version 2.0 -- 2018/09/02 -- LociOiling
        * detect and report multiple chains
        * force filters on at beginning and end
        * handle DNA and RNA, use single-letter codes externally
        * refine scriptlog output, eliminate timing calls
        version 2.0.1 -- 2020/04/16 -- LociOiling
        * handle proline at N-terminal correctly
        version 2.0.2 -- 2022/05/20 -- LociOiling
        * handle cases where structure.GetAminoAcid throws an error
        * handle lots of little peptides
        * don't treat ligands as chains
        * handle a binder target (or similar) with no C-term
        * fix bug in setChain

]]--

--
-- Globals
--
Recipe = "AA Edit"
Version = "2.0.2"
ReVersion = Recipe .. " " .. Version

mutable = false -- true if any mutable segments found

AALONG = 1 
AACODE = 2 -- redundant for proteins, needed for DNA and RNA
AAATOM = 3
AATYPE = 4
--
--  amino acid names and abbeviations,
--  third element is mid-chain atom count
--
AANames = {
    a = { "alanine",        "a", 10, "P", },
    c = { "cysteine",       "c", 11, "P", },
    d = { "aspartate",      "d", 12, "P", },
    e = { "glutamate",      "e", 15, "P", },
    f = { "phenylalanine",  "f", 20, "P", },
    g = { "glycine",        "g",  7, "P", },
    h = { "histidine",      "h", 17, "P", },
    i = { "isoleucine",     "i", 19, "P", },
    k = { "lysine",         "k", 22, "P", },
    l = { "leucine",        "l", 19, "P", },
    m = { "methionine",     "m", 17, "P", },
    n = { "asparagine",     "n", 14, "P", },
    p = { "proline",        "p", 15, "P", },
    q = { "glutamine",      "q", 17, "P", },
    r = { "arginine",       "r", 24, "P", },
    s = { "serine",         "s", 11, "P", },
    t = { "threonine",      "t", 14, "P", },
    v = { "valine",         "v", 16, "P", },
    w = { "tryptophan",     "w", 24, "P", },
    y = { "tyrosine",       "y", 21, "P", },
--
--  bonus! codes for ligands ("x" is common, but "unk" is historic)
--
    x   = { "ligand",       "x",  0, "M", },
    unk = { "ligand",       "x",  0, "M", },
--
--  bonus!  RNA nucleotides
--
    ra = { "adenine",       "a",  0, "R", },
    rc = { "cytosine",      "c",  0, "R", },
    rg = { "guanine",       "g",  0, "R", },
    ru = { "uracil",        "u",  0, "R", },
--
--  bonus!  DNA nucleotides (as seen in PDB, not confirmed for Foldit)
--
    da = { "adenine",       "a",  0, "D", },
    dc = { "cytosine",      "c",  0, "D", },
    dg = { "guanine",       "g",  0, "D", },
    dt = { "thymine",       "t",  0, "D", },
}
AA_ATOM_MAX = 27    -- modified AA if over this count
--
--  tables for converting external nucleobase codes to Foldit internal codes
--
RNAin = {
    a = "ra",
    c = "rc", 
    g = "rg",
    u = "ru",
}
DNAin = {
    a = "da",
    c = "dc",
    g = "dg",
    t = "dt",
}

Ctypes = {
    P = "protein", 
    D = "DNA", 
    R = "RNA", 
    M = "ligand",
}

--
--  common section used by all safe functions
--
safefun = {}

--
--  CommonError -- common routine used by safe functions,
--                 checks for common errors              
--
--  checks for errors like bad segment and bad band index
--  even for functions where they don't apply -- efficiency
--  not a key concern here
--
--  any error that appears more than once gets tested here
--
--  first return codes may not be unique
--
safefun.CommonError = function ( errmsg )
    local BADSEG    = "segment index out of bounds" 
    local ARGCNT    = "Expected %d+ arguments."
    local BADARG    = "bad argument #%d+ to '%?' (%b())"
    local EXPECT    = "expected, got"
    local BADATOM   = "atom number out of bounds" 
    local BADBAND   = "band index out of bounds"
    local BADSYMM   = "symmetry index out of bounds"
    local BADACID   = "invalid argument, unknown aa code" 

    local errp, errq = errmsg:find ( BADSEG )
    if errp ~= nil then
        return -1, errmsg
    end
--
--  "bad argument" messages include argument type errors 
--  and some types of argument value errors
--  trap only the argument type errors here
--
    local errp, errq, errd = errmsg:find ( BADARG )
    if errp ~= nil then
        local errp2 = errd:find ( EXPECT )
        if errp2 ~= nil then
            return -997, errmsg -- argument type error
        end
    end
    local errp, errq = errmsg:find ( ARGCNT )
    if errp ~= nil then
        return -998, errmsg
    end
    local errp, errq = errmsg:find ( BADATOM )
    if errp ~= nil then
        return -2, errmsg
    end
    local errp, errq = errmsg:find ( BADBAND )
    if errp ~= nil then
        return -3, errmsg
    end
    local errp, errq = errmsg:find ( BADACID )
    if errp ~= nil then
        return -2, errmsg
    end
    local errp, errq = errmsg:find ( BADSYMM )
    if errp ~= nil then
        return -3, errmsg
    end
    return 0, errmsg
end

--
--  end of common section used by all safe functions
--

--
--  structure.SafeGetAminoAcid uses pcall
--  to call structure.GetAminoAcid, returning
--  a numeric return code.
--
--  If the return code is non-zero,
--  an error message is also returned.
--
--  The return codes are:
--
--     0 - successful, second returned value is
--         the one-letter amino acid code 
--         of the specified segment (string).
--    -1 - bad segment index
--  -99x - other error
--
structure.SafeGetAminoAcid = function ( ... )
    local good, errmsg = pcall ( structure.GetAminoAcid, unpack ( arg ) )
    if good then
        return 0, errmsg
    else
        local crc, err2 = safefun.CommonError ( errmsg )
        if crc ~= 0 then
            return crc, err2
        end        
        return -999, err2
    end
end

function GetAA ( seg )
    local good, errmsg = structure.SafeGetAminoAcid ( seg )
    if good ~= 0 then
        errmsg = "unk"
    end
    return errmsg
end

--
--  begin protNfo Beta package version 0.2a
--
--  version 0.2a is packaged as a psuedo-class or psuedo-module
--  containing a mix of data fields and functions
--
--  all entries must be terminated with a comma to keep Lua happy
--
--  the commas aren't necessary if only function definitions are present
--
--  removed some items found in 0.1 not needed here,
--  added N-terminal and C-terminal checks, first and last analysis
--
--  this version depends on the external AANames table and associated codes,
--  so still a work in progress
--
--  version 0.2a contains a quick fix for proline at N-terminal
--
--  need to reconcile this version with the more extensive version in print protein
--
protNfo = {
    PROTEIN = "P",
    LIGAND = "M", 
    RNA = "R",
    DNA = "D",
    UNKNOWN_AA = "x",
    UNKNOWN_BASE = "xx",
    CYSTEINE_AA = "c",
    PROLINE_AA = "p",
    aa = {},    -- amino acid codes
    ss = {},    -- secondary structure codes
    atom = {},  -- atom counts
    mute = {},  -- mutable flag
    ctype = {}, -- segment type - P, M, R, D
    first = {}, -- true if segment is first in chain
    last = {},  -- true if segment is last in chain
    nterm = {}, -- true if protein and if n-terminal
    cterm = {}, -- true if protein and if c-terminal
    fastac = {}, -- external code for FASTA-style output
    
    
    setNfo = function ()
        local segCnt = structure.GetCount () 
    --
    --  initial scan: retrieve basic information from Foldit
    --
        for ii = 1, segCnt do
            local nterm = false
            local cterm = false

            protNfo.aa [ #protNfo.aa + 1 ] = GetAA ( ii )
            protNfo.ss [ #protNfo.ss + 1 ] = structure.GetSecondaryStructure ( ii )
            protNfo.atom [ #protNfo.atom + 1 ] = structure.GetAtomCount ( ii )
            protNfo.mute [ #protNfo.mute + 1 ] = structure.IsMutable ( ii )
            local aatab = AANames [ protNfo.aa [ ii ] ]
            if aatab ~= nil then
                protNfo.ctype [ #protNfo.ctype + 1 ] = aatab [ AATYPE ]
            --
            --  special case for puzzles 879, 1378b, and similar
            --
            --  if unknown amino acid, but secondary structure is not
            --  ligand, mark it as protein
            --
            --  segment 134 in puzzle 879 is the example
            --
                if protNfo.ctype [ ii ] == protNfo.LIGAND
                and   protNfo.ss [ ii ] ~= protNfo.LIGAND then
                    protNfo.ctype [ ii ] = protNfo.PROTEIN
                end
            else
                protNfo.ctype [ #protNfo.ctype + 1 ] = protNfo.LIGAND
                aa = protNfo.UNKNOWN_AA
            end
        --
        --  for proteins, determine n-terminal and c-terminal
        --  based on atom count
        --
            if protNfo.ctype [ ii ] == protNfo.PROTEIN then
                local ttyp = ""
                local noteable = false
                local ac = protNfo.atom [ ii ]  -- actual atom count 
                local act = aatab [ AAATOM ]    -- reference mid-chain atom count
                if ac ~= act 
                or ( protNfo.aa [ ii ] == protNfo.CYSTEINE_AA and ac == act ) then
                    ttyp = "non-standard amino acid"
                    if     ac == act + 2 then
                        ttyp = "N-terminal"
                        nterm = true
                        notable = true
                    elseif ac == act + 1 then
                        ttyp = "C-terminal"
                       cterm = true
                       notable = true
                    elseif protNfo.aa [ ii ] == protNfo.PROLINE_AA and ac == act + 3 then
                        ttyp = "N-terminal"
                        nterm = true
                        notable = true
                    end
                    if protNfo.aa [ ii ] == protNfo.CYSTEINE_AA then
                        local ds = current.GetSegmentEnergySubscore ( ii, "Disulfides" )
                        --  print ( "cysteine at " .. ii .. ", disulfides score = " .. ds ) 
                        if ds ~= 0 and math.abs ( ds ) > 0.01 then
                            nterm = false
                            cterm = false
                            ttyp = "disulfide bridge"
                            if     ac == act + 1 then
                                ttyp = "N-terminal"
                                nterm = true
                            elseif ac == act then
                                ttyp = "C-terminal"
                                cterm = true
                            end
                            notable = true
                        else
                            ttyp = "unpaired cysteine"
                            notable = false
                        end
                    end
                    if notable then
                        print ( ttyp ..
                                " detected at segment " 
                                    .. ii ..
                                ", amino acid = \'" 
                                    .. protNfo.aa [ ii ] ..
                                "\', atom count = "
                                    .. ac ..
                                ", reference count = "
                                    .. act ..
                                ", secondary structure = " 
                                    .. protNfo.ss [ ii ]
                              )
                    end
                end
            end
            if  protNfo.ctype [ ii ] == protNfo.LIGAND then
                print ( "ligand detected at segment " .. ii )
            end
            protNfo.nterm [ #protNfo.nterm + 1 ] = nterm
            protNfo.cterm [ #protNfo.cterm + 1 ] = cterm
            
            protNfo.fastac [ #protNfo.fastac + 1 ] = aatab [ AACODE ] 
        end
    --
    --  rescan to determine first and last in chain for all types
    --  it's necessary to "peek" at neighbors for DNA and RNA
    --
        for ii = 1, segCnt do
            local nterm = protNfo.nterm [ ii ]
            local cterm = protNfo.cterm [ ii ]
            local first = false
            local last = false
            if ii == 1 then 
                first = true
            end
            if ii == segCnt then
                last = true
            end
            if protNfo.ctype [ ii ] == protNfo.PROTEIN then
                if protNfo.nterm [ ii ] then
                    first = true
                end
                if protNfo.cterm [ ii ] then
                    last = true
                end
            --
            --  kludge for cases where binder target doesn't
            --  have an identifiable C terminal
            --
                if ii < segCnt then
                    if   protNfo.ctype [ ii ] == protNfo.PROTEIN
                    or ( protNfo.ctype [ ii ] == protNfo.PROTEIN and protNfo.nterm [ ii + 1 ] ) then
                        last = true
                    end
                end
            --
            --  special case for puzzles 879, 1378b, and similar
            --
            --  if modified AA ends or begins a chain, mark 
            --  it as C-terminal or N-terminal
            --
            --  hypothetical: no way to test so far!
            --
                if AANames [ protNfo.aa [ ii ] ] [ AACODE ] == protNfo.UNKNOWN_AA then
                    if ii > 1 and protNfo.ctype [ ii - 1 ] ~= protNfo.ctype [ ii ] then
                        first = true
                        protNfo.nterm [ ii ] = true
                        print ( "non-standard amino acid at segment "
                                    .. ii .. 
                              " marked as N-terminal" )
                    end
                    if ii < segCnt and protNfo.ctype [ ii + 1 ] ~= protNfo.ctype [ ii ] then
                        last = true
                        protNfo.cterm [ ii ] = true
                        print ( "non-standard amino acid at segment "
                                    .. ii .. 
                                " marked as C-terminal" )
                    end
                end
            elseif protNfo.ctype [ ii ] == protNfo.DNA
            or     protNfo.ctype [ ii ] == protNfo.RNA then
                if ii > 1 and protNfo.ctype [ ii - 1 ] ~= protNfo.ctype [ ii ] then
                    first = true
                end
                if ii < segCnt and protNfo.ctype [ ii + 1 ] ~= protNfo.ctype [ ii ] then
                    last = true
                end
            else -- ligand
                first = true
                last = true
            end
            protNfo.first [ #protNfo.first + 1 ] = first
            protNfo.last [ #protNfo.last + 1 ] = last
        end
    end,
}
--
--  end protNfo Beta package version 0.2
--

--
--  end of globals section
--


function getChains ()
--
--  getChains - build a table of the chains found
--
--  Most Foldit puzzles contain only a single protein (peptide) chain. 
--  A few puzzles contain ligands, and some puzzles have had two 
--  protein chains. Foldit puzzles may also contain RNA or DNA. 
--
--  For proteins, the atom count can be used to identify the first 
--  (N terminal) and last (C terminal) ends of the chain. The AANames
--  table has the mid-chain atom counts for each amino acid. 
--
--  Cysteine is a special case, since the presence of a disulfide 
--  bridge also changes the atom count.
--
--  For DNA and RNA, the beginning and end of the chain is determined
--  by context at present. For example, if the previous segment was protein
--  and this segment is DNA, it's the start of a chain. 
--
--  Each ligand is treated as a chain of its own, with a length of 1. 
--
--  chain table entries
--  -------------------
--
--  ctype - chain type - "P" for protein, "M" for ligand, "R" for RNA, "D" for DNA
--  fasta - FASTA-format sequence, single-letter codes (does not include FASTA header)
--  fastab - "backup" of fasta
--  start - Foldit segment number of sequence start
--  stop - Foldit segment number of sequence end
--  len - length of sequence
--  chainid - chain id assigned to entry, "A", "B", "C", and so on
--  mute - number of mutable segments
--
--  For DNA and RNA, fasta and fastab contain single-letter codes, so "a" for adenine. 
--  The codes overlap the amino acid codes (for example, "a" for alanine). 
--  The DNA and RNA codes must be converted to the appropriate two-letter codes Foldit 
--  uses internally, for example "ra" for RNA adenine and "da" for DNA adenine.
--

--
--  we're assuming Foldit won't ever have more chains
--  
    local chainid = { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", 
                      "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z" }
    local chainz = {}
    local chindx = 0
    local curchn = nil

    local segCnt = structure.GetCount ()

    for ii = 1, segCnt do

        if protNfo.first [ ii ] then
            chindx = chindx + 1
            chainz [ chindx ] = {}
            curchn = chainz [ chindx ]
            curchn.ctype = protNfo.ctype [ ii ]
            curchn.fasta = ""
            curchn.start = ii 
            curchn.chainid = chainid [ chindx ] 
            curchn.mute = 0
            curchn.len = 0
        end
        
        curchn.fasta = curchn.fasta .. protNfo.fastac [ ii ]
        if protNfo.mute [ ii ] then
            curchn.mute = curchn.mute + 1
        end
        
        if protNfo.last [ ii ] then
            curchn.stop = ii
            curchn.len = curchn.stop - ( curchn.start - 1 )
        end
    end

    for ii = 1, #chainz do
        chainz [ ii ].fastab = chainz [ ii ].fasta
    end
    return chainz
end

function setChain ( chain )
    local changes = 0
    local errz = 0
    local offset = chain.start - 1
  
    local fastan = "" -- possibly changed chain 
    for ii = 1, chain.stop - ( chain.start - 1 ) do
        local sType = chain.fasta:sub ( ii, ii )
        local oType = chain.fastab:sub ( ii, ii )

    --
    --  for DNA and RNA, convert FASTA to Foldit
    --
        if     chain.ctype == protNfo.DNA then
            sType = DNAin [ sType ]
            if sType == nil then
                sType = protNfo.UNKNOWN_BASE
            end
            oType = DNAin [ oType ]
            if oType == nil then
                oType = protNfo.UNKNOWN_BASE
            end
        elseif chain.ctype == protNfo.RNA then
            sType = RNAin [ sType ]
            if sType == nil then
                sType = protNfo.UNKNOWN_BASE
            end
            oType = RNAin [ oType ]
            if oType == nil then
                oType = protNfo.UNKNOWN_BASE
            end
        end

        if sType ~= oType then
            local sName = AANames [ sType ]
            if sName ~= nil then
                if protNfo.mute [ ii + offset ] then
                    structure.SetAminoAcid ( ii + offset, sType )
                    local newaa = structure.GetAminoAcid ( ii + offset )
                    if newaa == sType then
                        changes = changes + 1
                        fastan = fastan .. AANames [ sType ] [ AACODE ]
                    else
                        print ( "segment " 
                                    .. ii + offset .. 
                                " ("
                                    .. chain.chainid .. ":" ..  ii ..
                                ") mutation to type \"" 
                                    .. sType .. "\" failed" )
                        errz = errz + 1
                        fastan = fastan .. AANames [ oType ] [ AACODE ]
                end
            else
                print ( "segment " 
                            .. ii + offset .. 
                        " ("
                            .. chain.chainid .. ":" ..  ii .. 
                            ") is not mutable, skipping change to type \"" 
                                .. sType .. "\"" )
                    errz = errz + 1
                    fastan = fastan .. AANames [ oType ] [ AACODE ]
                end
            else
                print ( "segment " 
                            .. ii + offset .. 
                        " ("
                            .. chain.chainid .. ":" ..  ii .. 
                        "), skipping invalid type \"" 
                            .. sType .. 
                        "\"" )
                errz = errz + 1
                fastan = fastan .. AANames [ oType ] [ AACODE ]
            end
        else
            fastan = fastan .. AANames [ oType ] [ AACODE ]
        end
    end
    chain.fasta = fastan
    chain.fastab = fastan
    return changes, errz
end

function GetParameters ( chnz, peptides, gchn, minseg, maxseg, totlen, totmut )
    local dlog = dialog.CreateDialog ( ReVersion )

    dlog.sc0  = dialog.AddLabel ( "segment count = " .. structure.GetCount () ) 
    local cwd = "chain"
    if #chnz > 1 then 
        cwd = "chains" 
    end
    dlog.chz  = dialog.AddLabel ( #chnz .. " chains" )
    for ii = 1, #chnz do 
        local chain = chnz [ ii ]
        dlog [ "chn" .. ii .. "l1" ] = dialog.AddLabel (
                "Chain "
                    .. chain.chainid ..
                " ("
                    .. Ctypes [ chnz [ ii ].ctype ] ..
                ")" 
        )
        dlog [ "chn" .. ii .. "l2" ] = dialog.AddLabel (
                "segments "
                    .. chain.start ..
                "-"
                    .. chain.stop .. 
                ", mutables = " 
                    .. chain.mute ..
                ", length = " 
                    .. chain.len
        )
        dlog [ "chn" .. ii .. "ps" ] = dialog.AddTextbox ( "seq", chain.fasta )
    end

    dlog.u0 = dialog.AddLabel ( "" )
    if mutable then 
        dlog.u1 = dialog.AddLabel ( "Usage: click in text box, " )
        dlog.u2 = dialog.AddLabel ( "then use select all and copy, cut, or paste" )
        dlog.u3 = dialog.AddLabel ( "to save or change primary structure" )
    else
        dlog.u1 = dialog.AddLabel ( "Usage: click in text box," )
        dlog.u2 = dialog.AddLabel ( "then use select all and copy" )
        dlog.u3 = dialog.AddLabel ( "to save primary structure" )
    end
    dlog.w0 = dialog.AddLabel ( "" )
    if mutable then
        dlog.w1 = dialog.AddLabel ( "Windows: ctrl + a = select all" )
        dlog.w2 = dialog.AddLabel ( "Windows: ctrl + x = cut" )
        dlog.w3 = dialog.AddLabel ( "Windows: ctrl + c = copy" )
        dlog.w4 = dialog.AddLabel ( "Windows: ctrl + v = paste" )
    else
        dlog.w1 = dialog.AddLabel ( "Windows: ctrl + a = select all" )
        dlog.w3 = dialog.AddLabel ( "Windows: ctrl + c = copy" )
    end
    dlog.z0 = dialog.AddLabel ( "" )
   
    if mutable then 
        dlog.ok = dialog.AddButton ( "Change" , 1 )
    end
    dlog.exit = dialog.AddButton ( "Exit" , 0 )

    if ( dialog.Show ( dlog ) > 0 ) then
        for ii = 1, #chnz do 
            chnz [ ii ].fasta = ( dlog [ "chn" .. ii .. "ps" ].value:lower ()):sub ( 1, chnz [ ii ].len ) 
        end
        return true
    else
        return false
    end
end

function main ()
    print ( ReVersion )
    print ( "Puzzle: " .. puzzle.GetName () )
    print ( "Track: " .. ui.GetTrackName () )

    undo.SetUndo ( false )

    protNfo.setNfo ()
    
    for ii = 1, structure.GetCount () do
        if protNfo.mute [ ii ] == true then        
            mutable = true
            break
        end 
    end 

    local   changeNum = 0
    local   chnTbl = {} -- chains as table of tables
    chnTbl = getChains ()
    print ( #chnTbl .. " chains and ligands" )
--
--  print the chains and make some tests
--
    local totlen = 0
    local maxlen = 0
    local chncnt = 0
    local mutchn = 0
    local totmut = 0
    local gchn = ""
    local minseg = 99999
    local maxseg = 0

    for ii = 1, #chnTbl do
        local chain = chnTbl [ ii ]
        if chain.stop == nil then
            chain.stop = 999999
        end
        if chain.ctype ~= "M" then
            print ( "chain " .. chain.chainid .. ", start = " .. chain.start .. ", end = " .. chain.stop .. ", length = " .. chain.len .. ", mutables = " .. chain.mute )
            print ( chain.fasta )
            gchn = gchn .. chain.fasta
            chncnt = chncnt + 1
            if chain.mute > 0 then
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
            print ( "ligand " .. chain.chainid .. ", segment = " .. chain.start )
        end
    end

--
--  assume the worse if average length is under 25 
--
    local peptides = false
    local newchn = {}
    local avglen = totlen / chncnt
    if avglen < 25 and mutchn == 0 then
        peptides = true
        print ( "multiple immutable peptides found" )
        print ( "these are likely fragments of a larger protein" )
        print ( "combined sequence:" )
        print ( gchn )
        newchn = { ctype = "P", fasta = gchn, fastab = gchn, start = minseg, stop = maxseg, len = totlen, chainid = "A", mute = totmut, }
    end
    if peptides then
        local mrgchn = {}
        for ii = 1, #chnTbl do
            -- TODO: rewrite the table
        end

    end

    while GetParameters ( chnTbl, peptides, gchn, minseg, maxseg, totlen, totmut ) do
        for ii = 1, #chnTbl do
            local chain = chnTbl [ ii ]
            if chain.fasta ~= chain.fastab then
                print ( "--" )
                print ( "chain " .. chain.chainid .. " changed" )

                local old = chain.fastab
                changeNum = changeNum + 1
                local start_time = os.time ()

                behavior.SetFiltersDisabled ( true )
                local sChg, sErr = setChain ( chnTbl [ ii ] )
                behavior.SetFiltersDisabled ( false )

                print ( "segments changed = " .. sChg .. ", errors = " .. sErr )
                print ( "old chain " .. chain.chainid .. ": " )
                print ( old )
                print ( "new chain " .. chain.chainid .. ": " ) 
                print ( chain.fastab )
            end
        end
    end
    cleanup ()
end

function cleanup ( errmsg )
--
--  do not loop if cleanup causes an error
--
    if CLEANUPENTRY ~= nil then
        return
    end
    CLEANUPENTRY = true

    print ( "---" )
--
--  model 100 - print recipe name, puzzle, track, time, score, and gain
--
    local reason
    local start, stop, line, msg
    if errmsg == nil then
        reason = "complete"
    else
    --
    --  model 120 - civilized errmsg reporting,
    --              thanks to Bruno K. and Jean-Bob
    --
        start, stop, line, msg = errmsg:find ( ":(%d+):%s()" )
        if msg ~= nil then
            errmsg = errmsg:sub ( msg, #errmsg )
        end
        if errmsg:find ( "Cancelled" ) ~= nil then
            reason = "cancelled"
        else
            reason = "error"
        end
    end

    print (  ReVersion .. " " .. reason )
    print ( "Puzzle: " .. puzzle.GetName () )
    print ( "Track: " .. ui.GetTrackName () )

    if reason == "error" then
        print ( "Unexpected error detected" )
        print ( "Error line: " .. line )
        print ( "Error: \"" .. errmsg .. "\"" )
    end
    behavior.SetFiltersDisabled ( false )
end

xpcall ( main, cleanup )
