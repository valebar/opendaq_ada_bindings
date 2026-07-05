with Codegen.C_Model;

--  Deterministic file writing: content is rendered in memory, compared with
--  what's on disk, and written only on change (stable mtimes). In check mode
--  nothing is written; drift is recorded instead. Sweep removes stale
--  generated files that this run did not produce.
package Codegen.Output is

   type Writer is limited record
      Check     : Boolean := False;
      Written   : Natural := 0;
      Unchanged : Natural := 0;
      Drifted   : C_Model.String_Vectors.Vector;  --  paths that would change
      Produced  : C_Model.String_Sets.Set;        --  simple names produced
   end record;

   procedure Emit (W : in out Writer; Path : String; Content : String);

   --  Delete (or, in check mode, report) *.ads/*.adb in Dir not produced
   --  by this run.
   procedure Sweep (W : in out Writer; Dir : String);

   function Has_Drift (W : Writer) return Boolean;
   procedure Report (W : Writer; Label : String);

end Codegen.Output;
