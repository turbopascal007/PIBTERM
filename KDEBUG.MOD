{
PROCEDURE Kermit_Debug_Write_Boolean( S : AnyStr; B: BOOLEAN );

BEGIN (* Kermit_Debug_Write_Boolean *)

   IF B THEN
      Write_Log( 'Kermit debug: ' + S + ' = ON', FALSE, FALSE )
   ELSE
      Write_Log( 'Kermit debug: ' + S + ' = OFF', FALSE, FALSE );

END   (* Kermit_Debug_Write_Boolean *);

PROCEDURE Kermit_Debug_Write_String( S : AnyStr; S2 : AnyStr );

BEGIN (* Kermit_Debug_Write_String *)

   Write_Log( 'Kermit debug: ' + S + ' = <' +  S2  + '>', FALSE, FALSE );

END   (* Kermit_Debug_Write_String *);

PROCEDURE Kermit_Debug_Write_Char( S : AnyStr; Ch: CHAR );

BEGIN (* Kermit_Debug_Write_Char *)

   Write_Log( 'Kermit debug: ' + S + ' = <' + Ch  + '>', FALSE, FALSE );

END   (* Kermit_Debug_Write_Char *);

PROCEDURE Kermit_Debug_Write_Integer( S : AnyStr; B: INTEGER );

BEGIN (* Kermit_Debug_Write_Integer *)

   Write_Log( 'Kermit debug: ' + S + ' = ' + IToS( B ), FALSE, FALSE );

END   (* Kermit_Debug_Write_Integer *);

FUNCTION String_It( I: INTEGER ) : AnyStr;

VAR
   S: STRING[10];

BEGIN (* String_It *)

   STR( I , S );

   String_It := S;

END   (* String_It *);
}