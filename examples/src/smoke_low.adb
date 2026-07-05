with Ada.Command_Line;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Interfaces.C;
with Interfaces.C.Strings;

with Copendaq;              use Copendaq;
with Copendaq.Types;        use Copendaq.Types;
with Copendaq.Core_Types;   use Copendaq.Core_Types;
with Copendaq.Intf_IDs;
with Copendaq.Module_Manager; use Copendaq.Module_Manager;
with Copendaq.SDK;          use Copendaq.SDK;

--  Raw low-level smoke test. Validates, layer by layer, the ABI assumptions
--  the whole binding rests on:
--    1. out-parameter passing (RM B.3: elementary out params as t*)
--    2. daqIntfID by-value passing (C_Pass_By_Copy) via queryInterface
--    3. the DAQ_*_INTF_ID data imports match daqX_getInterfaceId
--    4. COM refcounting (addRef/releaseRef return the new count)
--    5. instance creation + module enumeration (full SDK + module loading)
procedure Smoke_Low is
   use Ada.Text_IO;
   use type Interfaces.C.int;

   Failures : Natural := 0;

   procedure Check (OK : Boolean; What : String) is
   begin
      if OK then
         Put_Line ("  ok: " & What);
      else
         Put_Line ("  FAIL: " & What);
         Failures := Failures + 1;
      end if;
   end Check;

   procedure Expect (Code : daqErrCode; What : String) is
   begin
      Check (Succeeded (Code), What
             & (if Succeeded (Code) then ""
                else " (err" & Code'Image & ")"));
   end Expect;

begin
   ----------------------------------------------------------------
   Put_Line ("[1] daqString roundtrip");
   ----------------------------------------------------------------
   declare
      use Interfaces.C.Strings;
      S    : daqString;
      CS   : chars_ptr := New_String ("hello opendaq");
      P    : daqConstCharPtr := Null_Ptr;
      Len  : daqSizeT := 0;
   begin
      Expect (daqString_createString (S, CS), "createString");
      Free (CS);
      Expect (daqString_getLength (S, Len), "getLength");
      Check (Len = 13, "length = 13 (got" & Len'Image & ")");
      Expect (daqString_getCharPtr (S, P), "getCharPtr");
      Check (Value (P) = "hello opendaq", "roundtrip content");

      ----------------------------------------------------------------
      Put_Line ("[2] queryInterface with by-value daqIntfID");
      ----------------------------------------------------------------
      declare
         ID_From_Func : daqIntfID;
         Obj          : daqBaseObject := Null_Object;
      begin
         daqString_getInterfaceId (ID_From_Func);
         Check (ID_From_Func = Copendaq.Intf_IDs.DAQ_STRING_INTF_ID,
                "data import DAQ_STRING_INTF_ID = getInterfaceId ()");
         Expect (daqBaseObject_queryInterface
                   (daqBaseObject (S), ID_From_Func, Obj),
                 "queryInterface (IString)");
         Check (Obj /= Null_Object, "queryInterface returned an object");
         Check (daqBaseObject_releaseRef (Obj) >= 0, "releaseRef qi ref");
      end;

      ----------------------------------------------------------------
      Put_Line ("[3] refcounting");
      ----------------------------------------------------------------
      declare
         C1, C2 : Interfaces.C.int;
      begin
         C1 := daqBaseObject_addRef (daqBaseObject (S));
         C2 := daqBaseObject_releaseRef (daqBaseObject (S));
         Check (C1 = 2 and C2 = 1,
                "addRef -> 2, releaseRef -> 1 (got" & C1'Image & ","
                & C2'Image & ")");
      end;

      Check (daqBaseObject_releaseRef (daqBaseObject (S)) = 0,
             "final releaseRef -> 0");
   end;

   ----------------------------------------------------------------
   Put_Line ("[4] instance + modules");
   ----------------------------------------------------------------
   declare
      use Interfaces.C.Strings;
      Builder : daqInstanceBuilder;
      Inst    : daqInstance;
      Mgr     : daqModuleManager;
      Modules : daqList;
      Count   : daqSizeT := 0;
   begin
      Expect (daqInstanceBuilder_createInstanceBuilder (Builder),
              "createInstanceBuilder");

      declare
         function Module_Path return String is
            use Ada.Directories;
         begin
            if Ada.Environment_Variables.Exists ("OPENDAQ_MODULE_PATH") then
               return Ada.Environment_Variables.Value
                 ("OPENDAQ_MODULE_PATH");
            end if;
            --  Fallback for direct runs: <root>/vendor/copendaq/lib
            --  located relative to this executable (examples/bin/...).
            declare
               Exe  : constant String :=
                 Full_Name (Ada.Command_Line.Command_Name);
               Cand : constant String :=
                 Containing_Directory
                   (Containing_Directory (Containing_Directory (Exe)))
                 & "/vendor/copendaq/lib";
            begin
               return (if Exists (Cand) then Cand else "");
            end;
         end Module_Path;

         Path : constant String := Module_Path;
      begin
         if Path /= "" then
            declare
               PS : daqString;
               CP : chars_ptr := New_String (Path);
            begin
               Expect (daqString_createString (PS, CP), "path string");
               Free (CP);
               Expect (daqInstanceBuilder_setModulePath (Builder, PS),
                       "setModulePath " & Path);
               Check (daqBaseObject_releaseRef (daqBaseObject (PS)) >= 0,
                      "release path string");
            end;
         end if;
      end;

      Expect (daqInstanceBuilder_build (Builder, Inst), "build instance");
      Expect (daqInstance_getModuleManager (Inst, Mgr), "getModuleManager");
      Expect (daqModuleManager_getModules (Mgr, Modules), "getModules");
      Expect (daqList_getCount (Modules, Count), "getCount");
      Put_Line ("  modules loaded:" & Count'Image);
      Check (Count > 0, "at least one module loaded");

      for I in 0 .. Natural (Count) - 1 loop
         declare
            Module_Obj : daqBaseObject;
            Info       : daqModuleInfo;
            Name       : daqString;
            P          : daqConstCharPtr := Null_Ptr;
         begin
            Expect (daqList_getItemAt
                      (Modules, daqSizeT (I), Module_Obj),
                    "getItemAt" & I'Image);
            Expect (daqModule_getModuleInfo
                      (daqModule (Module_Obj), Info),
                    "getModuleInfo");
            Expect (daqModuleInfo_getName (Info, Name), "getName");
            Expect (daqString_getCharPtr (Name, P), "name charPtr");
            Put_Line ("    - " & Value (P));
            Check (daqBaseObject_releaseRef (daqBaseObject (Name)) >= 0,
                   "release name");
            Check (daqBaseObject_releaseRef (daqBaseObject (Info)) >= 0,
                   "release info");
            Check (daqBaseObject_releaseRef (Module_Obj) >= 0,
                   "release module");
         end;
      end loop;

      Check (daqBaseObject_releaseRef (daqBaseObject (Modules)) >= 0,
             "release modules list");
      Check (daqBaseObject_releaseRef (daqBaseObject (Mgr)) >= 0,
             "release module manager");
      Check (daqBaseObject_releaseRef (daqBaseObject (Inst)) >= 0,
             "release instance");
      Check (daqBaseObject_releaseRef (daqBaseObject (Builder)) >= 0,
             "release builder");
   end;

   New_Line;
   if Failures = 0 then
      Put_Line ("smoke_low: ALL OK");
   else
      Put_Line ("smoke_low:" & Failures'Image & " FAILURES");
      Ada.Command_Line.Set_Exit_Status (1);
   end if;
end Smoke_Low;
