
--  Fracture v2.1  -  MurloW   

-- function SortItWell(SsP) mangled and assimilated from drjr: BareBones Rebuilder 1.11  
-- Some (parts of-)functions from Quaker v3.1 500 by Raven_pl 

-- version 2.1.1 (Hunter Lecavalier)

IterationMultiplier = 1.2 -- Multiply wiggle iterations by this value. Most used values of wiggle iterations are 4 (perturb), 8 (lower than maxCI), and 10 (stabilize). Recommended value between 0.8 and 2.5

normal = true -- set false to use .GetEnergyScore()

------------------------------------------------------------------------
print("")

function score()
  local s = 0
  if normal == false then
    s = current.GetEnergyScore()
  else
    s = current.GetScore()
  end
  return s
end

nSegs = structure.GetCount()
cival = behavior.GetClashImportance()
if cival < 0.1 then cival = 1 end
oldbands = 0
oldbands = band.GetCount()
origbands = oldbands
startscore = score()
bestscore = startscore
BndrStartscore = score()
BndrBestscore = BndrStartscore
ItMu = IterationMultiplier
if ItMu<=0 then ItMu=1 end
AllAla=false
InBander=false
luktni=false
beter=true
startseg=1
startD=1
endD=nSegs
endseg=nSegs
if score()<8000 then maxLoss=0.5
else maxLoss=1.5 end
------------------------------------------------------------------------
-- REALLY good seed by Rav3n_pl
function Seed()
seed=os.time()/math.abs(current.GetEnergyScore())
seed=seed%0.001
seed=1/seed
while seed<10000000 do seed=seed*10 end
seed=seed-seed%1
--print("Seed is: "..seed)
math.randomseed(seed)
end
Seed()
------------------------------------------------------------------------
function wig(how,it,iters,minppi)
if DisFil then behavior.SetSlowFiltersDisabled(true) end
if how==nil then how="wa" end
if it==nil then it=10*ItMu else it=it*ItMu end
if minppi==nil then minppi=1 end
if iters==nil then iters=2 end
it=math.ceil(it)
if iters>0 then
iters=iters-1
local sp=score()
if how == "s" then if AllAla == false then structure.ShakeSidechainsAll(1) end
elseif how == "wb" then structure.WiggleAll(it, true, false)
elseif how == "ws" then structure.WiggleAll(it, false, true)
elseif how == "wa" then structure.WiggleAll(it, true, true)
end
if score()-sp > minppi and how ~= "s" then return wig(how, it, iters, minppi) end
end
if DisFil then behavior.SetSlowFiltersDisabled(false) end
end
function PresDia()
--print(" Presets: ")
print(" Early Game: ")
print(" 1 = drw small rebuilds, shortest first - fast healing")
print(" 2 = drw large-med rebuilds")
print(" 3 = rr large-med rebuilds")
print(" Mid Game: ")
print(" 1 = drw med rebuilds")
print(" 2 = rr big-med rebuilds")
print(" 3 = rr med-small rebuilds")
print(" End Game: ")
print(" 1 = drw small rebuilds")
print(" 2 = rr small rebuilds")
print(" 3 = drw acid tweak")
print(" 4 = rr acid tweak")
print("")
-- define puzzle
for i=1, nSegs-1 do
if structure.IsMutable(i) then MM = true break end end
for d=1, nSegs-1 do
if current.GetSegmentEnergySubscore(d, 'density') ~= -0 then EDpuzzle = true break end end
if band.GetCount()>0 then
for e=1, band.GetCount() do
if band.IsEnabled(e) then
oldbands = band.GetCount()
Bands = true
end
end
end
local plc = 0
for y=1, nSegs, 4 do
if (get_ss(y) == 'E') then plc=plc+1 end
if plc>=2 then plank=true break end
end
for y = 1, nSegs-2 do
for j = y+2, nSegs do
if contactmap.GetHeat(y, j) ~= 0 then ConP=true
break
end
end
if ConP then break end
end
-- /def puz
opt = dialog.CreateDialog("Fracture. ")
opt.Yosh=dialog.AddCheckbox("Custom. Like a Boss.",false)
opt.ll=dialog.AddLabel(" Presets : ")
opt.MC=dialog.AddSlider("Maximum CI:", cival, 0.1, 1, 2)
opt.sl=dialog.AddCheckbox(" ~~ Early Game - Fast & Loose ",false)
opt.sg=dialog.AddSlider("",1,1,3,0)
opt.ml=dialog.AddCheckbox(" ~~ Mid Game - Deep Rebuild & Refine ",false)
opt.mg=dialog.AddSlider("",1,1,3,0)
opt.el=dialog.AddCheckbox(" ~~ End Game - Idealize & Polish ",false)
opt.eg=dialog.AddSlider("",1,1,4,0)
opt.lal=dialog.AddLabel(" Variables: ")
opt.AllLoop=dialog.AddCheckbox("Change to loop before rebuild.", false)
opt.IwantB=dialog.AddCheckbox(" I'll have Banders with that.  ",false)
-- puzzle specific
if MM == true then
opt.mutaL=dialog.AddCheckbox("Mutate locally;", true)
opt.muta=dialog.AddCheckbox("and in fuze.", false)
end
if Bands then
opt.KB=dialog.AddCheckbox("Keep bands, disable during rebuild", true)
opt.KBE=dialog.AddCheckbox("Keep bands enabled", false)
opt.KBSTR=dialog.AddCheckbox("Keep original strength and goal length", true)
end
if EDpuzzle == true then
opt.d=dialog.AddCheckbox("Target density subscore", false)
end
-- /puz spec
opt.dis=dialog.AddCheckbox("Disable slow filters during wiggle.", true)
opt.ok=dialog.AddButton("Go go!", 1)
dialog.Show(opt)
AllLoop = opt.AllLoop.value
custom = opt.Yosh.value
if custom==true then return OptionsDialog() end
if EDpuzzle == true then
if opt.d.value  == true then SubscorePart="density" end
end
Strtgame=opt.sl.value
sgsl=opt.sg.value
Midgame=opt.ml.value
mgsl=opt.mg.value
Endgame=opt.el.value
egsl=opt.eg.value
cival = opt.MC.value
DisFil=opt.dis.value
if MM == true then
muta=opt.muta.value
mutaL=opt.mutaL.value
else
muta = false
mutaL = false
end
if Bands then
KB=opt.KB.value
KBE=opt.KBE.value
KBSTR=opt.KBSTR.value
end
-- failsafe
if (Strtgame == true) and ((Midgame == true) or (Endgame == true)) then
return PresDia()
elseif (Midgame == true) and ((Endgame == true) or (Strtgame == true)) then
return PresDia()
end
if (Strtgame == false) and (Midgame == false) and (Endgame == false) and (opt.Yosh.value == false) then
return PresDia()
end
-- /fs
if opt.IwantB.value == true then PresBands() end
return custom, cival, Strtgame, sgsl, Midgame, mgsl, Endgame, egsl, DisFil
end
function PresBands()
comdecom = true
opt=dialog.CreateDialog("Banders")
opt.wosl=dialog.AddLabel(" Slider value = Bander intensity ")
opt.w1sl=dialog.AddLabel(" 1 is weak, fuzing; 3 is strong, altering. ")
opt.w2sl=dialog.AddLabel(" Previous choice of preset factors in as well. ")
opt.wos=dialog.AddSlider("",1,1,3,0)
opt.prebis=dialog.AddCheckbox(" Spacebands. ",false)
if ConP then opt.conp=dialog.AddCheckbox("Use local contact map bands after every rebuild.", true) end
opt.rbldcomp=dialog.AddCheckbox("Bander after every rebuild. ", false)
opt.cyclecomp=dialog.AddCheckbox("Bander after every cycle. ", true)
opt.bFi=dialog.AddCheckbox("Start with a cycle of bander. ", false)
opt.ok=dialog.AddButton("Go go!", 1)
dialog.Show(opt)
cyclecomp=opt.cyclecomp.value
rbldcomp=opt.rbldcomp.value
SpBa=opt.prebis.value
bFi=opt.bFi.value
BSl=opt.wos.value
if ConP then if opt.conp.value then ConB=true end end
bandson = false
if Strtgame == true then
SinSq = false
------- end local
runs = 10
comdecom = true
both = false
bloat = false
------- end basic
if BSl == 1 then
--weak
shap = true
tryboth = true
raci = true
minB = 8
maxLoss = 0.6
minBS = 0.1
maxBS = 0.7
fuzt = 1.5
pullci = 0.9
elseif BSl == 2 then
--med
shap = true
tryboth = true
raci = true
minB = 8
maxLoss = 1
minBS = 0.1
maxBS = 1.5
fuzt = 1.5
pullci = 0.9
elseif BSl == 3 then
--strong
shap = true
tryboth = true
raci = true
minB = 8
maxLoss = 1.5
minBS = 0.4
maxBS = 3
fuzt = 1.5
pullci = 0.9
end
elseif Midgame == true then
SinSq = true
Qradius = 7
LoBaCD = false
LBstr = 0.4
------- end local
runs = 20
comdecom = true
both = false
bloat = false
------- end basic
if BSl == 1 then
--weak
shap = true
tryboth = true
raci = true
minB = 2
maxLoss = 0.6
minBS = 0.1
maxBS = 0.7
fuzt = 1.5
pullci = 0.9
elseif BSl == 2 then
--med
shap = true
tryboth = true
raci = true
minB = 8
maxLoss = 1
minBS = 0.1
maxBS = 1.5
fuzt = 1.5
pullci = 0.9
elseif BSl == 3 then
--strong
shap = true
tryboth = true
raci = true
minB = 8
maxLoss = 1.5
minBS = 0.4
maxBS = 3
fuzt = 1.5
pullci = 0.9
end
elseif Endgame == true then
SinSq = true
Qradius = 7
LoBaCD = true
LBstr = 0.6
------- end local
runs = 40
comdecom = true
both = true
bloat = false
------- end basic
if BSl == 1 then
--weak
shap = true
tryboth = true
raci = true
minB = 1
maxLoss = 1
minBS = 0.1
maxBS = 1.3
fuzt = 1.5
pullci = 0.9
elseif BSl == 2 then
--med
shap = true
tryboth = true
raci = true
minB = 4
maxLoss = 1
minBS = 0.1
maxBS = 2
fuzt = 1.5
pullci = 0.9
elseif BSl == 3 then
--strong
shap = true
tryboth = true
raci = true
minB = 1
maxLoss = 1.7
minBS = 0.4
maxBS = 3
fuzt = 1.5
pullci = 0.9
end
end
if ConB then SinSq=true end
return cyclecomp, rbldcomp, bandson, SinSq, Qradius, LoBaCD, LBstr, runs, comdecom, both, bloat, shap, tryboth, raci, minB, maxLoss, minBS, maxBS, fuzt, pullci, comdecom, SpBa, bFi, ConB, ConP
end
function OptionsDialog()
opt = dialog.CreateDialog("Fracture. Executive Edition.")
opt.RR=dialog.AddCheckbox("Rainbow Rebuild instead of drw.", false)
opt.Bndr=dialog.AddCheckbox("Bander.", true)
opt.MC=dialog.AddSlider("Maximum CI:", cival, 0.1, 1, 2)
opt.rblbl=dialog.AddLabel("Rebuild Length:")
opt.maxrblng=dialog.AddSlider("Max.:", 5, 1, maxrblng, 0)
opt.minrblng=dialog.AddSlider("Min.:",2,1,maxrblng,0)
opt.wf=dialog.AddCheckbox("Longest first.",true)
opt.fuze=dialog.AddSlider("Fuze threshold:", -50, -200, 100, 1)
opt.Sf=dialog.AddCheckbox("Short fuze", true)
opt.qSt=dialog.AddCheckbox("qStab", false)
opt.Idt=dialog.AddCheckbox("Idealize (beware of large rebuild lengths)",true)
if MM == true then
opt.mutaL=dialog.AddCheckbox("Mutate locally;", true)
opt.muta=dialog.AddCheckbox("and in fuze.", false)
end
if Bands then
opt.KB=dialog.AddCheckbox("Keep bands, disable during rebuild", true)
opt.KBE=dialog.AddCheckbox("Keep bands enabled", false)
opt.KBSTR=dialog.AddCheckbox("Keep original strength and goal length", true)
end
opt.dis=dialog.AddCheckbox("Disable slow filters during wiggle.", true)
opt.aa=dialog.AddLabel("")
opt.AllLoop=dialog.AddCheckbox("Change to loop before rebuild.", false)
opt.AO=dialog.AddCheckbox(" More options.", false)
opt.ok=dialog.AddButton("Go go!", 1)
dialog.Show(opt)
if MM == true then
muta=opt.muta.value
mutaL=opt.mutaL.value
else
muta = false
mutaL = false
end
if Bands then
KB=opt.KB.value
KBE=opt.KBE.value
KBSTR=opt.KBSTR.value
end
RR=opt.RR.value
Sf=opt.Sf.value
fzt=opt.fuze.value
cival=opt.MC.value
qSt=opt.qSt.value
DisFil=opt.dis.value
AllLoop=opt.AllLoop.value
maxrb=opt.maxrblng.value
minrb=opt.minrblng.value
lFirst=opt.wf.value
if minrb>maxrb then
mnnrb=minrb
mxxrb=maxrb
minrb=mxxrb
maxrb=mnnrb
end
if lFirst == true then
rbLng=maxrb
elseif lFirst == false then
rbLng=minrb
end
Bndrss=opt.Bndr.value
IdealT=opt.Idt.value
if (opt.AO.value == true) then MoreOptions()
elseif (opt.AO.value == false) and (minrb ~= maxrb) then
if lFirst == true then
rbCh = -1
elseif lFirst == false then
rbCh = 1
end
end
if Bndrss == true then BndrssDialog() end
if (band.GetCount()>0) and (KB == false) and (KBE == false) then
band.DeleteAll()
end
if fzt<=0 then
FFzt = (-1*fzt)
else
end
if RR == true then
RRdialog()
else
DRWdialog()
end
return qSt,rbLng,AllLoop,Sf,fzt,FFzt,cival,Bndrss,IdealT,lFirst,minrb,maxrb,DisFil
end
function MoreOptions()
opt = dialog.CreateDialog("Moarr.")
if minrb~=maxrb then
opt.rbc=dialog.AddLabel("Change Rebuild Length by x after y cycles.")
if lFirst == true then
opt.rbCh=dialog.AddSlider("         x", -1, -1*(maxrb-minrb), 0, 0)
elseif lFirst == false then
opt.rbCh=dialog.AddSlider("         x", 1, 0, (maxrb-rbLng), 0)
end
opt.rbCy=dialog.AddSlider("         y", 2, 1, 50, 0)
end
opt.mxl=dialog.AddLabel("Change maxCI by x after y cycles with less than z gain")
opt.ciDo=dialog.AddCheckbox(" uncheck to NOT do this.", false)
opt.ciCh=dialog.AddSlider("         x", 0.1, 0.05, 0.95, 2)
opt.ciCy=dialog.AddSlider("         y", 5, 1, 50, 0)
opt.cyGa=dialog.AddSlider("         z", 0, 0, 500, 0)
opt.aab=dialog.AddLabel("")
opt.rbci = dialog.AddSlider("Rebuild CI value:", 0.1, 0, 1, 2)
opt.sphere=dialog.AddSlider("Shake Sphere:", 7, 4, 50, 0)
opt.notsh=dialog.AddCheckbox("Don't rebuild sheets", false)
opt.nothe=dialog.AddCheckbox("Don't rebuild helices", false)
opt.notlo=dialog.AddCheckbox("Don't rebuild loops", false)
opt.ok=dialog.AddButton("Go go!", 1)
dialog.Show(opt)
ShakeSphere=opt.sphere.value
ciCh=opt.ciCh.value
ciCy=opt.ciCy.value
cyGa=opt.cyGa.value
ciDo=opt.ciDo.value
if minrb~=maxrb then
rbCh=opt.rbCh.value
rbCy=opt.rbCy.value
end
rbci=opt.rbci.value
nothelices=opt.nothe.value
notsheets=opt.notsh.value
notloops=opt.notlo.value
return ciCh,ciCy,cyGa,ciDo,notloops,notsheets,nothelices,rbci,rbCh,rbCy,ShakeSphere
end
function OptionsTest()
if ciDo == nil then ciDo = false end
if ciCh == nil then ciCh = 0 end
if ciCy == nil then ciCy = 50000000 end
if cyGa == nil then cyGa = 50000000 end
if notloops == nil then notloops = false end
if notsheets == nil then notsheets = false end
if nothelices == nil then nothelices = false end
if ShakeSphere == nil then ShakeSphere = 8 end
if rbci == nil then rbci = 0.1 end
if rbCy == nil then rbCy = 1 end
if endseg == nil then endseg = nSegs end
if startseg == nil then startseg = 1 end
if startD == nil then startD = 1 end
if endD == nil then endD = nSegs end
if rbCh == nil then
if minrb~=maxrb then
if lFirst == true then rbCh = (-1)
else rbCh = 1 end
end
end
end
function DRWdialog()
opt=dialog.CreateDialog("DRW Options.")
opt.a=dialog.AddLabel("Choose one scorepart:")
opt.b=dialog.AddCheckbox("backbone", true)
opt.to=dialog.AddCheckbox("total", false)
opt.c=dialog.AddCheckbox("other", false)
opt.wf=dialog.AddCheckbox("Worst scoring first  (uncheck is best scoring)", true)
opt.tb=dialog.AddCheckbox("Chosen scorepart MUST improve to accept gains.", false)
opt.lt=dialog.AddCheckbox("Less testing if scorepart too low.", false)
opt.ltl=dialog.AddLabel("    ^('every rebuild' banders and fuze will be skipped)")
--opt.resort=dialog.AddCheckbox("Re-sort after every rebuild", false)
opt.gsort=dialog.AddCheckbox("Gary sort: after x succesful rebuilds", false)
opt.perscnt=dialog.AddCheckbox("Persistant counter", false)
opt.cntG=dialog.AddSlider(" x for Gary sort:", (maxRPC/4), 1, maxRPC, 0)
opt.numruns=dialog.AddSlider("Nr. of cycles:", 1000, 1, 1000, 0)
opt.nbr=dialog.AddSlider("Rebuilds per cycle:", (maxRPC/2)+2, 1, maxRPC, 0)
opt.lal=dialog.AddLabel("Start and End Segment for DRW")
opt.startD=dialog.AddSlider("Start Seg:",startD,1,endD,0)
opt.endD=dialog.AddSlider("End Seg:",endD,2,endD,0)
opt.norl=dialog.AddLabel("Nr. of rebuilds per segment:")
opt.nor=dialog.AddSlider("", 10, 1, 60, 0)
opt.wigsc=dialog.AddCheckbox("Wiggle Sidechains every rebuild iteration.", false)
opt.Lwigaf=dialog.AddCheckbox("Local wiggle every rebuild iteration.", false)
opt.wigAf=dialog.AddCheckbox("Global wiggle every rebuild iteration.", false)
if (comdecom == true) or (SpBa == true) then
opt.rbldcomp=dialog.AddCheckbox("Bander after every rebuild. (qkrbld style)", false)
opt.cyclecomp=dialog.AddCheckbox("Bander after every cycle. (tvdl comp style)", true)
end
if MM then opt.bm=dialog.AddCheckbox("Bruteforce mutate after every cycle.",false) end
opt.ok=dialog.AddButton("Go go!", 1)
dialog.Show(opt)
--ReSort=opt.resort.value
cntGary=opt.cntG.value
gsort=opt.gsort.value
PersCnt=opt.perscnt.value
if MM then bfm=opt.bm.value end
testBeter=opt.tb.value
LessTests=opt.lt.value
WorstFirst=opt.wf.value
endD=opt.endD.value
startD=opt.startD.value
RbldsPrCycle=opt.nbr.value
NumberOfRebuilds=opt.nor.value
LocW=opt.Lwigaf.value
GlWi=opt.wigAf.value
WigSC=opt.wigsc.value
numruns=opt.numruns.value
if (comdecom == true) or (SpBa == true) then
cyclecomp=opt.cyclecomp.value
rbldcomp=opt.rbldcomp.value
end
if (startD>endD) then
startD = 1
endD = nSegs
end
if rbLng>(endD-startD) then rbLng=(endD-startD)+1 end
if opt.to.value  == true then SubscorePart="total" end
if opt.b.value == true then SubscorePart="backbone" end
if (opt.c.value  == true) or (SubscorePart == nil) then Moarr = true end
if (Moarr == true) then MoreDialog() end
return testBeter,SubscorePart,GlWi,LocW,WigSC,startD,endD,numruns,RbldsPrCycle,NumberOfRebuilds,WorstFirst,cyclecomp,rbldcomp,garyCnt,cntGary,gsort--,ReSort
end
function RRdialog()
ask=dialog.CreateDialog("Rainbow Rebuilder Options")
ask.numruns2=dialog.AddSlider(" Nr. of cycles:", 500, 1, 1000, 0)
ask.ll=dialog.AddLabel("Start and End Segment for RR")
ask.startseg=dialog.AddSlider("Start Seg:",startseg,1,endseg,0)
ask.endseg=dialog.AddSlider("End Seg:",endseg,0,endseg,0)
ask.rbit=dialog.AddSlider("Rebuild iterations:",2,1,27,0)
ask.wigsc=dialog.AddCheckbox("Wiggle Sidechains.", false)
ask.Lwigaf=dialog.AddCheckbox("Local wiggle.", false)
if (comdecom == true) or (SpBa == true) then
ask.rbldcomp=dialog.AddCheckbox("Bander after every rebuild. (qkrbld style)", false)
ask.cyclecomp=dialog.AddCheckbox("Bander after every cycle. (tvdl comp style)", true)
end
if MM then ask.bm=dialog.AddCheckbox("Bruteforce mutate after every cycle.",false) end
ask.ok = dialog.AddButton("Go go!",1)
dialog.Show(ask)
if MM then bfm=ask.bm.value end
if (comdecom == true) or (SpBa == true) then
cyclecomp=ask.cyclecomp.value
rbldcomp=ask.rbldcomp.value
end
startseg=ask.startseg.value
endseg=ask.endseg.value
rbIt=ask.rbit.value
numruns2=ask.numruns2.value
if (startseg>endseg) then
startseg = 1
endseg = nSegs
end
if rbLng>(endseg-startseg) then rbLng=(endseg-startseg)+1 end
return startseg,endseg,rbIt,numruns2,cyclecomp,rbldcomp
end
function MoreDialog()
if Moarr == true then
opt=dialog.CreateDialog("Choose one subscore")
opt.aa=dialog.AddLabel("")
opt.cl=dialog.AddCheckbox("clashing", false)
opt.p=dialog.AddCheckbox("packing", false)
opt.h=dialog.AddCheckbox("hiding", false)
opt.s=dialog.AddCheckbox("sidechain", false)
opt.bo=dialog.AddCheckbox("bonding", false)
opt.ide=dialog.AddCheckbox("ideality",false)
if EDpuzzle == true then
opt.d=dialog.AddCheckbox("density", false)
end
opt.ok=dialog.AddButton("Go go!", 1)
dialog.Show(opt)
if opt.ide.value == true then SubscorePart="ideality" end
if opt.bo.value  == true then SubscorePart="bonding" end
if opt.s.value  == true then SubscorePart="sidechain" end
if opt.cl.value  == true then SubscorePart="clashing" end
if opt.p.value == true then SubscorePart="packing" end
if opt.h.value  == true then SubscorePart="hiding" end
if EDpuzzle == true then
if opt.d.value  == true then SubscorePart="density" end
end
end
if SubscorePart == nil then return DRWdialog() end
end
function BndrssDialog()
ask = dialog.CreateDialog("Bander Options.")
ask.SinSq=dialog.AddCheckbox("Single squeeze/push local bands after rebuild.", false)
ask.comdecom=dialog.AddCheckbox("Compress / Decompress.", true)
ask.spb=dialog.AddCheckbox("Space bands.",true)
if plank == true then
ask.Sti=dialog.AddCheckbox("Sheet Stitcher every rebuild.",false)
end
ask.ok = dialog.AddButton("Go go!",1)
dialog.Show(ask)
if plank == true then
Stitch=ask.Sti.value
end
SinSq=ask.SinSq.value
comdecom=ask.comdecom.value
SpBa=ask.spb.value
if Stitch == nil then Stitch = false
elseif Stitch then SSdia()
end
if SinSq then LoBaDialog() end
if (comdecom == true) or (SpBa == true) then BanderDialog() end
return SinSq, comdecom, SpBa
end
function SSdia()
ask = dialog.CreateDialog("Sheet Stitcher")
ask.BStr = dialog.AddSlider("Band Strength:", 0.7, 0.1, 1, 2)
ask.dis = dialog.AddSlider("Distance:", 7, 5, 15, 0)
ask.frz = dialog.AddCheckbox("Freeze sheet backbone.",true)
ask.SSf = dialog.AddCheckbox("Fuze with bands",false)
ask.ok = dialog.AddButton("Go go!",1)
dialog.Show(ask)
SSf = ask.SSf.value
BStr = ask.BStr.value
distance = ask.dis.value
frz = ask.frz.value
end
function LoBaDialog()
ask = dialog.CreateDialog("Local Bands Options.")
ask.band=dialog.AddCheckbox("Contract. Uncheck for Expand.", true)
if ConP then ask.conp=dialog.AddCheckbox("Use only contact map bands.", true) end
ask.blurp=dialog.AddLabel("Max. distance radius size:")
ask.Qradius=dialog.AddSlider("", 10, 6, 20, 0)
ask.bstr=dialog.AddSlider("Band strength:", 0.4, 0.2, 2, 1)
ask.ok = dialog.AddButton("Go go!",1)
dialog.Show(ask)
Qradius=ask.Qradius.value
if ConP then ConB=true end
LoBaCD=ask.band.value
LBstr=ask.bstr.value
return Qradius, LoBaCD, LBstr, ConB
end
function BanderDialog()
ask = dialog.CreateDialog("Bander Options.")
if comdecom == true then
ask.bloat = dialog.AddCheckbox("Decompress. Unchecked = compress.", false)
if cival>=0.8 then
ask.both = dialog.AddCheckbox("Alternate both.  (overrides) ", true)
else
ask.both = dialog.AddCheckbox("Alternate both.  (overrides) ", false)
end end
ask.bFi=dialog.AddCheckbox("Start with a cycle of bander. ", false)
ask.bll=dialog.AddLabel("")
ask.runs = dialog.AddSlider("Number of runs:", 12, 1, 200, 0)
ask.MBndr = dialog.AddCheckbox("Moarr options.", false)
ask.dr2 = dialog.AddLabel(" ")
ask.noGa=dialog.AddLabel("Runs without gain before restore best")
ask.noGains=dialog.AddSlider("",3,1,100,0)
ask.Sf = dialog.AddCheckbox("Short fuze.", true)
ask.bandson = dialog.AddCheckbox("Fuze with bands on.", false)
ask.ok = dialog.AddButton("Go go!",1)
dialog.Show(ask)
MBndr = ask.MBndr.value
noGains=ask.noGains.value
if comdecom == true then
both = ask.both.value
Bloat = ask.bloat.value
end
bandson = ask.bandson.value
Sf = ask.Sf.value
bFi=ask.bFi.value
runs = ask.runs.value
if MBndr == true then MoarBndr() end
return muta1, mut2, mut3, bandson, Sf, both, Bloat, qval, shap, Shap, fuzt, qci, minB, pullci, maxLoss, minBS, maxBS, runs, tryboth, FF, noGains, bFi
end
function MoarBndr()
ask = dialog.CreateDialog("Moar Bander Options.")
ask.pullci = dialog.AddSlider("Banding CI:", 0.9, 0.1, 1, 1)
ask.loss = dialog.AddLabel("Minimum % loss when perturbing")
ask.maxloss = dialog.AddSlider("Min.:", maxLoss, 0.2, 10, 1)
ask.minB = dialog.AddSlider("Min. # of bands:", 1, 1, 20, 0)
ask.mia = dialog.AddLabel("Minimum/maximum band strength")
ask.minbs = dialog.AddSlider("Min.:", 0.5, 0.1, 0.7, 1)
ask.maxbs = dialog.AddSlider("Max.:", 2, 0.3, 4, 1)
ask.ShaMutPull = dialog.AddLabel("Shake/mutate after bands?")
ask.shap = dialog.AddCheckbox("Yes.", false)
ask.Shap = dialog.AddCheckbox("No; perturb, then wiggle only.", false)
ask.trb = dialog.AddCheckbox("Try both.", true)
ask.qlab = dialog.AddLabel("Shake CI after bands ")
ask.qci = dialog.AddSlider("CI:", (0.2*cival), 0.01, 1, 2)
ask.raci = dialog.AddCheckbox(" Use random CI.  (overrides)", true)
ask.qla = dialog.AddLabel("qStab if score drops more than %: (otherwise wiggle only)")
ask.qval = dialog.AddSlider("",5,1,20,0)
ask.fu = dialog.AddLabel("Fuzing threshold (negative value is only on gain)")
ask.fuz = dialog.AddSlider("", -50, -50, 100, 1)
if MM == true then
ask.mut = dialog.AddCheckbox("Mutate after bands.", false)
ask.mut2 = dialog.AddCheckbox("Mutate during qstab.", false)
ask.mut3 = dialog.AddCheckbox("Mutate during fuze.", false)
end
ask.ok = dialog.AddButton("Go go!",1)
dialog.Show(ask)
raci = ask.raci.value
qval = ask.qval.value
shap = ask.shap.value
Shap = ask.Shap.value
fuzt = ask.fuz.value
qci = ask.qci.value
minB = ask.minB.value
pullci = ask.pullci.value
maxLoss = ask.maxloss.value
minBS = ask.minbs.value
maxBS = ask.maxbs.value
tryboth = ask.trb.value
if MM == true then
muta1 = ask.mut.value
mut2 = ask.mut2.value
mut3 = ask.mut3.value
end
end
function CheckBander()
if comdecom == false then
both = false
Bloat = false
end
if qval == nil then qval = 5 end
if (Shap == nil) and (shap == nil) and (tryboth == nil)  then
Shap = true
end
if fuzt == nil then fuzt = (-1*50) end
if qci == nil then qci = (0.4*cival) end
if minB == nil then minB = 1 end
if pullci == nil then pullci = 0.9 end
if maxLoss == nil then maxLoss = 1 end
if minBS == nil then minBS = 0.2 end
if maxBS == nil then maxBS = 4 end
if noGains == nil then noGains = 1 end
if muta1 == nil then muta1 = false end
if mut2 == nil then mut2 = false end
if mut3 == nil then mut3 = false end
if raci == nil then raci = true end
if fuzt<=0 then
FF = (-1*fuzt)
end
if (Shap == false) and (shap == false) and (tryboth == false)  then
Shap = true
shap = false
Hhrr = true
elseif (Shap == true) and (shap == true) and (tryboth == false) then
shap = true
Shap = false
Uhr = true
elseif (Shap == true) and (shap == true) and (tryboth == true) then
dehr = true
elseif (Shap == true) and (shap == false) and (tryboth == true) then
yuhr = true
end
if (Hhrr or Uhr or dehr or yuhr) == true then
print("  Fixed that for you:")
end
if yuhr == true then
print(" Heh.. Trying both.")
end
if dehr == true then
print("   All three checked; trying both.")
end
if Hhrr == true then
print("   Nothing checked, pull, then wiggle only.")
end
if Uhr == true then
print("   Both checked, shake/mutate after pull. ")
end
if tryboth == true then shap = true end
end
function setCI(ci)
return behavior.SetClashImportance(ci)
end
function Fuzit()
CheckAla()
setCI(.05)
wig("s")  CheckBest()
setCI(cival)
wig("wa",9) CheckBest()
setCI(cival/3)
wig("wa",3)  CheckBest()
if Sf == false then
setCI(.07)
wig("s")  CheckBest()
setCI(cival)
wig("wa",9) CheckBest()
setCI(cival/3)
wig("wa",3)  CheckBest()
end
setCI(cival)
wig("wa",9)  CheckBest()
wig("s")  CheckBest()
wig("wa",9)
recentbest.Restore()
CheckBest()
end
function Fuze1mut()
CheckAla()
setCI(0.15)
selectMutas()
structure.MutateSidechainsSelected(1) CheckBest()
selection.DeselectAll()
setCI(cival)
wig("wa",9) CheckBest()
setCI(cival/3)
wig("wa",3)  CheckBest()
setCI(cival)
wig("wa",9) CheckBest()
if Sf == false then
CheckAla()
setCI(0.2)
wig("s")  CheckBest()
setCI(cival)
wig()  CheckBest()
setCI(cival/2)
wig()  CheckBest()
setCI(0.87*cival)
selectMutas()
structure.MutateSidechainsSelected(1)  CheckBest()
selection.DeselectAll()
end
setCI(cival)
wig("wa",9)
recentbest.Restore()
CheckBest()
end
function Fuzing()
if InBander == true then
print("  fuzing..")
if mut3 == true then
Fuze1mut()
else
Fuzit()
end
else
if muta then
Fuze1mut()
else
Fuzit()
end
end
wig("wa",6)  CheckBest()
end
function qStab()
CheckAla()
if InBander == true then
setCI(cival/2)
wig("wa",5)  CheckBest()
setCI(cival)
wig("wa",9)   CheckBest()
if mut2 == true then
selectMutas()
structure.MutateSidechainsSelected(1)  CheckBest()
selection.DeselectAll()
wig("s")  CheckBest()
else
wig("s")  CheckBest()
end
setCI(cival/2)
wig("wa",5)  CheckBest()
setCI(cival)
wig("wa",9)  CheckBest()
else
setCI(cival/3)
wig("wa",3)  CheckBest()
setCI(cival)
wig("s")  CheckBest()
wig("wa",9)  CheckBest()
end
recentbest.Restore()
CheckBest()
end
function allWalk()
lscore=score()
print(" Bruteforce ..")
for j=1, #AAs do
for i=1, nSegs do
origA = structure.GetAminoAcid(i)
if structure.CanMutate(i, AAs[j]) then
structure.SetAminoAcid(i, AAs[j])
CheckBest()
save.Quickload(99)
newA = structure.GetAminoAcid(i)
if newA ~= origA then
print("Residue "..i.." changed from "..origA.." to "..newA)
end
end end
end -- aa
if score()>lscore then
print(" Gained:", cut(score()-lscore))
else
print(" No change.")
end
end
function checkLengths(SecStr, length)
local b=0
for e=1,nSegs do
if get_ss(e) ~= SecStr then b=b+1 else b=0 end
--print("",b,e,"b , e", broken)
if b >= length then
broken = false
break end
end
end
function checkLockLengths(length)
local v=0
broken = true
for e=1,nSegs do
if isMovable(e,e) == true then v=v+1 else v=0 end
--print(v,e)
if v >= length then
broken = false
break end
end
end
function selectMutas()
for i=1,nSegs do
if structure.IsMutable(i)  == true then selection.Select(i) end
end
end
function CheckAla()
AllAla=false
local ala=0
for i=1, structure.GetCount() do
local Taa=structure.GetAminoAcid(i)
if (Taa=='a') or (Taa=='g') then
ala=ala+1
else
AllAla=false
break
end end
if ala>=nSegs then AllAla=true end
return AllAla
end
function checkLock()
lockd=0 -- locked seg quantity counter
locklist = {}
for k=1,nSegs do  -- k = seg identity counter
if isMovable(k,k) == false then
lockd=lockd+1
locklist[lockd] = k
end end
return locklist
end
function contains(x, value)
for _, v in pairs(x) do
if v == value then
return true
end
end
return false
end
function SortItWell(SubscorePart)     -- drjr
grid = {}
for i = 1, nSegs do
grid[i] = {}
if SubscorePart ~= 'total' then
grid[i][1] = current.GetSegmentEnergySubscore(i, SubscorePart)
else
grid[i][1] = current.GetSegmentEnergyScore(i)
end
grid[i][2]=i
end
switch = 1
while switch ~= 0 do
switch=0
if WorstFirst == true then
for i=1, nSegs-1 do
if grid[i][1] > grid[i+1][1] then
grid[i][1],grid[i+1][1]=grid[i+1][1],grid[i][1]
grid[i][2],grid[i+1][2]=grid[i+1][2],grid[i][2]
switch = switch +1
end
end
else
for i=1, nSegs-1 do
if grid[i][1] < grid[i+1][1] then
grid[i][1],grid[i+1][1]=grid[i+1][1],grid[i][1]
grid[i][2],grid[i+1][2]=grid[i+1][2],grid[i][2]
switch = switch +1
end
end
end
end
return grid
end
function isMovable(seg1, seg2)
local FT = true
for i=seg1, seg2 do
BB, SC = freeze.IsFrozen(i)
if (BB == true) then
FT = false
end
sl = structure.IsLocked(i)
if ( sl == true ) then
FT = false
end
end
return FT
end
function Delbands()
if KB == true then
freshbands = band.GetCount()
for h = origbands, freshbands-1 do
band.Delete(origbands+1)
end
else
band.DeleteAll()
end
end
function Disbands(oldbands)
if KBE == true then
newbands = band.GetCount()
for i = oldbands, newbands-1 do
band.Disable(i+1)
end
else
band.DisableAll()
end
end
function cut(x)
return x-x%0.001
end
function CheckBest()
if testBeter == true then
if SubscorePart ~= 'total' then
PT = current.GetSegmentEnergySubscore(rbldseg,SubscorePart)
else
PT = current.GetSegmentEnergyScore(rbldseg)
end
if PT>=TempSegSc-0.03 then
beter=true
else
beter=false
end
else beter = true end
if InBander == true then
if (BndrBestscore < score()) then
bgain = score() - BndrBestscore
bgain = bgain-bgain%0.001
BndrBestscore = score()
save.Quicksave(8)
else
bgain = 0
end
elseif InBander == false then
if beter == true then
if (bestscore < score()) then
gain = score() - bestscore
gain = gain-gain%0.001
bestscore = score()
save.Quicksave(1)
save.Quicksave(8)
save.Quicksave(99)
else
gain = 0
end
else
gain = 0
end
end
if InBander == true then
if bgain>0.01 then
print(" ",bgain,"pts.")
end
elseif InBander == false then
if gain>0.01 then
print(" ",gain,"pts.")
end
end
if BndrBestscore>bestscore then
bestscore=BndrBestscore
save.Quicksave(99)
save.Quicksave(1)
end
end
function selectsphere(seg, radius)
if seg>nSegs then seg = nSegs end
if seg<1 then seg = 1 end
for i=1, nSegs do
if structure.GetDistance(seg,i) <= radius then
if seg >= 1 and seg <= nSegs then
selection.Select(i)
end
end
end
end
function Result()
print("")
setCI(cival)
if DisFil then behavior.SetSlowFiltersDisabled(false) end
CheckBest()
save.Quickload(99)
save.Quickload(8)
recentbest.Restore() CheckBest()
save.Quickload(1)
Tgain = (bestscore-startscore)
if Tgain<0.008 then
print(" No change..  :/  ")
else
print(" Startscore: "..cut(startscore))
print(" Score: "..cut(score()))
print(" Total gain: "..cut(Tgain).." pts.")
end
save.LoadSecondaryStructure()
Delbands()
end
function End(errmsg)
if done then return end
done=true
if string.find(errmsg,"Cancelled") then
print("  User cancel.")
Result()
print("")
else
Result()
print("")
print(errmsg)
end
return errmsg
end
function BanderResult()
save.Quickload(8)
save.Quickload(99)
recentbest.Restore()
print(" Score:",cut(score()))
Delbands()
end
function QTest()
local loss = (bestscore*qval)/100
if score() < bestscore-loss then qStab()
else
setCI(cival)
wig("wa",6)  CheckBest()
end
end
function spacebands(amnt)
if comdecom == true then
zeBands=(oldbands+(amnt/2))
else
zeBands=(oldbands+(1.8*minB))
end
--print(zeBands)
if minB==1 then zeBands=zeBands+2
else
zeBands=zeBands+1.5
end
while band.GetCount()<zeBands do
segO = math.random(nSegs)
OsegC=1
while structure.IsLocked(segO)==true do
segO=math.random(nSegs)
OsegC=OsegC+1
if OsegC>25 then break end
end
rho = math.random(10)
theta = math.random(3.14159)
phi = math.random(3.14159)
if phi<1 then
phi=phi+1
end
if theta<1 then
theta=theta+1
end
if segO<=nSegs and segO>=1 then
if segO==nSegs then
segX = segO-1
segY = segO-2
elseif segO==1 then
segX = segO+1
segY = segO+2
else
segX = segO-1
segY = segO+1
end
if segX>nSegs then segX=nSegs-1 end
if segY>nSegs then segY=nSegs-1 end
if segY<1 then segY=1 end
if segX<1 then segX=1 end
--[[print(segX,"X")
print(segY,"Y")
print(segO,"O")
print(theta,"theta")
print(phi,"phi")]]
band.Add(segO, segX, segY, rho, theta, phi)
local lb=band.GetCount()
band.SetGoalLength(lb,math.random(band.GetLength(lb)*2))
end
end
end
function create() -- make bands   -- mostly Rav3n_pl
local dd = cut(nSegs/7)
local start=math.random(dd)
local len=cut(math.random((nSegs-dd)/2)+dd)
local step=cut(math.random((nSegs-dd)/2)+dd)
if luktni == false then
for x=start,nSegs, step do
for y=start+len, nSegs, step do
if (y<=nSegs) and ((isMovable(y, y) == true) or (isMovable(x, x) == true)) then band.AddBetweenSegments(x,y) end
end
end
elseif luktni == true then
for x=start,nSegs, step do
for y=nSegs-(nSegs/8), nSegs, 1 do
if (y<=nSegs) and ((isMovable(y, y) == true) or (isMovable(x, x) == true)) then band.AddBetweenSegments(x,y) end
end
end
luktni = false
end
end
function pull(minBS, maxBS) -- find band strength: 'slow bands'  -- mostly Rav3n_pl, I think
local ss=score()
local loss=(ss*maxLoss/100)
local lastBS=minBS
for str=lastBS,maxBS, 0.1 do
if KBSTR == true then
local NNbands = band.GetCount()
for i=oldbands+1, NNbands do
band.SetStrength(i, str)
end
else
for i=1, band.GetCount() do
band.SetStrength(i, str)
end
end
wig("wb",1) CheckBest()
if (ss-score()>=loss) or (score()>bestscore+1) then
if band.GetCount()>(nSegs/10)*2 then
lastBS=str-0.1
if lastBS<minBS then lastBS=minBS end
else
lastBS=minBS
end
break
end
end
end
function bandage()
if Bloat == true then
if KBSTR == true then  -- decompress
local NNbands = band.GetCount()
for i=oldbands+1, NNbands do
band.SetGoalLength(i,band.GetLength(i)+4)
end
else
for i=1, band.GetCount() do
band.SetGoalLength(i,band.GetLength(i)+4)
end
end
else
if KBSTR == true then  -- compress
local NNbands = band.GetCount()
for i=oldbands+1, NNbands do
local leng=band.GetLength(i)
local perc=math.random(20,50)
local loss=((perc*leng)/100)
band.SetGoalLength(i,band.GetLength(i)-loss)
end
else
for i=1, band.GetCount() do
local leng=band.GetLength(i)
local perc=math.random(20,50)
local loss=((perc*leng)/100)
band.SetGoalLength(i,band.GetLength(i)-loss)
end
end
end
end
function get_ss(sn)
return structure.GetSecondaryStructure(sn)
end
function StitchEm() -- M. Suchard
print(" Stitcher ..")
save.Quicksave(97)
local Ssv=score()
for i =2,nSegs do
for y =i+1,nSegs do
if (structure.GetDistance(i, y)<=distance and get_ss(i)=='E' and get_ss(y)=='E' )then
band.AddBetweenSegments(i,y)
end
end
end
newbandsS=band.GetCount()
for i=oldbands+1, newbandsS do
band.SetStrength(i,BStr)
end
------------------------------------
if KBSTR == true then
local NNbands = band.GetCount()
for i=oldbands+1, NNbands do
band.SetGoalLength(i,band.GetLength(i))
end
else
for i=1, band.GetCount() do
band.SetGoalLength(i,band.GetLength(i))
end
end
if frz == true then
for i=1, nSegs do
if get_ss(i) == 'E' then selection.Select(i) end
end
freeze.FreezeSelected(true, false)
selection.DeselectAll()
end
if RR == true then
for tt = xseg, xseg+rbLng-1 do
freeze.Unfreeze(tt, true, true)
end
else
for tt = rbldStrt, rbldEnd do
freeze.Unfreeze(tt, true, true)
end
end
local preci=behavior.GetClashImportance()
setCI(cival)
wig()
CheckBest()
if InIdT==false then
if SSf==true then
Fuzit()
end
end
if frz == true then
for i=1, nSegs do
if freeze.IsFrozen(i) and get_ss(i) == 'E' then
freeze.Unfreeze(i, true, false)
end
end
end
setCI(preci)
Delbands()
CheckBest()
end
function LocalBands()
CheckBest()
if LoBaCD == false then
print(" Local push ..")
else
print(" Local pull ..")
end
if ConB then -- contact only or all in range
if RR == true then -- create local contact bands
for y = xseg, xseg+rbLng-1 do
if y==nSegs then break end
for j = 1, y-1 do
if contactmap.GetHeat(y, j) ~=0 and structure.GetDistance(y,j) <= Qradius then band.AddBetweenSegments(y,j) end
end
if y<=nSegs-2 then
for j = y+1, nSegs do
if contactmap.GetHeat(y, j) ~=0 and structure.GetDistance(y,j) <= Qradius then band.AddBetweenSegments(y,j) end
end end
end
else
for y = rbldStrt, rbldEnd do
if y==nSegs then break end
for j = 1, y-1 do
if contactmap.GetHeat(y, j) ~=0 and structure.GetDistance(y,j) <= Qradius then band.AddBetweenSegments(y,j) end
end
if y<=nSegs-2 then
for j = y+1, nSegs do
if contactmap.GetHeat(y, j) ~=0 and structure.GetDistance(y,j) <= Qradius then band.AddBetweenSegments(y,j) end
end end
end
end
else
for i=1, nSegs do -- create local bands
if RR == true then
for x = xseg, xseg+rbLng-1 do
if structure.GetDistance(i,x) <= Qradius then band.AddBetweenSegments(i,x) end end
else
for x = rbldStrt, rbldEnd do
if structure.GetDistance(i,x) <= Qradius then band.AddBetweenSegments(i,x)  end end
end  end
end
if LoBaCD == false then -- push or pull
if KBSTR == true then  -- decompress
local NNbands = band.GetCount()
for i=oldbands+1, NNbands do
band.SetGoalLength(i,band.GetLength(i)+4)
end
else
for i=1, band.GetCount() do
band.SetGoalLength(i,band.GetLength(i)+4)
end
end
else
if KBSTR == true then  -- compress
local NNbands = band.GetCount()
for i=oldbands+1, NNbands do
band.SetGoalLength(i,band.GetLength(i))
if band.GetLength(i)-10>0 then
band.SetGoalLength(i,band.GetLength(i)-9)
end
if band.GetLength(i)-6>0 then
band.SetGoalLength(i,band.GetLength(i)-5)
end
if band.GetLength(i)-4>0 then
band.SetGoalLength(i,band.GetLength(i)-3)
end
end
else
for i=1, band.GetCount() do
band.SetGoalLength(i,band.GetLength(i))
if band.GetLength(i)-10>0 then
band.SetGoalLength(i,band.GetLength(i)-9)
end
if band.GetLength(i)-6>0 then
band.SetGoalLength(i,band.GetLength(i)-5)
end
if band.GetLength(i)-4>0 then
band.SetGoalLength(i,band.GetLength(i)-3)
end
end
end
end
if KBSTR == true then -- band strength
local NNbands = band.GetCount()
for i=oldbands+1, NNbands do
band.SetStrength(i, LBstr)
end
else
for i=1, band.GetCount() do
band.SetStrength(i, LBstr)
end
end
setCI(cival)
wig("wa",4)  CheckBest()
if RR == true then
for tt = xseg, xseg+rbLng-1 do
selectsphere(tt, Qradius+1)
end
else
for tt = rbldStrt, rbldEnd do
selectsphere(tt, Qradius+1)
end
end
CheckAla()
if (mut3 == true) or (mutaL) or (muta1 == true) then
setCI(cival)
structure.MutateSidechainsSelected(1)  CheckBest()
CheckAla()
else
if AllAla == false then
setCI(cival)
structure.ShakeSidechainsSelected(1)  CheckBest()
end
end
setCI(cival)
selection.DeselectAll()
Disbands(oldbands)
wig("wb",8)  CheckBest()
wig()  CheckBest()
recentbest.Restore()
Delbands()
CheckBest()
end
function Bander()
CheckAla()
yy=0
InBander = true
Delbands()
selection.DeselectAll()
recentbest.Save()
BndrStartscore = score()
BndrBestscore = score()
save.Quicksave(8)
if runs>50 then
print(" Let's get things moving, shall we.")
print("",runs,"runs to go.")
end
for bandruns=1, runs do
CheckAla()
if comdecom == true then
if Bloat == true then
print(" Expand ",bandruns,"of",runs)
else
print(" Contract ",bandruns,"of",runs)
end
else
print(" Spacebands ",bandruns,"of",runs)
end
if (yy>=noGains) or (bandruns == 1) then
save.Quickload(8)
recentbest.Restore()
yy=0
end
Delbands()
Bscore = score()
if Bscore > BndrStartscore+0.1 or (bandruns == 1) then
print(" ",cut(score()),"")
else
end
if Bscore > BndrStartscore+0.1 then
print(" Bander gain:",cut(BndrBestscore-BndrStartscore)," Last gain: Run",ZZ)
end
if (SpBa == true) and (comdecom == false) then
amnt=minB
spacebands(amnt)
elseif (SpBa == true) and (comdecom == true) then
amnt=math.random(minB*3)
spacebands(amnt)
create()
if (bandruns*33)%2 ~= 0 then create() end
if band.GetCount()<minB then create() end
if band.GetCount()<minB then create() end
if band.GetCount()<=oldbands then
luktni = true
create()
end
elseif (SpBa == false) and (comdecom == true) then
create()
if (bandruns*33)%2 ~= 0 then create() end
if band.GetCount()<minB then create() end
if band.GetCount()<minB then create() end
if band.GetCount()<minB then create() end
if band.GetCount()<minB then create() end
if band.GetCount()<minB then create() end
if band.GetCount()<minB then create() end
if band.GetCount()<=oldbands then
luktni = true
create()
end
end
bandage()
setCI(pullci*cival)
pull(minBS, maxBS)
print("",cut(score()))
if score()>Bscore then -- if: pull has gained
recentbest.Restore()
CheckBest()
end
save.Quicksave(97)
if shap == true then
if raci == true then
ranci=(math.random(cival*100)/100)
setCI(ranci)
else
setCI(qci)
end
if muta1 == true then
selectMutas()
structure.MutateSidechainsSelected(1)  CheckBest()
selection.DeselectAll()
wig("s")  CheckBest()
else
wig("s")  CheckBest()
end
end
CheckAla()
Disbands(oldbands)
setCI(cival)
wig()  CheckBest()
if tryboth == true then
save.Quickload(97)
end
Disbands(oldbands)
wig()  CheckBest()
recentbest.Restore() CheckBest()
print("",cut(score()))
if bandson == true then
print("    fuzing with bands ..")
band.EnableAll()
Fuzing()
end
Delbands()
QTest()
recentbest.Restore()
CheckBest()
if fuzt>=0 then
if score()>(Bscore-fuzt) then
Fuzing()
end
else
if score()>=(Bscore+FF) then
Fuzing()
end
recentbest.Restore()
end
if (BndrBestscore-Bscore)>0.1 then -- if: gain in this run
TT = bandruns
ZZ = TT
end
bandruns = bandruns+1
if both == true then
if Bloat == true then Bloat = false
elseif Bloat == false then Bloat = true end
end
if score()-startscore<=0.001 then
yy=yy+1
recentbest.Restore()
CheckBest()
end
end
BanderResult()
InBander = false
CheckBest()
print(" Gained:",cut(BndrBestscore-BndrStartscore))
CheckAla()
end
------------------------------------------------------------------------
checkLock()
CheckAla()
if lockd>nSegs-1 then
print(" Not enough to work with.")
print("")
return UnfreezeSomething()
end
while contains(locklist,startD) do
startD=startD+1
end
while contains(locklist,endD) do
endD=endD-1
end
while contains(locklist,endseg) do
endseg=endseg-1
end
while contains(locklist,startseg) do
startseg=startseg+1
end
maxRPC = (nSegs-lockd)
maxrblng = (nSegs-lockd)
PresDia()
if custom == false then
numruns = 5000
numruns2 = 5000
RbldsPrCycle = 20--(nSegs/3)
NumberOfRebuilds = 5
rbIt = 5
SubscorePart = 'total'
WorstFirst = true
Sf = true
fzt = -1
if fzt<=0 then FFzt = (-1*fzt) end
qSt = false
raci = true
if (band.GetCount()>0) and (KB == false) and (KBE == false) then
band.DeleteAll()
end
if Strtgame == true then
IdealT = false
if sgsl == 1 then
RR = false
lFirst = false
minrb = 3
maxrb = 4
elseif sgsl == 2 then
RR = false
lFirst = true
minrb = 5
maxrb = 8
elseif sgsl == 3 then
RR = true
lFirst = true
minrb = 5
maxrb = 8
end
elseif Midgame == true then
IdealT = false
if mgsl == 1 then
RR = false
lFirst = true
minrb = 4
maxrb = 6
elseif mgsl == 2 then
RR = true
lFirst = true
minrb = 5
maxrb = 8
elseif mgsl == 3 then
RR = true
lFirst = true
minrb = 3
maxrb = 6
end
elseif Endgame == true then
IdealT = true
minrb = 2
maxrb = 4
if egsl == 1 then
RR = false
lFirst = true
elseif egsl == 2 then
RR = true
lFirst = true
elseif egsl == 3 then
SubscorePart = 'sidechain'
RbldsPrCycle = (nSegs/3)
WorstFirst = false
RR = false
lFirst = false
LocW = true
WigSC = true
elseif egsl == 4 then
SubscorePart = 'sidechain'
RbldsPrCycle = (nSegs/3)
WorstFirst = false
RR = true
lFirst = false
LocW = true
WigSC = true
end
end
if lFirst == true then
rbLng=maxrb
elseif lFirst == false then
rbLng=minrb
end
end
print(" Startscore: ", cut(score()))
print(" Best score will be saved in quickslot 1 ")
print(" Starting structure in quickslot 2 ")
if AllAla == true then
print("  No sidechains: no shaking, still mutating if checked.")
end
OptionsTest()
setCI(cival)
CheckBander()
save.SaveSecondaryStructure()
print("")
if RR == false then
if numruns<1 then
print(" "..numruns.." cycle of deep rebuild, coming up.")
else
print(" "..numruns.." cycles of deep rebuild, coming up.")
end
else
if numruns2<1 then
print(" "..numruns2.." cycle of rainbow rebuild, coming up.")
else
print(" "..numruns2.." cycles of rainbow rebuild, coming up.")
end
end
AAs={"a", "c", "d", "e", "f", "g", "h", "i", "k", "l", "m", "n", "p", "q", "r", "s", "t", "v", "w", "y"}
recentbest.Save()
save.Quicksave(99)
save.Quicksave(8)
save.Quicksave(2)
save.Quicksave(1)
if DisFil then behavior.SetSlowFiltersDisabled(false) end
startscore = score()
bestscore = startscore
TempSegSc=(-1*seed)
------------------------------------------------------------------------
function main()
noGain = false
badcycles = 0
goodcycles = 0
rblds = 0
cyc = 0
rcyc = 0
cyc1 = 1
rcyc1 = 1
minusR = 0
printRR=true
if bFi==true then Bander() end
if RR == true then
for rb=1, numruns2 do                        --  RR
CheckBest()
--[[
print("rcyc1",rcyc1)
print("rbCy",rbCy)
print("rbCh",rbCh)
print("rbLng",rbLng)
]]
if (ciDo == true) and (rblds>=1) then
if cyGa>0 then
if (score()-cRscore)<=cyGa then
if goodcycles>= ciCy then
cival=(cival+ciCh)
end
end
elseif cyGa == 0 then
if badcycles>=ciCy then
cival=(cival+ciCh)
end
end
if cival>1 then cival = 1
elseif cival<=0 then cival = 0.15 end
print("  maxCI = "..cival)
setCI(cival)
wig() CheckBest()
setCI(cival/2)
wig() CheckBest()
setCI(cival)
wig() CheckBest()
recentbest.Restore()
CheckBest()
end
save.Quickload(99)
cRscore = score()
if rcyc1>rbCy then
rcyc1=1
if rbCh>0 then
rbLng = (rbLng+rbCh)
else
if rbCh<0 then
local rbCha = (-1*rbCh)
rbLng = (rbLng-rbCha)
end
end
if rbLng<minrb then rbLng = maxrb end
if rbLng>maxrb then rbLng = minrb end
end
rblds = 0
for seg = startseg, endseg - (rbLng - 1) do
selection.DeselectAll()
broken = false
for x = seg, seg+rbLng-1 do
if get_ss(x) ~= 'L' then
if notsheets  then
if get_ss(x) == 'E' then
broken = true
end
end
if nothelices  then
if get_ss(x) == 'H' then
broken = true
end
end
end
if get_ss(x) == 'L' then
if notloops  then
broken = true
end
end
end
if broken ~= true then
if isMovable(seg, seg+rbLng-1) == true then
save.Quickload(99)
selection.SelectRange(seg, seg+rbLng-1)
CheckAla()
if printRR==true then
print("")
rcyc=rcyc+1
print(" Cycle",rcyc,"of",numruns2-minusR)
print(" Rebuild length: "..rbLng)
print(" Range: "..startseg.."-"..endseg)
print(" Starting score this cycle: "..cut(score()))
printRR=false
end
rblds = rblds+1
print(" Rebuild:",rblds,"Segments:",seg.."-"..seg+rbLng-1," "..cut(score()).." ",os.date("%X"))
xseg = seg
oldscore = score()
if AllLoop then
for e=1, nSegs do
if selection.IsSelected(e) then structure.SetSecondaryStructure(e, "L") end
end
end
setCI(rbci)
Disbands(oldbands)
structure.RebuildSelected(1)
recentbest.Save()
structure.RebuildSelected(rbIt)
setCI(cival)
recentbest.Restore()
if Bands then band.EnableAll() end
newscore = score()
save.LoadSecondaryStructure()
if (oldscore ~= newscore) then
for g=seg, seg+rbLng-1 do
selectsphere(g,ShakeSphere)
end
if mutaL then
setCI(.87)
structure.MutateSidechainsSelected(1) CheckBest()
else
if AllAla == false then
setCI(.2)
structure.ShakeSidechainsSelected(1) CheckBest()
end
end
CheckBest()
setCI(cival)
if Bands then band.EnableAll() end
if WigSC then
--  selection.DeselectAll()
--  selection.SelectRange(rbldStrt,rbldEnd)
setCI(cival)
structure.WiggleAll(14, false, true) CheckBest()
end
if LocW then
selection.DeselectAll()
selection.SelectRange(rbldStrt,rbldEnd)
structure.LocalWiggleSelected(10, true, true) CheckBest()
end
recentbest.Restore()
CheckBest()
selection.DeselectAll()
if Bands then band.EnableAll() end
if Stitch then StitchEm() end
if score()>5000 then
setCI(cival)
wig("wa",9) CheckBest()
else
setCI(0.6*cival)
wig("wa",3) CheckBest()
setCI(cival)
wig("wa",9) CheckBest()
end
recentbest.Restore()
CheckBest()
if Bands then band.EnableAll() end
setCI(cival/2)
wig("wa",3) CheckBest()
setCI(cival)
wig("wa",9) CheckBest()
recentbest.Restore() CheckBest()
if IdealT then
print(" Idealize ..")
selection.DeselectAll()
InIdT=true
local idS=score()
selection.SelectRange(seg,seg+rbLng-1)
structure.IdealizeSelected() CheckBest()
qStab()
save.LoadSecondaryStructure()
if fzt>=0 then
if score()>(idS-fzt) then
if muta then
Fuze1mut()
else
Fuzit()
end
end
else
if score()>=(idS+FFzt) then
if muta then
Fuze1mut()
else
Fuzit()
end
end
end
InIdT=false
elseif IdealT == false then
if qSt then
qStab()
end
end
if SinSq then
LocalBands()
end
CheckBest()
if fzt>=0 then
if score()>(oldscore-fzt) then
if muta then
Fuze1mut()
else
Fuzit()
end
end
else
if score()>=(oldscore+FFzt) then
if muta then
Fuze1mut()
else
Fuzit()
end
end
end
newscore = score()
CheckAla()
if (oldscore - newscore) < 51 then
setCI(cival/2)
wig("s") CheckBest()
setCI(cival)
wig("wa",5) CheckBest()
recentbest.Restore()
CheckBest()
end
end
newscore = score()
if(newscore > oldscore) then
recentbest.Restore()
CheckBest()
save.Quicksave(99)
save.Quicksave(8)
print(" Gained "..cut(score()-oldscore).." pts. this rebuild.")
else
end
end
if (rbldcomp == true) and (rblds>=1)  then
Bander()
end
save.Quickload(99)
end
end
if (score()-cRscore)>1 then
print(" Startscore: "..cut(startscore).."  Score: "..cut(score()))
print(" Gained: "..cut((score()-cRscore)).." pts. this cycle.")
noGain = false
badcycles = 0
goodcycles = goodcycles+1
printRR=true
else
noGain = true
badcycles = badcycles+1
if rcyc>0 then
print(" Score: "..cut(score()), "  No gain this cycle.")
printRR=true
else
numruns2 = numruns2 +1
minusR=minusR+1
end
end
if badcycles>5 and rbLng == nSegs then
rbLng = nSegs/3
end
if (bfm==true) and (rblds>=1) then allWalk() end
if (cyclecomp == true) and (rblds>=1)  then
Bander()
end
rcyc1 = rcyc1+1
end
else
for cy=1,numruns do                           --  DRW
save.Quickload(99)
if (ciDo == true) and (rblds>=1) then
if cyGa>0 then
if (score()-cscore)<=cyGa then
if goodcycles>= ciCy then
cival=(cival+ciCh)
end
end
elseif cyGa == 0 then
if badcycles>=ciCy then
cival=(cival+ciCh)
end
end
if cival>1 then cival = 1
elseif cival<=0 then cival = 0.15 end
print("  maxCI = "..cival)
setCI(cival)
wig()
setCI(cival/2)
wig()
setCI(cival)
wig()
recentbest.Restore()
CheckBest()
end
if cyc1>rbCy then
cyc1=1
if rbCh>0 then
rbLng = (rbLng+rbCh)
else
if rbCh<0 then
local rbCha = (-1*rbCh)
rbLng = (rbLng-rbCha)
end
end
if rbLng<minrb then rbLng = maxrb end
if rbLng>maxrb then rbLng = minrb end
end
if notloops==true then
broken = true
checkLengths('L', rbLng)
end
if nothelices  then
broken = true
checkLengths('H', rbLng)
end
if notsheets  then
broken = true
checkLengths('E', rbLng)
end
checkLockLengths(rbLng)
if broken ~= true then
cyc=cyc+1
cscore = score()
print("")
print(" Cycle",cyc,"of ",numruns)
print(" Rebuild length:",rbLng)
print(" Range: "..startD.."-"..endD)
print(" Starting score this cycle: "..cut(score()))
if (gsort and cyc>1) then if PersCnt==false then SortItWell(SubscorePart)
garyCnt = 0 end else SortItWell(SubscorePart) garyCnt=0 end
if WorstFirst == true then
print(" Looking for worst "..SubscorePart.." score.")
else
print(" Looking for best "..SubscorePart.." score.")
end
rblds = 0
j=0
Jround=0
while rblds < RbldsPrCycle do
broken = false
j=j+1
if j>nSegs then
j=1
Jround=Jround+1
end
if Jround>=2 then break end
if (grid[j][2]-1) < 0 then grid[j][2] = (grid[j][2]+1) end
if (grid[j][2]+1) > nSegs+1 then grid[j][2] = (grid[j][2]-1) end
rbldseg = grid[j][2]
--print("real rbldseg",rbldseg)
if (rbldseg+(rbLng/2))<nSegs then
rbldEnd = math.floor(rbldseg+(rbLng/2))
else
rbldEnd = nSegs
end
if (rbldseg-(rbLng/2))>1 then
rbldStrt = math.ceil(rbldseg-(rbLng/2))
else
rbldStrt = 1
end
if rbLng%2 == 0 then
if rbldEnd==nSegs then rbldStrt=rbldStrt+1
else rbldEnd=rbldEnd-1
end
end
local sellngth=(rbldEnd-rbldStrt)
if sellngth<rbLng-1 then
if rbldStrt==1 then rbldEnd=rbldEnd+1
elseif rbldEnd==nSegs then rbldStrt=rbldStrt-1
end
elseif sellngth>=rbLng then
if rbldStrt==1 then rbldEnd=rbldEnd-1
elseif rbldEnd==nSegs then rbldStrt=rbldStrt+1
end
end
local sellngth=(rbldEnd-rbldStrt)
if sellngth<rbLng-1 then
if rbldStrt==1 then rbldEnd=rbldEnd+1
elseif rbldEnd==nSegs then rbldStrt=rbldStrt-1
end
elseif sellngth>=rbLng then
if rbldStrt==1 then rbldEnd=rbldEnd-1
elseif rbldEnd==nSegs then rbldStrt=rbldStrt+1
end
end
local sellngth=(rbldEnd-rbldStrt)
if sellngth<rbLng-1 then
if rbldStrt==1 then rbldEnd=rbldEnd+1
elseif rbldEnd==nSegs then rbldStrt=rbldStrt-1
end
elseif sellngth>=rbLng then
if rbldStrt==1 then rbldEnd=rbldEnd-1
elseif rbldEnd==nSegs then rbldStrt=rbldStrt+1
end
end
for x = rbldStrt, rbldEnd do
if get_ss(x) ~= 'L' then
if notsheets  then
if get_ss(x) == 'E' then
broken = true
end end
if nothelices  then
if get_ss(x) == 'H' then
broken = true
end end
elseif get_ss(x) == 'L' then
if notloops  then
broken = true
end end
end
if broken ~= true then
if (rbldStrt >= startD) and (rbldEnd <= endD) and (isMovable(rbldStrt, rbldEnd) == true) then
broken = false
else
broken = true
end
end
if broken ~= true then
save.Quickload(99)
CheckAla()
qscore = score()
save.LoadSecondaryStructure()
selection.DeselectAll()
rblds = rblds+1
print(" Rebuild:",rblds, "Segments:",rbldStrt.."-"..rbldEnd," "..cut(score()).." ",os.date("%X"))
selection.SelectRange(rbldStrt,rbldEnd)
if AllLoop then
for e=1, nSegs do
if selection.IsSelected(e) then structure.SetSecondaryStructure(e, "L") end
end
else
structure.SetSecondaryStructure(rbldseg, "L")
end
setCI(rbci)
Disbands(oldbands)
if testBeter == true then beter = false
elseif testBeter == false then beter = true end
if SubscorePart ~= 'total' then
TempSegSc = current.GetSegmentEnergySubscore(rbldseg,SubscorePart)
else
TempSegSc = current.GetSegmentEnergyScore(rbldseg)
end
--print("",rbldseg)
if gsort then
print(" Target's score:",cut(TempSegSc)) end
structure.RebuildSelected(1)
recentbest.Save()
save.Quicksave(97)
for k = 1, NumberOfRebuilds do
save.Quickload(97)
selection.SelectRange(rbldStrt,rbldEnd)
setCI(rbci)
structure.RebuildSelected(1)
selection.DeselectAll()
if Bands then band.EnableAll() end
for g=rbldStrt, rbldEnd do
selectsphere(g,ShakeSphere)
end
if mutaL then
setCI(.87)
structure.MutateSidechainsSelected(1)
else
if AllAla == false then
setCI(.2)
structure.ShakeSidechainsSelected(1)
end
end
CheckBest()
setCI(cival)
if WigSC then wig("ws", 14, 1) end
if LocW then
selection.DeselectAll()
selection.SelectRange(rbldStrt,rbldEnd)
if DisFil then behavior.SetSlowFiltersDisabled(true) end structure.LocalWiggleSelected(10, true, true) if DisFil then behavior.SetSlowFiltersDisabled(false) end
end
CheckBest()
selection.DeselectAll()
if GlWi == true then
if score()>5000 then
setCI(cival)
wig("wa",9) CheckBest()
else
setCI(0.6*cival)
wig("wa") CheckBest()
setCI(cival)
wig("wa",9) CheckBest()
end
end
CheckBest()
end
recentbest.Restore()
save.LoadSecondaryStructure()
CheckBest()
CheckAla()
if Bands then band.EnableAll() end
if Stitch then StitchEm() end
setCI(cival)
wig("wa",10) CheckBest()
if (cut(score()) ~= cut(qscore)) then
wig("s") CheckBest()
wig() CheckBest()
end
recentbest.Restore()
CheckBest()
if Bands then band.EnableAll() end
if (cut(score()) ~= cut(qscore)) then
setCI(cival/2)
wig("wa",3) CheckBest()
setCI(cival)
wig("wa",9)
recentbest.Restore()
CheckBest()
end
if IdealT then
selection.DeselectAll()
print(" Idealize ..")
InIdT=true
local idS=score()
selection.SelectRange(rbldStrt,rbldEnd)
structure.IdealizeSelected()
selection.DeselectAll()
wig() CheckBest()
if beter == true then
qStab()
if fzt>=0 then
if score()>(idS-fzt) then
if muta then
Fuze1mut()
else
Fuzit()
end
end
else
if score()>=(idS+FFzt) then
if muta then
Fuze1mut()
else
Fuzit()
end
end
end
else
setCI(cival/3)
wig('wa',10) CheckBest()
setCI(cival)
wig('wa',10) CheckBest()
end
InIdT=false
elseif (IdealT == false) and (beter == true) then
if qSt then qStab() end
end
------------------------------------------------
if testBeter == true then
if SubscorePart ~= 'total' then
PT = current.GetSegmentEnergySubscore(rbldseg,SubscorePart)
else
PT = current.GetSegmentEnergyScore(rbldseg)
end
if PT>=TempSegSc-0.03 then
beter=true
else
beter=false
end
end
------------------------------------------------
if LessTests == true then
if beter == true then
if SinSq then
if testBeter == true then
print(" Target's score:",cut(PT))
end
LocalBands()
end
CheckBest()
if fzt>=0 then
save.LoadSecondaryStructure()
if score()>(qscore-fzt) then
if muta then
Fuze1mut()
else
Fuzit()
end
end
else
if score()>=(qscore+FFzt) then
if muta then
Fuze1mut()
else
Fuzit()
end
end
end
recentbest.Restore()
CheckBest()
if (score()-qscore)>0.01 then
print(" Gained "..cut(score()-qscore).." pts. this rebuild.")
end
if (rbldcomp == true) and (rblds>=1) then Bander() end
end
else
if SinSq then
if testBeter == true then
print(" Target's score:",cut(PT))
end
LocalBands()
end
CheckBest()
if fzt>=0 then
save.LoadSecondaryStructure()
if score()>(qscore-fzt) then
if muta then
Fuze1mut()
else
Fuzit()
end
end
else
if score()>=(qscore+FFzt) then
if muta then
Fuze1mut()
else
Fuzit()
end
end
end
CheckBest()
if beter == true then
if (score()-qscore)>0.01 then
print(" Gained "..cut(score()-qscore).." pts. this rebuild.")
end
end
if (rbldcomp == true) and (rblds>=1) then Bander() end
end
if (score()-qscore)>1 then
garyCnt = garyCnt +1
if gsort==true then
if (cntGary-garyCnt)~=0 then
print(" ",cntGary-garyCnt,"more good rebuilds before sort.") end end
end
if gsort then
if garyCnt >= cntGary then SortItWell(SubscorePart)
print("  sorted ")
garyCnt = 0 end end
--if ReSort == true then SortItWell(SubscorePart) end
end
end
save.Quickload(99)
if testBeter==false then
recentbest.Restore()
CheckBest()
end
if (score()-cscore)>0.1 then
print(" Startscore: "..cut(startscore).."  Score: "..cut(score()))
print(" Gained: "..cut((score()-cscore)).." pts. this cycle.")
noGain = false
goodcycles = goodcycles+1
badcycles = 0
else
noGain = true
badcycles = badcycles+1
print(" Score: "..cut(score()), "  No gain this cycle.")
end
if badcycles>5 and rbLng == nSegs then
rbLng = nSegs/3
end
if badcycles>1 and SubscorePart=="backbone" then SubscorePart="total"
elseif badcycles>1 and SubscorePart=="total" then SubscorePart="ideality"
elseif badcycles>1 and SubscorePart=="ideality" then SubscorePart="sidechain"
elseif badcycles>1 and SubscorePart=="sidechain" then SubscorePart="bonding"
elseif badcycles>1 and SubscorePart=="bonding" then SubscorePart="clashing"
elseif badcycles>1 and SubscorePart=="clashing" then SubscorePart="hiding"
elseif badcycles>1 and SubscorePart=="hiding" then SubscorePart="packing"
elseif badcycles>1 and SubscorePart=="packing" then SubscorePart="backbone" end
if (bfm==true) and (rblds>=1) then allWalk() end
if (cyclecomp == true) and (rblds>=1)  then Bander() end
end
cyc1=cyc1+1
end
end
Result()
end
err = xpcall(main,End)
