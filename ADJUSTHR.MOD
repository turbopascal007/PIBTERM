(*--------------------------------------------------------------------------*)
(*        Adjust_Hour --- Convert 24 hour time to 12 hour am/pm             *)
(*--------------------------------------------------------------------------*)

PROCEDURE Adjust_Hour( VAR Hour : INTEGER;
                       VAR AmPm : ShortStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*    Procedure: Adjust_Hour                                            *)
(*                                                                      *)
(*    Purpose:   Converts 24 hour time to 12 hour am/pm time            *)
(*                                                                      *)
(*    Calling sequence:                                                 *)
(*                                                                      *)
(*       Adjust_Hour( VAR Hour : INTEGER; AmPm : ShortStr );            *)
(*                                                                      *)
(*          Hour --- Input = Hours in 24 hour form;                     *)
(*                   Output = Hours in 12 hour form.                    *)
(*          AmPm --- Output 'am' or 'pm' indicator                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Adjust_Hour *)

   IF ( Hour < 12 ) THEN
      BEGIN
         AmPm := 'am';
         IF ( Hour = 0 ) THEN
            Hour := 12;
      END
   ELSE
      BEGIN
         AmPm := 'pm';
         IF ( Hour <> 12 ) THEN
            Hour := Hour - 12;
      END;

END   (* Adjust_Hour *);
