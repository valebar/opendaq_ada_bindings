with Ada.Containers.Indefinite_Vectors;
with Ada.Containers.Indefinite_Ordered_Maps;
with Ada.Containers.Indefinite_Ordered_Sets;
with Ada.Containers.Vectors;
with Interfaces;

--  Plain data model filled by Codegen.C_Parse from the copendaq headers.
package Codegen.C_Model is

   package String_Vectors is new
     Ada.Containers.Indefinite_Vectors (Positive, String);
   package String_Sets is new
     Ada.Containers.Indefinite_Ordered_Sets (String);
   package String_Maps is new
     Ada.Containers.Indefinite_Ordered_Maps (String, String);

   use type Interfaces.Unsigned_32;
   package Value_Maps is new
     Ada.Containers.Indefinite_Ordered_Maps (String, Interfaces.Unsigned_32);

   type Param is record
      Name   : Unbounded_String;  --  C parameter name, unsanitized ("" if absent)
      C_Type : Unbounded_String;  --  base type token(s), qualifiers stripped
      Ptr    : Natural := 0;      --  pointer depth
   end record;
   package Param_Vectors is new Ada.Containers.Vectors (Positive, Param);

   type Proc_Decl is record
      Name   : Unbounded_String;
      Group  : Unbounded_String;  --  header subdir: "ccoretypes", "copendaq/signal", ...
      Ret    : Unbounded_String;  --  base return type, "" for void
      Params : Param_Vectors.Vector;
   end record;
   package Proc_Vectors is new Ada.Containers.Vectors (Positive, Proc_Decl);

   type Enum_Member is record
      Name  : Unbounded_String;
      Value : Interfaces.Unsigned_32 := 0;
   end record;
   package Member_Vectors is new Ada.Containers.Vectors (Positive, Enum_Member);

   type Enum_Decl is record
      Name       : Unbounded_String;
      Members    : Member_Vectors.Vector;
      Resolved   : Boolean := True;  --  every member value numerically known
      Enumerable : Boolean := True;  --  strictly increasing & distinct values
                                     --  (an Ada enum rep clause is possible)
   end record;
   package Enum_Vectors is new Ada.Containers.Vectors (Positive, Enum_Decl);

   type Const_Decl is record
      Name  : Unbounded_String;
      Value : Interfaces.Unsigned_32 := 0;
   end record;
   package Const_Vectors is new Ada.Containers.Vectors (Positive, Const_Decl);

   type Database is record
      Opaques      : String_Vectors.Vector;  --  first-seen order
      Enums        : Enum_Vectors.Vector;
      Consts       : Const_Vectors.Vector;
      Intf_Ids     : String_Vectors.Vector;
      Procs        : Proc_Vectors.Vector;

      Known_Opaque : String_Sets.Set;        --  opaque typedefs (+ daqBaseObject)
      Known_Enums  : String_Sets.Set;        --  non-prelude enums, by name
      Seen         : String_Sets.Set;        --  emitted symbol names (dedup)
      Defines      : String_Maps.Map;        --  #define NAME TOKEN
      Int_Defines  : Value_Maps.Map;         --  integer-valued #defines
      Const_Seen   : String_Sets.Set;
      Unmapped     : String_Sets.Set;        --  base types we could not map
   end record;

end Codegen.C_Model;
