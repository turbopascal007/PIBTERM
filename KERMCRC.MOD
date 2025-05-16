(*----------------------------------------------------------------------*)
(*       Kermit_Chk8 --- Compute 6-bit checksum for sector in Kermit    *)
(*----------------------------------------------------------------------*)

PROCEDURE Kermit_Chk8( VAR Sector        ;
                           Sector_Length : INTEGER;
                       VAR CheckSum      : INTEGER  );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function: Kermit_Chk8                                            *)
(*                                                                      *)
(*     Purpose:  Computes 8-bit checksum for Kermit type 1 block check  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Checksum := Kermit_Chk8( VAR Sector ;                         *)
(*                                     Sector_Length : INTEGER;         *)
(*                                 VAR CheckSum      : INTEGER  );      *)
(*                                                                      *)
(*           Sector        --- data for which to compute checksum       *)
(*           Sector_Length --- length of Sector in bytes                *)
(*           Checksum      --- computed checksum                        *)
(*                                                                      *)
(*     Calls:    None                                                   *)
(*                                                                      *)
(*     Remarks:  In Pascal one could write the body of this procedure   *)
(*               as follows:                                            *)
(*                                                                      *)
(*                  CheckSum := 0;                                      *)
(*                                                                      *)
(*                  FOR I := 1 TO Sector_Length DO                      *)
(*                     CheckSum := ( CheckSum + Sector[I] ) AND 255;    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Kermit_Chk8 *)

INLINE(
  $1E                    {          PUSH   DS                       ;Save DS}
                         {;}
  /$31/$D2               {          XOR    DX,DX                    ;Accumulates checksum}
  /$31/$C0               {          XOR    AX,AX                    ;Clear byte holder}
  /$8B/$8E/>SECTOR_LENGTH{          MOV    CX,[BP+>Sector_Length]   ;Get sector length}
  /$C5/$B6/>SECTOR       {          LDS    SI,[BP+>Sector]          ;Get sector address}
  /$BB/$FF/$00           {          MOV    BX,255                   ;1 byte checksum}
  /$FC                   {          CLD                             ;March forward}
                         {;}
  /$AC                   {Chk8:     LODSB                           ;Get next byte in sector}
  /$01/$C2               {          ADD    DX,AX                    ;Add next byte to checksum}
  /$21/$DA               {          AND    DX,BX                    ;Mask out high-order checksum bits}
  /$E2/$F9               {          LOOP   Chk8}
                         {;}
  /$C4/$BE/>CHECKSUM     {          LES    DI,[BP+>CheckSum]        ;Get result address}
  /$26/$89/$15           {      ES: MOV    [DI],DX                  ;Move checksum to function result}
                         {;}
  /$1F                   {          POP    DS                       ;Restore DS}
);

END   (* Kermit_Chk8 *);

(*----------------------------------------------------------------------*)
(*       Kermit_Chk12 --- Compute 12-bit checksum for sector in Kermit  *)
(*----------------------------------------------------------------------*)

PROCEDURE Kermit_Chk12( VAR Sector        ;
                            Sector_Length : INTEGER;
                        VAR CheckSum      : INTEGER  );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Kermit_Chk12                                          *)
(*                                                                      *)
(*     Purpose:   Computes 12-bit checksum for Kermit type2 block check *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Checksum := Kermit_Chk12( VAR Sector ;                        *)
(*                                      Sector_Length : INTEGER;        *)
(*                                  VAR CheckSum      : INTEGER  );     *)
(*                                                                      *)
(*           Sector        --- data for which to compute checksum       *)
(*           Sector_Length --- length of Sector in bytes                *)
(*           Checksum      --- computed checksum                        *)
(*                                                                      *)
(*     Calls:    None                                                   *)
(*                                                                      *)
(*     Remarks:  In Pascal one could write the body of this procedure   *)
(*               as follows:                                            *)
(*                                                                      *)
(*                  CheckSum := 0;                                      *)
(*                                                                      *)
(*                  FOR I := 1 TO Sector_Length DO                      *)
(*                     CheckSum := ( CheckSum + Sector[I] ) AND 4095;   *)
(*                                                                      *)
(*                  Kermit_Chk12 := CheckSum;                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Kermit_Chk12 *)

INLINE(
  $1E                    {          PUSH   DS                       ;Save DS}
                         {;}
  /$31/$C0               {          XOR    AX,AX                    ;Gets bytes in sector}
  /$31/$D2               {          XOR    DX,DX                    ;Accumulates checksum}
  /$8B/$8E/>SECTOR_LENGTH{          MOV    CX,[BP+>Sector_Length]   ;Get sector length}
  /$C5/$B6/>SECTOR       {          LDS    SI,[BP+>Sector]          ;Get sector address}
  /$BB/$FF/$0F           {          MOV    BX,4095                  ;1 byte checksum}
  /$FC                   {          CLD                             ;March forward}
                         {;}
  /$AC                   {Chk12:    LODSB                           ;Get next byte in sector}
  /$01/$C2               {          ADD    DX,AX                    ;Add next byte to checksum}
  /$21/$DA               {          AND    DX,BX                    ;Mask out high-order checksum bits}
  /$E2/$F9               {          LOOP   Chk12}
                         {;}
  /$C4/$BE/>CHECKSUM     {          LES    DI,[BP+>CheckSum]        ;Get result address}
  /$26/$89/$15           {      ES: MOV    [DI],DX                  ;Move answer to function result}
                         {;}
  /$1F                   {          POP    DS                       ;Restore DS}
);

