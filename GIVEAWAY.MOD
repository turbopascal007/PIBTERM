(*--------------------------------------------------------------------------*)
(*            GiveAwayTime --- gives away time slices to other task         *)
(*--------------------------------------------------------------------------*)

PROCEDURE GiveAwayTime( NSlices : INTEGER );

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*    Procedure:  GiveAwayTime;                                             *)
(*                                                                          *)
(*    Purpose:    Gives away time slices to other tasks                     *)
(*                                                                          *)
(*    Calling Sequence:                                                     *)
(*                                                                          *)
(*       GiveAwayTime( NSlices :  INTEGER );                                *)
(*                                                                          *)
(*          NSlices --- # of slices (55 ms) to give away, if DoubleDos.     *)
(*                                                                          *)
(*    Calls:  GiveUpTime                                                    *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

VAR
   Regs : Registers;

BEGIN (* GiveAwayTime *)
                                   (* If printing a file, do that, *)
                                   (* else actually donate time to *)
                                   (* other partitions.            *)
   IF Print_Spooling THEN
      Print_Spooled_File
   ELSE
      GiveUpTime( NSlices );

END   (* GiveAwayTime *);
