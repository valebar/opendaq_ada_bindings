--  Hand-maintained tables driving both emitters (the analogue of the Dart
--  codegen's type_map.dart + target list). The generator is rebuilt on every
--  run, so tables live in code, not in a data file.
package Codegen.Config is

   --  Types defined by hand in opendaq_bindings/src/copendaq.ads; never
   --  regenerated (mirrors the Odin bindgen's PRELUDE_TYPES).
   type Prelude_Kind is
     (Not_Prelude,
      Handle,          --  daqBaseObject: Ada value IS the C pointer
      Scalar,          --  daqErrCode, daqBool, daqInt, ... passed by value
      Pointer_Alias,   --  daqCharPtr/daqConstCharPtr/daqVoidPtr: already pointers
      Record_Type,     --  daqIntfID
      Enum_Type,       --  daqCoreType, daqLockingStrategy
      Callback);       --  daqFuncCall, daqProcCall, daqEventCall

   function Prelude_Kind_Of (Name : String) return Prelude_Kind;

   --  Headers that only aggregate or re-declare prelude content.
   function Skip_Header (Simple_Name : String) return Boolean;

   --  Header subdirectory -> generated child package of Copendaq.
   --  Empty string = unknown group (generator error).
   function Package_For_Group (Group : String) return String;

   --  Fixed emission order of the function packages (determinism).
   function Group_Count return Positive;
   function Group_Dir (I : Positive) return String;      --  e.g. "copendaq/signal"

   --  Raw C base types that can appear without a daq* typedef.
   --  Returns "" when unknown.
   function Map_C_Base (T : String) return String;

end Codegen.Config;
