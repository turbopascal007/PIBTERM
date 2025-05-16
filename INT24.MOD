(*----------------------------------------------------------------------*)
(* Int24 handlers -- Essentially dummies now that TP4 has them built-in *)
(*----------------------------------------------------------------------*)

PROCEDURE Int24;

BEGIN (* Int24 *)
END   (* Int24 *);

PROCEDURE Int24On;

BEGIN (* Int24On *)
END   (* Int24On *);

PROCEDURE Int24Off( Flag : BOOLEAN );

BEGIN (* Int24Off *)
END   (* Int24Off *);

FUNCTION Int24Result : INTEGER;

BEGIN (* Int24Result *)
   Int24Result := IOResult;
END   (* Int24Result *);
