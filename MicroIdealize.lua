kOriginalStructureOrNewBest = 1   -- the starting structure, or any subsequent improvement, will be stored in this quicksave slot
  best_score = 0
  idealize_length = 3
  min_residue = 1
  max_residue = 999
  worst_first = true
  idealize_ss = true
  use_local_wiggle = false
  local_wiggle_spacer = 3


  score_type = 1
  kDefaultWiggle = 12
  sphere = {}
  kSphereRadius = 10

  function r3 ( i )    -- printing convenience

      return i - i % 0.001

  end

  function GetScore ()

     if ( score_type == 1 ) then
         score = current.GetEnergyScore ()
     end

     return score

  end



 function SphereSelect ( start_idx , end_idx )

     for i = 1 , n_residues do
           sphere [ i ] = false
     end

     for  i = 1 , n_residues do
          for j = start_idx , end_idx do
             if ( structure.GetDistance ( i , j ) < kSphereRadius ) then
               sphere [ i ] = true
             end
          end
     end

     selection.DeselectAll ()

     for i = 1 , n_residues do
            if ( sphere [ i ] == true ) then
                     selection.Select ( i )
             end
     end
end

function GoSegment ( start_idx , end_idx )

    save.Quickload ( kOriginalStructureOrNewBest )

    if ( start_idx > 1 ) then
        structure.InsertCut ( start_idx )
    end

    if ( end_idx < n_residues ) then
        structure.InsertCut ( end_idx  )
    end

     selection.DeselectAll ()

     selection.SelectRange ( start_idx , end_idx )
     structure.IdealizeSelected ()

     if ( idealize_ss == false ) then
       structure.IdealizeSelected ()
      else
       structure.IdealSSSelected ()
     end

     if ( start_idx > 1 ) then
        structure.DeleteCut ( start_idx )
     end

     if ( end_idx < n_residues ) then
         structure.DeleteCut ( end_idx )
     end

     if ( use_local_wiggle == false ) then
         SphereSelect ( start_idx , end_idx )
         structure.WiggleSelected ( kDefaultWiggle )
      else
        selection.DeselectAll ()
        selection.SelectRange ( math.max ( 1 , start_idx - local_wiggle_spacer ) , math.min ( end_idx + local_wiggle_spacer , n_residues ) )
        structure.WiggleSelected ( kDefaultWiggle )
     end


     score = GetScore ()
     if ( score > best_score ) then
         best_score = score
         print ( "Improvement to "..  r3 ( best_score )  )
         save.Quicksave ( kOriginalStructureOrNewBest )
     end

 end

 function Coprime ( n )

     local primes = {2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97,101}

     i = #primes   -- find the highest prime < 70% of the residue count and which is coprime with the number of residues

     while ( i >= 1 ) do
          if ( primes [ i ] < n*0.7 and n % primes [ i ]  ~= 0 ) then
             return primes [ i ]
          end

          i = i - 1
     end

     return 1

 end

 function pseudorandom ( score )

 -- Returns a pseudorandom number >= 0 and < 1.

 -- Based on the fractional part of the  score

     if ( score >= 0 ) then
        return  score % 1
      else
        return (-score ) % 1
     end
 end


 function Go ()

    local inc

    max_possible_residue = max_residue - idealize_length + 1
    n_possible_segs = max_possible_residue - min_residue + 1
    r = pseudorandom ( best_score )

    start_idx = min_residue + n_possible_segs *  r
    start_idx = start_idx - start_idx % 1
    inc = Coprime ( n_possible_segs  )

    for  i = 1 , n_possible_segs do
        print ( start_idx .. "-" .. start_idx + idealize_length - 1 .. "  (" .. i .. "/" .. n_possible_segs .. ")" )
        GoSegment ( start_idx , start_idx + idealize_length - 1 )        start_idx = start_idx + inc
        if ( start_idx >  max_possible_residue ) then
           start_idx =  start_idx - n_possible_segs
        end
    end

 end

 function ShellSort ( ids , sequence_scores , n )

     -- Adapted from Numerical Recipes in C

     local  inc = 1

     repeat
       inc = inc * 3 + 1
     until inc > n

     repeat
        inc = inc / 3
        inc = inc - inc % 1

        for i = inc + 1 , n do
            v = sequence_scores [ i ]
            w = ids [  i ]
            j = i

            flag = false

            while ( flag == false and sequence_scores [ j - inc ]  > v ) do
               sequence_scores [ j ] = sequence_scores [ j - inc ]
               ids [ j ] = ids [ j - inc ]
               j = j - inc

               if ( j <= inc ) then
                   flag = true
               end
            end

            sequence_scores [ j ] = v
            ids [ j ] = w
         end
     until inc <= 1

