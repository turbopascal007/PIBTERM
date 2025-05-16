(*----------------------------------------------------------------------*)
(*       Fast_Change_Params --- fast change of communications params.   *)
(*----------------------------------------------------------------------*)

PROCEDURE Fast_Change_Params;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Fast_Change_Params                                   *)
(*                                                                      *)
(*     Purpose:    Fast change of communications params                 *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Fast_Change_Params;                                           *)
(*                                                                      *)
(*                                                                      *)
(*      Remarks:                                                        *)
(*                                                                      *)
(*         This routine is useful is making a fast switch between       *)
(*         the parameter values needed by XMODEM and those required     *)
(*         by the remote host.                                          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

CONST
   Comm_Parities  : ARRAY[ 1 .. 5 ] OF CHAR    = ( 'N','E','O','M','S' );
   Comm_Data_Bits : ARRAY[ 1 .. 5 ] OF INTEGER = (  8,  7,  7,  7,  7  );
   Baud_Rates     : ARRAY[ 1 .. 5  ] OF WORD
                    = ( 300, 1200, 2400, 9600, 19200 );
   Letters        : ARRAY[1..25] OF CHAR
                    = ( 'a','f','k','p','u',
                        'b','g','l','q','v',
                        'c','h','m','r','w',
                        'd','i','n','s','x',
                        'e','j','o','t','y'  );

VAR
   I               : INTEGER;
   J               : INTEGER;
   Let             : INTEGER;
   Local_Save      : Saved_Screen_Ptr;
   OK_Choice       : BOOLEAN;
   Ch              : CHAR;

BEGIN (* Fast_Change_Params *)
                                   (* Draw frame around screen *)

   Draw_Titled_Box( Local_Save, 1, 5, 79, 14,
                    'Change communications settings' );

   PibTerm_Window( 2, 6, 78, 13 );
                                   (* Display params to choose from *)
   Let := 0;

   FOR I := 1 TO 5 DO
      BEGIN
         GoToXY( 2 , I );
         FOR J := 1 TO 5 DO
            BEGIN
               Let := Let + 1;
               TextColor( Menu_Text_Color_2 );
               WRITE( Letters[ Let ] );
               TextColor( Menu_Text_Color  );
               WRITE( ') ' );
               WRITE( Baud_Rates[J]:5,',',Comm_Data_Bits[I],',',
                      Comm_Parities[I],',1 ' );
            END;
      END;
                                   (* Get new params *)
   REPEAT
      GoToXY( 2 , 7 );
      TextColor( Menu_Text_Color_2 );
      WRITE ( 'Enter letter corresponding to new parameters or ESC to quit: ');
      TextColor( Menu_Text_Color );
      Read_Kbd( Ch );
      Ch := UpCase( Ch );
      OK_Choice := ( Ch = CHR( ESC ) ) OR
                   ( Ch = CHR( CR  ) ) OR
                   ( ( ORD( Ch ) >= ORD( 'A' ) ) AND
                     ( ORD( Ch ) <= ORD( 'Y' ) ) );
      IF ( NOT OK_Choice ) THEN
         Menu_Beep;
   UNTIL ( OK_Choice );
                                   (* Get parameters corresponding *)
                                   (* to choice.                   *)

   IF ( ( Ch <> CHR( ESC ) ) AND ( Ch <> CHR( CR ) ) ) THEN
      BEGIN

         Let := ORD( Ch ) - ORD( 'A' );
         J   := ( Let DIV 5 ) + 1;
         I   := ( Let MOD 5 ) + 1;

         Baud_Rate := Baud_Rates    [J];
         Parity    := Comm_Parities [I];
         Data_Bits := Comm_Data_Bits[I];
         Stop_Bits := 1;
                                   (* Reset the port *)

         Async_Reset_Port( Comm_Port, Baud_Rate, Parity, Data_Bits, Stop_Bits );

         Reset_Comm_Port := TRUE;

      END;
                                   (* Restore previous screen *)

   Restore_Screen_And_Colors( Local_Save );

END   (* Fast_Change_Params *);
