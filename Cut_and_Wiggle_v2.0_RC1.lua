-- Adapted from Karen CH's script
min_residue = 1
max_residue =  999
n_residues = 0
fragment_length = 5
score_type = 1
original_slow_filters_setting = 0
curr_best_score = 0
kLowCI = 0.3
kOriginalStructureOrNewBest = 10

function r3 ( x )
  t  = 10 ^ 3
  return math.floor ( x * t ) /  t 
end

function GetScore ()
  if ( score_type == 1 ) then
    score = current.GetScore () 
  elseif ( score_type == 2 ) then
    behavior.SetFiltersDisabled ( false )
    score = current.GetScore () 
    behavior.SetFiltersDisabled ( true )
  end
  return score
end

function DoesPuzzleHaveSlowFilters ()
  init_setting = behavior.GetSlowFiltersDisabled ()
  if ( init_setting == false ) then
    score_without_sf = current.GetScore () 
    behavior.SetSlowFiltersDisabled ( true )
    score_with_sf = current.GetScore () 
  else
    score_with_sf = current.GetScore () 
    behavior.SetSlowFiltersDisabled ( false )
    score_without_sf = current.GetScore () 
  end
  behavior.SetSlowFiltersDisabled ( init_setting )
  if ( math.abs ( score_without_sf - score_with_sf ) >1e-3 ) then
    return true
  else
    return false
  end
end

function Go ()
  n_iterations_without_improvement = 0
  n = 0
  while true do
    for j = 0 , fragment_length - 1 do
      n = n + 1
      undo.SetUndo ( false )
      save.Quickload ( kOriginalStructureOrNewBest )
      for i = min_residue + j , max_residue , fragment_length do
        structure.InsertCut ( i )
      end
      selection.SelectRange ( min_residue , max_residue )
      behavior.SetClashImportance ( kLowCI )
      structure.WiggleSelected ( 1 )
      behavior.SetClashImportance ( 1.0 )
      structure.WiggleSelected ( 10 )
      for i = min_residue + j , max_residue , fragment_length do
        structure.DeleteCut ( i )
      end
      undo.SetUndo ( true )
      behavior.SetClashImportance ( kLowCI )
      structure.WiggleSelected ( 1 )
      behavior.SetClashImportance ( 1.0 )
      structure.WiggleSelected ( 10 )
      score = GetScore ()
      print ( "n " .. n .. " " .. r3 ( score ) )
      if ( score > curr_best_score ) then
        save.Quicksave ( kOriginalStructureOrNewBest )
        curr_best_score = score
        print ( "Improvement to " .. r3 ( score ) )
        n_iterations_without_improvement = 0
      else
        n_iterations_without_improvement = n_iterations_without_improvement + 1
      end
      if ( n_iterations_without_improvement >= fragment_length ) then
        return
      end
    end
  end
end

function GetParameters ()
  local dlog = dialog.CreateDialog ( "Cut and Wiggle 1.5" )
  dlog.min_residue = dialog.AddSlider ( "Min residue" , 1 , 1 , n_residues , 0 )  
  dlog.max_residue = dialog.AddSlider ( "Max residue" , n_residues , 1 , n_residues , 0 )  
  dlog.fragment_length = dialog.AddSlider ( "Fragment length" , fragment_length  , 1 , 10 , 0 )  
  dlog.cidm = dialog.AddSlider ( "Clash importance" , kLowCI , 0 , 1.0 , 2 )  
  if ( DoesPuzzleHaveSlowFilters () == true ) then
    score_type = 2
  end
  dlog.score_type = dialog.AddSlider ( "Score type" , score_type , 1 , 2 , 0 )  
  dlog.tp2 = dialog.AddLabel ( "1 = Normal : 2 = Normal for Filters"  )
  dlog.ok = dialog.AddButton ( "OK" , 1 )
  dlog.cancel = dialog.AddButton ( "Cancel" , 0 )
  if ( dialog.Show ( dlog ) > 0 ) then
    min_residue = dlog.min_residue.value
    max_residue = dlog.max_residue.value
    fragment_length = dlog. fragment_length.value
    kLowCI = dlog.cidm.value
    score_type = dlog.score_type.value
    return true
  else
    return false
  end
end

function main ()
  print ( "Cut and Wiggle 1.5" )
  band.DisableAll ()
  n_residues = structure.GetCount ()
  save.Quicksave ( kOriginalStructureOrNewBest )
  behavior.SetClashImportance ( 1.0 )
  original_slow_filters_setting = behavior.GetSlowFiltersDisabled ()
  if ( GetParameters () == false ) then
    return
  end
  print  ( "Range " .. min_residue .. " to " .. max_residue )
  print  ( "Fragment length " .. fragment_length  )
  print  ( "Clash importance low " .. r3 ( kLowCI ) )
  if ( score_type == 1 ) then
    print (  "Score type : Normal" )
  elseif ( score_type == 2 ) then
    print (  "Score type : Normal/Slow Filters" )
  end
  curr_best_score = GetScore ()
  print ( "Start score " .. r3 ( curr_best_score ) )
  print  ( "" )
  Go ()
  cleanup ()
end

function cleanup ()
  print ( "Cleaning up" )
  behavior.SetClashImportance ( 1.0 )
  save.Quickload ( kOriginalStructureOrNewBest )
  selection.SelectAll ()
  band.EnableAll ()
  if ( score_type == 2 ) then
    behavior.SetSlowFiltersDisabled ( original_slow_filters_setting )
  end
end

xpcall ( main , cleanup )

