with Ada.Containers.Vectors;

--  Minimal typed view over the committed RTGen JSON model (model/*.json).
--
--  The C headers are the ABI ground truth; the ONLY facts the JSON model
--  contributes are which interfaces exist and their inheritance (BaseType) —
--  the one thing the flat C headers cannot express.
package Codegen.RTGen_Model is

   type Interface_Info is record
      Name : Unbounded_String;  --  NonInterfaceName, e.g. "SignalConfig"
      Base : Unbounded_String;  --  base NonInterfaceName, "" for none
   end record;

   package Interface_Vectors is new
     Ada.Containers.Vectors (Positive, Interface_Info);

   procedure Load
     (Model_Dir  : String;
      Interfaces : out Interface_Vectors.Vector;
      Verbose    : Boolean := False);
   --  Loads every model/*.json (sorted), collecting one Interface_Info per
   --  class. Duplicate names keep the first occurrence.

end Codegen.RTGen_Model;
