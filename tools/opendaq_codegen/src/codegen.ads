with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

--  Root package of the openDAQ Ada binding generator.
--
--  Two inputs, two outputs:
--    C headers (vendor/copendaq/include)  ->  opendaq_bindings/src/gen  (thin)
--    RTGen JSON model (model/)            ->  opendaq/src/gen           (thick)
package Codegen is

   type Options is record
      Root        : Unbounded_String;
      Headers_Dir : Unbounded_String;
      Model_Dir   : Unbounded_String;
      Symbols     : Unbounded_String;  --  vendor/copendaq/symbols.txt
      Low_Out     : Unbounded_String;
      High_Out    : Unbounded_String;
      Check       : Boolean := False;
      Verbose     : Boolean := False;
   end record;

   --  Repo root: $OPENDAQ_ADA_ROOT, else three levels up from the executable
   --  (<root>/tools/opendaq_codegen/bin/opendaq_codegen).
   function Detect_Root return String;

   function Defaults return Options;

   function "+" (S : String) return Unbounded_String renames To_Unbounded_String;
   function "-" (S : Unbounded_String) return String renames To_String;

end Codegen;
