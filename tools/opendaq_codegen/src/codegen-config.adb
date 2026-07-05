package body Codegen.Config is

   function Prelude_Kind_Of (Name : String) return Prelude_Kind is
   begin
      if Name = "daqBaseObject" then
         return Handle;
      elsif Name = "daqErrCode" or else Name = "daqBool"
        or else Name = "daqInt" or else Name = "daqUInt"
        or else Name = "daqFloat" or else Name = "daqSizeT"
        or else Name = "daqEnumType"
      then
         return Scalar;
      elsif Name = "daqCharPtr" or else Name = "daqConstCharPtr"
        or else Name = "daqVoidPtr"
      then
         return Pointer_Alias;
      elsif Name = "daqIntfID" then
         return Record_Type;
      elsif Name = "daqCoreType" or else Name = "daqLockingStrategy" then
         return Enum_Type;
      elsif Name = "daqFuncCall" or else Name = "daqProcCall"
        or else Name = "daqEventCall"
      then
         return Callback;
      else
         return Not_Prelude;
      end if;
   end Prelude_Kind_Of;

   function Skip_Header (Simple_Name : String) return Boolean is
   begin
      return Simple_Name = "copendaq.h"
        or else Simple_Name = "ccommon.h"
        or else Simple_Name = "copendaq_private.h";
   end Skip_Header;

   type Group_Row is record
      Dir : Unbounded_String;   --  header subdir relative to include root
      Pkg : Unbounded_String;   --  child package of Copendaq
   end record;

   Groups : constant array (Positive range <>) of Group_Row :=
     ((+"ccoretypes",               +"Core_Types"),
      (+"ccoreobjects",             +"Core_Objects"),
      (+"copendaq/component",       +"Component"),
      (+"copendaq/context",         +"Context"),
      (+"copendaq/device",          +"Device"),
      (+"copendaq/functionblock",   +"Function_Block"),
      (+"copendaq/logger",          +"Logger"),
      (+"copendaq/modulemanager",   +"Module_Manager"),
      (+"copendaq/opendaq",         +"SDK"),
      (+"copendaq/reader",          +"Reader"),
      (+"copendaq/scheduler",       +"Scheduler"),
      (+"copendaq/server",          +"Server"),
      (+"copendaq/signal",          +"Signal"),
      (+"copendaq/streaming",       +"Streaming"),
      (+"copendaq/synchronization", +"Synchronization"),
      (+"copendaq/utility",         +"Utility"));

   function Package_For_Group (Group : String) return String is
   begin
      for R of Groups loop
         if -R.Dir = Group then
            return -R.Pkg;
         end if;
      end loop;
      return "";
   end Package_For_Group;

   function Group_Count return Positive is (Groups'Length);
   function Group_Dir (I : Positive) return String is (-Groups (I).Dir);

   function Map_C_Base (T : String) return String is
   begin
      if T = "int" then
         return "Interfaces.C.int";
      elsif T = "unsigned" or else T = "unsigned int" then
         return "Interfaces.C.unsigned";
      elsif T = "float" then
         return "Interfaces.C.C_float";
      elsif T = "double" then
         return "Interfaces.C.double";
      elsif T = "size_t" then
         return "daqSizeT";
      elsif T = "bool" then
         return "Interfaces.C.C_bool";
      elsif T = "int8_t" then
         return "Interfaces.Integer_8";
      elsif T = "int16_t" then
         return "Interfaces.Integer_16";
      elsif T = "int32_t" then
         return "Interfaces.Integer_32";
      elsif T = "int64_t" then
         return "Interfaces.Integer_64";
      elsif T = "uint8_t" then
         return "Interfaces.Unsigned_8";
      elsif T = "uint16_t" then
         return "Interfaces.Unsigned_16";
      elsif T = "uint32_t" then
         return "Interfaces.Unsigned_32";
      elsif T = "uint64_t" then
         return "Interfaces.Unsigned_64";
      else
         return "";
      end if;
   end Map_C_Base;

end Codegen.Config;
