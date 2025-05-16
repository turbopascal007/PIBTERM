
(*----------------------------------------------------------------------*)
(*                 Global variables for music playing                   *)
(*----------------------------------------------------------------------*)

(* STRUCTURED *) CONST
                                   (* Current Octave for Note *)
   Note_Octave   : INTEGER = 4;
                                   (* Fraction of duration given to note *)
   Note_Fraction : REAL    = 0.875;
                                   (* Duration of note *)
   Note_Duration : INTEGER = 0;
                                   (* Length of note *)
   Note_Length   : REAL    = 0.25;
                                   (* Length of quarter note (principal beat) *)
   Note_Quarter  : REAL    = 500.0;

(* ------------------------------------------------------------------------ *)
(*               PibPlaySet --- Set up to play music                        *)
(*               PibPlay    --- Play Music through Speaker                  *)
(* ------------------------------------------------------------------------ *)

PROCEDURE PibPlaySet;

(* ------------------------------------------------------------------------ *)
(*                                                                          *)
(*   Procedure:  PibPlaySet                                                 *)
(*                                                                          *)
(*   Purpose:    Sets up to play music though PC's speaker                  *)
(*                                                                          *)
(*   Calling Sequence:                                                      *)
(*                                                                          *)
(*      PibPlaySet;                                                         *)
(*                                                                          *)
(*   Calls:  None                                                           *)
(*                                                                          *)
(* ------------------------------------------------------------------------ *)

BEGIN (* PibPlaySet *)

                                   (* Default Octave *)
   Note_Octave   := 4;
                                   (* Default sustain is semi-legato *)
   Note_Fraction := 0.875;
                                   (* Note is quarter note by default *)
   Note_Length   := 0.25;
                                   (* Moderato pace by default *)
   Note_Quarter  := 500.0;

END   (* PibPlaySet *);

PROCEDURE PibPlay( S : AnyStr );

(* ------------------------------------------------------------------------ *)
(*                                                                          *)
(*   Procedure:  PibPlay                                                    *)
(*                                                                          *)
(*   Purpose:    Play music though PC's speaker                             *)
(*                                                                          *)
(*   Calling Sequence:                                                      *)
(*                                                                          *)
(*      PibPlay( Music_String : AnyStr );                                   *)
(*                                                                          *)
(*         Music_String --- The string containing the encoded music to be   *)
(*                          played.  The format is the same as that of the  *)
(*                          MicroSoft Basic PLAY Statement.  The string     *)
(*                          must be <= 254 characters in length.            *)
(*                                                                          *)
(*   Calls:  Sound                                                          *)
(*           GetInt  (Internal)                                             *)
(*                                                                          *)
(*   Remarks:  The characters accepted by this routine are:                 *)
(*                                                                          *)
(*             A - G       Musical Notes                                    *)
(*             # or +      Following A - G note,  indicates sharp           *)
(*             -           Following A - G note,  indicates flat            *)
(*             <           Move down one octave                             *)
(*             >           Move up one octave                               *)
(*             .           Dot previous note (extend note duration by 3/2)  *)
(*             MN          Normal duration (7/8 of interval between notes)  *)
(*             MS          Staccato duration                                *)
(*             ML          Legato duration                                  *)
(*             Ln          Length of note (n=1-64; 1=whole note,            *)
(*                                         4=quarter note, etc.)            *)
(*             Pn          Pause length (same n values as Ln above)         *)
(*             Tn          Tempo, n=notes/minute (n=32-255, default n=120)  *)
(*             On          Octave number (n=0-6, default n=4)               *)
(*             Nn          Play note number n (n=0-84)                      *)
(*                                                                          *)
(*             The following two commands are IGNORED by PibPlay:           *)
(*                                                                          *)
(*             MF          Complete note before continuing                  *)
(*             MB          Another process may begin before speaker is      *)
(*                         finished playing note                            *)
(*                                                                          *)
(*   IMPORTANT --- PibPlaySet MUST have been called at least once before    *)
(*                 this routine is called.                                  *)
(*                                                                          *)
(* ------------------------------------------------------------------------ *)

(* STRUCTURED *) CONST
                                   (* Offsets in octave of natural notes *)

   Note_Offset   : ARRAY[ 'A'..'G' ] OF INTEGER
                   = ( 9, 11, 0, 2, 4, 5, 7 );

                                   (* Frequencies for 7 octaves *)

   Note_Freqs: ARRAY[ 0 .. 84 ] OF INTEGER
               =
(*
      C    C#     D    D#     E     F    F#     G    G#     A    A#     B
*)
(     0,
     65,   69,   73,   78,   82,   87,   92,   98,  104,  110,  116,  123,
    131,  139,  147,  156,  165,  175,  185,  196,  208,  220,  233,  247,
    262,  278,  294,  312,  330,  350,  370,  392,  416,  440,  466,  494,
    524,  556,  588,  624,  660,  700,  740,  784,  832,  880,  932,  988,
   1048, 1112, 1176, 1248, 1320, 1400, 1480, 1568, 1664, 1760, 1864, 1976,
   2096, 2224, 2352, 2496, 2640, 2800, 2960, 3136, 3328, 3520, 3728, 3952,
   4192, 4448, 4704, 4992, 5280, 5600, 5920, 6272, 6656, 7040, 7456, 7904  );

   Quarter_Note = 0.25;            (* Length of a quarter note *)

   Digits : SET OF '0'..'9' = ['0'..'9'];

VAR
                                   (* Frequency of note to be played *)
   Play_Freq     : INTEGER;

                                   (* Duration to sound note *)
   Play_Duration : INTEGER;

                                   (* Duration of rest after a note *)
   Rest_Duration : INTEGER;

                                   (* Offset in Music string *)
   I             : INTEGER;
                                   (* Current character in music string *)
   C             : CHAR;
                                   (* Note Frequencies *)

   Freq          : ARRAY[ 0 .. 6 , 0 .. 11 ] OF INTEGER ABSOLUTE Note_Freqs;

   N             : INTEGER;
   XN            : REAL;
   K             : INTEGER;

(* ------------------------------------------------------------------------ *)

FUNCTION GetInt : INTEGER;

(*   --- Get integer from music string --- *)

VAR
   N : INTEGER;

BEGIN (* GetInt *)

   N := 0;

   WHILE( S[I] IN Digits ) DO
      BEGIN
         N := N * 10 + ORD( S[I] ) - ORD('0');
         INC( I );
      END;

   DEC( I );

   GetInt := N;

END   (* GetInt *);

(* ------------------------------------------------------------------------ *)

BEGIN (* PibPlay *)
                                   (* Append blank to end of music string *)
   S := S + ' ';
                                   (* Point to first character in music *)
   I := 1;
                                   (* BEGIN loop over music string *)
   WHILE( I < LENGTH( S ) ) DO

      BEGIN (* Interpret Music *)
                                   (* Get next character in music string *)
         C := UpCase(S[I]);
                                   (* Interpret it                       *)
         CASE C OF

            'A'..'G' : BEGIN (* A Note *)

                          N         := Note_Offset[ C ];

                          Play_Freq := Freq[ Note_Octave , N ];

                          XN := Note_Quarter * ( Note_Length / Quarter_Note );

                          Play_Duration := TRUNC( XN * Note_Fraction );

                          Rest_Duration := TRUNC( XN * ( 1.0 - Note_Fraction ) );

                                   (* Check for sharp/flat *)

                          IF S[I+1] IN ['#','+','-' ] THEN
                             BEGIN

                                INC( I );

                                CASE S[I] OF
                                   '#',
                                   '+' : Play_Freq :=
                                            Freq[ Note_Octave , SUCC( N ) ];
                                   '-' : Play_Freq :=
                                            Freq[ Note_Octave , PRED( N ) ];
                                   ELSE  ;
                                END (* Case *);

                             END;

                                   (* Check for note length *)

                          IF ( S[I+1] IN Digits ) THEN
                             BEGIN

                                INC( I );
                                N  := GetInt;
                                XN := ( 1.0 / N ) / Quarter_Note;

                                Play_Duration :=
                                    TRUNC( Note_Fraction * Note_Quarter * XN );

                                Rest_Duration :=
                                   TRUNC( ( 1.0 - Note_Fraction ) *
                                          Xn * Note_Quarter );

                             END;
                                   (* Check for dotting *)

                             IF S[I+1] = '.' THEN
                                BEGIN

                                   XN := 1.0;

                                   WHILE( S[I+1] = '.' ) DO
                                      BEGIN
                                         XN := XN * 1.5;
                                         INC( I );
                                      END;

                                   Play_Duration :=
                                       TRUNC( Play_Duration * XN );

                                END;

                                       (* Play the note *)

                          Sound( Play_Freq );
                          Delay( Play_Duration );
                          NoSound;
                          Delay( Rest_Duration );

                       END   (* A Note *);

            'M'      : BEGIN (* 'M' Commands *)

                          INC( I );
                          C := S[I];

                          Case C Of

                             'F' : ;
                             'B' : ;
                             'N' : Note_Fraction := 0.875;
                             'L' : Note_Fraction := 1.000;
                             'S' : Note_Fraction := 0.750;
                             ELSE ;

                          END (* Case *);


                       END   (* 'M' Commands *);

            'O'      : BEGIN (* Set Octave *)

                          INC( I );
                          N := ORD( S[I] ) - ORD('0');

                          IF ( N < 0 ) OR ( N > 6 ) THEN N := 4;

                          Note_Octave := N;

                       END   (* Set Octave *);

            '<'      : BEGIN (* Drop an octave *)

                          IF Note_Octave > 0 THEN
                             DEC( Note_Octave );

                       END   (* Drop an octave *);

            '>'      : BEGIN (* Ascend an octave *)

                          IF Note_Octave < 6 THEN
                             INC( Note_Octave );

                       END   (* Ascend an octave *);

            'N'      : BEGIN (* Play Note N *)

                          INC( I );

                          N := GetInt;

                          IF ( N > 0 ) AND ( N <= 84 ) THEN
                             BEGIN

                                Play_Freq    := Note_Freqs[ N ];

                                XN           := Note_Quarter *
                                                ( Note_Length / Quarter_Note );

                                Play_Duration := TRUNC( XN * Note_Fraction );

                                Rest_Duration := TRUNC( XN * ( 1.0 - Note_Fraction ) );

                             END

                          ELSE IF ( N = 0 ) THEN
                             BEGIN

                                Play_Freq     := 0;
                                Play_Duration := 0;
                                Rest_Duration :=
                                   TRUNC( Note_Fraction * Note_Quarter *
                                          ( Note_Length / Quarter_Note ) );

                             END;

                          Sound( Play_Freq );
                          Delay( Play_Duration );
                          NoSound;
                          Delay( Rest_Duration );

                       END   (* Play Note N *);

            'L'      : BEGIN (* Set Length of Notes *)

                          INC( I );
                          N := GetInt;

                          IF N > 0 THEN Note_Length := 1.0 / N;

                       END   (* Set Length of Notes *);

            'T'      : BEGIN (* # of quarter notes in a minute *)

                          INC( I );
                          N := GetInt;

                          Note_Quarter := ( 1092.0 / 18.2 / N ) * 1000.0;

                       END   (* # of quarter notes in a minute *);

            'P'      : BEGIN (* Pause *)

                          INC( I );
                          N := GetInt;

                          IF      ( N <  1 ) THEN N := 1
                          ELSE IF ( N > 64 ) THEN N := 64;

                          Play_Freq     := 0;
                          Play_Duration := 0;
                          Rest_Duration :=
                             TRUNC( ( ( 1.0 / N ) / Quarter_Note )
                                    * Note_Quarter );

                          Sound( Play_Freq );
                          Delay( Play_Duration );
                          NoSound;
                          Delay( Rest_Duration );

                       END   (* Pause *);

            ELSE
               (* Ignore other stuff *);

         END (* Case *);

         INC( I );

       END  (* Interpret Music *);

                                   (* Make sure sound turned off when through *)
   NoSound;

END   (* PibPlay *);