end

function GoWorstFirst ()

    ideality_scores = {}
    sequence_scores = {}
    ids = {}

    max_possible_residue = max_residue - idealize_length + 1
    n_possible_segs = max_possible_residue - min_residue + 1

    for i = min_residue , max_residue do
        ideality_scores [ i ] = current.GetSegmentEnergySubscore ( i , "ideality" )--print ( i .. "  " .. r3 ( ideality_scores [ i ] ) )
    end

    idx = 1

    for i = min_residue , max_residue - idealize_length + 1 do

        total = 0
        for j = i , i + idealize_length - 1 do
            total = total + ideality_scores [ j ]
        end

        sequence_scores [ idx ] = total
        ids [ idx ] = i--print ( idx .. "  " .. ids [ idx ] .. "  " .. r3 ( sequence_scores [ idx ] ) )
        idx = idx + 1
     end

     ShellSort ( ids , sequence_scores , max_possible_residue - min_residue + 1 )

     for  i = 1 , n_possible_segs do --print ( i .. "  " .. ids [ i ] .. "  " .. r3 ( sequence_scores [ i ] ) )
        print (  ids [ i ] .. "-" ..  ids [ i ] + idealize_length - 1 .. "  (" .. i .. "/" .. n_possible_segs .. ")" )
        GoSegment ( ids [ i ] , ids [ i ]  + idealize_length - 1 )
     end
 end


 function GetParameters ()

     local dlog = dialog.CreateDialog ( "MicroIdealize 5.0" )
     dlog.idealize_length = dialog.AddSlider ( "Idealize length" , idealize_length , 1 , 20 , 0 )
     dlog.min_residue = dialog.AddSlider ( "Min residue" , min_residue , 1 , n_residues , 0 )
     dlog.max_residue = dialog.AddSlider ( "Max residue" , max_residue , 1 , n_residues , 0 )
     dlog.i_ss = dialog.AddCheckbox ( "Use IdealizeSS" , idealize_ss )
     dlog.worst_first = dialog.AddCheckbox ( "Worst first" , worst_first )
     dlog.use_local_wiggle = dialog.AddCheckbox ( "Local Wiggle" , use_local_wiggle  )

     dlog.local_wiggle_spacer = dialog.AddSlider ( "Local wiggle spacer" , local_wiggle_spacer , 0 , 10 , 0 )

     dlog.ok = dialog.AddButton ( "OK" , 1 )
     dlog.cancel = dialog.AddButton ( "Cancel" , 0 )

     if ( dialog.Show ( dlog ) > 0 ) then
          idealize_length = dlog.idealize_length.value
          min_residue = dlog.min_residue.value
          max_residue = dlog.max_residue.value
          idealize_ss = dlog.i_ss.value
          worst_first  = dlog.worst_first.value
          local_wiggle_spacer = dlog.local_wiggle_spacer.value
          use_local_wiggle = dlog.use_local_wiggle.value

          return true
       else
          return false
      end

 end

 function main ()

     print (  "MicroIdealize 5.0" )
     save.Quicksave ( kOriginalStructureOrNewBest )

     best_score = GetScore ()
     print ( "Start score " .. r3 ( best_score ) )
     n_residues = structure.GetCount ()

         -- Trim off locked terminal sequences as a UI convenience

     min_residue = 1
     while ( ( structure.IsLocked ( min_residue ) == true ) and ( min_residue <= n_residues ) ) do
       min_residue = min_residue + 1
     end

     max_residue = n_residues
     while ( ( structure.IsLocked ( max_residue ) == true ) and ( max_residue >= 1 ) ) do
       max_residue = max_residue - 1
     end

     if ( GetParameters () == false ) then
        return                -- graceful exit
     end

     if ( score_type == 2 ) then
        behavior.SetSlowFiltersDisabled ( true )
     end

     print  ( "Idealize range " .. min_residue .. " to " .. max_residue )

     print ( "Length " .. idealize_length )
     if ( idealize_ss == true ) then
        print ( "Using Idealize SS" )
     end

     if ( worst_first == false ) then
        Go ()
      else
        GoWorstFirst ()
     end

     cleanup ()

end

function cleanup ()
    print ( "Cleaning up" )
    behavior.SetClashImportance ( 1.0 )
    save.Quickload ( kOriginalStructureOrNewBest )
end

--main ()
xpcall (main, cleanup)