END   (* Kermit_Chk12 *);

(*----------------------------------------------------------------------*)
(*       Kermit_CRC --- Compute cyclic redundancy check for Kermit      *)
(*----------------------------------------------------------------------*)

PROCEDURE Kermit_CRC( VAR Sector        ;
                          Sector_Length : INTEGER;
                      VAR CRC           : INTEGER  );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Kermit_CRC                                            *)
(*                                                                      *)
(*     Purpose:   Computes 16-bit CRC for Kermit type 3 block check     *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Kermit_CRC( VAR Sector        ;                               *)
(*                        Sector_Length : INTEGER;                      *)
(*                    VAR CRC           : INTEGER  );                   *)
(*                                                                      *)
(*           Sector        --- data for which to compute CRC            *)
(*           Sector_Length --- length of Sector in bytes                *)
(*           CRC           --- computed CRC                             *)
(*                                                                      *)
(*     Calls:    None                                                   *)
(*                                                                      *)
(*     Remarks:  In Pascal one could write the body of this procedure   *)
(*               as follows:                                            *)
(*                                                                      *)
(*                  Crc := 0;                                           *)
(*                                                                      *)
(*                  FOR I := 1 TO Sector_Length DO                      *)
(*                     BEGIN                                            *)
(*                        C     := Sector[I] XOR LO( Crc );             *)
(*                        CSave := ( C AND $F0 ) SHR 4;                 *)
(*                        C     := C AND $0F;                           *)
(*                        Crc   := ( Crc SHR 8 ) XOR                    *)
(*                                 ( CrcTab[ CSave ] XOR CrcTab2[ C ] );*)
(*                     END;                                             *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

CONST
   CrcTab:  ARRAY[0..15] OF WORD
            = ( $0000, $1081, $2102, $3183, $4204, $5285, $6306, $7387,
                $8408, $9489, $A50A, $B58B, $C60C, $D68D, $E70E, $F78F  );

   CrcTab2: ARRAY[0..15] OF WORD
            = ( $0000, $1189, $2312, $329B, $4624, $57AD, $6536, $74BF,
                $8C48, $9DC1, $AF5A, $BED3, $CA6C, $DBE5, $E97E, $F8F7  );

BEGIN (* Kermit_CRC *)

INLINE(
  $1E/                    {          PUSH   DS                       ;Save DS}
  $07/                    {          POP    ES                       ;DS to ES}
  $06/                    {          PUSH   ES}
                          {;}
  $31/$D2/                {          XOR    DX,DX                    ;Accumulates CRC}
  $8B/$8E/>SECTOR_LENGTH/ {          MOV    CX,[BP+>Sector_Length]   ;Get sector length}
  $C5/$B6/>SECTOR/        {          LDS    SI,[BP+>Sector]          ;Get sector address}
  $FC/                    {          CLD                             ;March forward}
                          {;}
  $51/                    {Crc1:     PUSH   CX                       ;Save loop counter}
                          {;}
  $AC/                    {          LODSB                           ;Get next byte in sector}
                          {;}
  $30/$D0/                {          XOR    AL,DL                    ;C = B XOR LO( Crc )}
  $88/$C3/                {          MOV    BL,AL                    ;CSave := C}
  $81/$E3/$F0/$00/        {          AND    BX,$F0                   ;Csave := ( CSAve AND $F0 )}
  $D0/$EB/                {          SHR    BL,1                     ;  ... SHR 1}
  $D0/$EB/                {          SHR    BL,1                     ;  ... SHR 2}
  $D0/$EB/                {          SHR    BL,1                     ;  ... SHR 3}
  $25/$0F/$00/            {          AND    AX,$0F                   ;C     := C AND $0F}
  $D0/$E0/                {          SHL    AL,1}
  $B1/$08/                {          MOV    CL,8}
  $D3/$EA/                {          SHR    DX,CL                    ;CRC := ( CRC SHR 8 ) ...}
  $8D/$3E/>CRCTAB/        {          LEA    DI,[>CrcTab]}
  $01/$DF/                {          ADD    DI,BX}
  $26/$8B/$1D/            {      ES: MOV    BX,[DI]                  ;CrcTab[ CSave ]}
  $8D/$3E/>CRCTAB2/       {          LEA    DI,[>CrcTab2]}
  $01/$C7/                {          ADD    DI,AX}
  $26/$8B/$05/            {      ES: MOV    AX,[DI]                  ;CrcTab2[ C ]}
  $31/$D8/                {          XOR    AX,BX}
  $31/$C2/                {          XOR    DX,AX}
                          {;}
  $59/                    {          POP    CX                       ;Restore loop counter}
  $E2/$CE/                {          LOOP   Crc1                     ;Go back if sector not done yet}
                          {;}
  $C4/$BE/>CRC/           {          LES    DI,[BP+>Crc]             ;Pick up return address}
  $26/$89/$15/            {      ES: MOV    [DI],DX                  ;Store result}
                          {;}
  $1F);                   {          POP    DS                       ;Restore DS}

END   (* Kermit_CRC *);

