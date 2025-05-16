(*----------------------------------------------------------------------*)
(*               Initialize_Printer --- Initialize Printer              *)
(*----------------------------------------------------------------------*)

PROCEDURE Initialize_Printer;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Initialize_Printer                                   *)
(*                                                                      *)
(*     Purpose:    Initializes Printer                                  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Initialize_Printer;                                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Ch        : CHAR;
   Regs      : Registers;
   LstHandle : WORD ABSOLUTE Lst;

BEGIN (* Initialize_Printer *)
                                   (* Assign printer device *)
   ASSIGN ( Lst , 'PRN' );
   REWRITE( Lst );
                                   (* Check if this went OK *)
   Lst_OK := ( Int24Result = 0 );
                                   (* Ensure printer file is in binary mode *)
   WITH Regs DO
      BEGIN

         AX := $4400;              (* IOCTL sub function 0 - Get device information. *)
         BX := LstHandle;          (* Device information is returned in DX.          *)

         MsDos( Regs );

         AX := $4401;              (* IOCTL sub function 1 - Set device information. *)
                                   (* New device setting is passed in DX.            *)
                                   (* Set bit 5 of DX so data is passed in "raw"     *)
                                   (* mode through LST device.                       *)

         DX := ( DX AND $00FF ) OR $0020;

         MsDos( Regs );

      END;
                                   (* If printer setup string is not null, *)
                                   (* try sending it to printer.           *)

   IF ( LENGTH( Printer_Setup ) > 0 ) THEN
      BEGIN

         WRITE( Lst , Printer_Setup );
         Lst_OK := ( Int24Result = 0 );

         IF ( NOT Lst_OK ) THEN
            BEGIN

               WRITELN('*** Printer appears to be turned off or out of paper.');
               WRITELN('*** Please fix that and then press ESC key to continue.');

               IF Attended_Mode THEN
                  BEGIN
                     Read_Kbd( Ch );
                     IF ( Ch = CHR( ESC ) ) AND PibTerm_KeyPressed THEN
                        Read_Kbd( Ch );
                  END
               ELSE
                  WRITELN('*** Continuing anyway because of unattended mode.');

            END;

         WRITE( Lst , Printer_Setup );
         Lst_OK := ( Int24Result = 0 );

         IF Lst_OK THEN
            WRITELN('Printer initialization completed.')
         ELSE
            WRITELN('Printer initialization could not be done.')

      END;

END   (* Initialize_Printer *);
