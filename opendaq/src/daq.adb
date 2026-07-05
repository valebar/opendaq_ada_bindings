with Ada.Unchecked_Conversion;
with Interfaces.C.Strings;
with System;

with Copendaq.Core_Types;
with Copendaq.Intf_IDs;
with Copendaq.Types;

package body Daq is

   use Copendaq;
   use Copendaq.Core_Types;
   use type Interfaces.C.int;

   subtype chars_ptr is Interfaces.C.Strings.chars_ptr;

   --  Exported (unmangled) by libdaqcoretypes; pairs with the allocation
   --  daqBaseObject_toString performs. See the COPENDAQ_CORETYPES_LIB
   --  external in opendaq_bindings.gpr.
   procedure daqFreeMemory (Ptr : System.Address)
     with Import => True, Convention => C, External_Name => "daqFreeMemory";

   function To_Address is new Ada.Unchecked_Conversion
     (chars_ptr, System.Address);

   ----------------------------------------------------------------
   --  Lifetime
   ----------------------------------------------------------------

   overriding procedure Adjust (Self : in out Object) is
      Ignore : Interfaces.C.int;
   begin
      if Self.Owned and then Self.H /= Null_Object then
         Ignore := daqBaseObject_addRef (Self.H);
      end if;
   end Adjust;

   overriding procedure Finalize (Self : in out Object) is
      Ignore : Interfaces.C.int;
   begin
      if Self.Owned and then Self.H /= Null_Object then
         Ignore := daqBaseObject_releaseRef (Self.H);
      end if;
      Self.H := Null_Object;
      Self.Owned := False;
   end Finalize;

   function Is_Null (Self : Object'Class) return Boolean is
     (Self.H = Null_Object);

   function Handle (Self : Object'Class) return Copendaq.daqBaseObject is
     (Self.H);

   function Take (H : Copendaq.daqBaseObject) return Object is
   begin
      return (Ada.Finalization.Controlled with
                H => H, Owned => H /= Null_Object);
   end Take;

   function Borrow (H : Copendaq.daqBaseObject) return Object is
      Ignore : Interfaces.C.int;
   begin
      if H /= Null_Object then
         Ignore := daqBaseObject_addRef (H);
      end if;
      return (Ada.Finalization.Controlled with
                H => H, Owned => H /= Null_Object);
   end Borrow;

   function No_Object return Object is
   begin
      return (Ada.Finalization.Controlled with
                H => Null_Object, Owned => False);
   end No_Object;

   ----------------------------------------------------------------
   --  Errors
   ----------------------------------------------------------------

   function Error_Name (Code : Copendaq.daqErrCode) return String is
   begin
      case Code is
         when 16#0000_0000# => return "DAQ_SUCCESS";
         when 16#8000_0000# => return "DAQ_ERR_NOMEMORY";
         when 16#8000_0001# => return "DAQ_ERR_INVALIDPARAMETER";
         when 16#8000_4002# => return "DAQ_ERR_NOINTERFACE";
         when 16#8000_0003# => return "DAQ_ERR_SIZETOOSMALL";
         when 16#8000_0004# => return "DAQ_ERR_CONVERSIONFAILED";
         when 16#8000_0005# => return "DAQ_ERR_OUTOFRANGE";
         when 16#8000_0006# => return "DAQ_ERR_NOTFOUND";
         when 16#8000_000A# => return "DAQ_ERR_ALREADYEXISTS";
         when 16#8000_000B# => return "DAQ_ERR_NOTASSIGNED";
         when 16#8000_000C# => return "DAQ_ERR_CALLFAILED";
         when 16#8000_000D# => return "DAQ_ERR_PARSEFAILED";
         when 16#8000_000E# => return "DAQ_ERR_INVALIDVALUE";
         when 16#8000_0010# => return "DAQ_ERR_RESOLVEFAILED";
         when 16#8000_0011# => return "DAQ_ERR_INVALIDTYPE";
         when 16#8000_0012# => return "DAQ_ERR_ACCESSDENIED";
         when 16#8000_0013# => return "DAQ_ERR_NOTENABLED";
         when 16#8000_0014# => return "DAQ_ERR_GENERALERROR";
         when 16#8000_0015# => return "DAQ_ERR_CALCFAILED";
         when 16#8000_0016# => return "DAQ_ERR_NOTIMPLEMENTED";
         when 16#8000_0017# => return "DAQ_ERR_FROZEN";
         when 16#8000_0026# => return "DAQ_ERR_ARGUMENT_NULL";
         when 16#8000_0027# => return "DAQ_ERR_INVALID_OPERATION";
         when 16#8000_0028# => return "DAQ_ERR_UNINITIALIZED";
         when 16#8000_0029# => return "DAQ_ERR_INVALIDSTATE";
         when 16#8000_0033# => return "DAQ_ERR_LOCKED";
         when 16#8000_0041# => return "DAQ_ERR_NOT_SUPPORTED";
         when 16#8000_0050# => return "DAQ_ERR_NO_DATA";
         when others =>
            declare
               Hex : String (1 .. 8);
               Dig : constant String := "0123456789ABCDEF";
               V   : daqErrCode := Code;
            begin
               for I in reverse Hex'Range loop
                  Hex (I) := Dig (Natural (V and 16#F#) + 1);
                  V := V / 16;
               end loop;
               return "0x" & Hex;
            end;
      end case;
   end Error_Name;

   procedure Check (Code : Copendaq.daqErrCode; Operation : String) is
   begin
      if Failed (Code) then
         raise Opendaq_Error with Operation & ": " & Error_Name (Code);
      end if;
   end Check;

   ----------------------------------------------------------------
   --  Object services
   ----------------------------------------------------------------

   function To_String (Self : Object'Class) return String is
      P : daqCharPtr := Interfaces.C.Strings.Null_Ptr;
   begin
      if Self.Is_Null then
         return "<null>";
      end if;
      Check (daqBaseObject_toString (Self.H, P), "daqBaseObject_toString");
      declare
         S : constant String := Interfaces.C.Strings.Value (P);
      begin
         daqFreeMemory (To_Address (P));
         return S;
      end;
   end To_String;

   function Equals (A, B : Object'Class) return Boolean is
      Eq : daqBool := 0;
   begin
      Check (daqBaseObject_equals (A.H, B.H, Eq), "daqBaseObject_equals");
      return Eq /= 0;
   end Equals;

   function Hash (Self : Object'Class) return Copendaq.daqSizeT is
      H : daqSizeT := 0;
   begin
      Check (daqBaseObject_getHashCode (Self.H, H),
             "daqBaseObject_getHashCode");
      return H;
   end Hash;

   ----------------------------------------------------------------
   --  Interface queries
   ----------------------------------------------------------------

   function Query_Handle
     (From : Object'Class; Getter : Id_Getter; What : String)
      return Copendaq.daqBaseObject
   is
      ID    : daqIntfID;
      Out_H : daqBaseObject := Null_Object;
      Code  : daqErrCode;
   begin
      if From.Is_Null then
         raise Cast_Error with "cast of null object to " & What;
      end if;
      Getter (ID);
      Code := daqBaseObject_queryInterface (From.H, ID, Out_H);
      if Failed (Code) then
         raise Cast_Error with
           "object does not support " & What & " (" & Error_Name (Code) & ")";
      end if;
      return Out_H;
   end Query_Handle;

   function Supports (From : Object'Class; Getter : Id_Getter) return Boolean
   is
      ID    : daqIntfID;
      Out_H : daqBaseObject := Null_Object;
   begin
      if From.Is_Null then
         return False;
      end if;
      Getter (ID);
      return Succeeded
        (daqBaseObject_borrowInterface (From.H, ID, Out_H));
   end Supports;

   function Borrow_For
     (From : Object'Class; Id : Copendaq.daqIntfID; What : String)
      return Copendaq.daqBaseObject
   is
      Out_H : daqBaseObject := Null_Object;
      Code  : daqErrCode;
   begin
      if From.Is_Null then
         raise Cast_Error with "cast of null object to " & What;
      end if;
      Code := daqBaseObject_borrowInterface (From.H, Id, Out_H);
      if Failed (Code) then
         raise Cast_Error with
           "object does not support " & What & " (" & Error_Name (Code) & ")";
      end if;
      return Out_H;
   end Borrow_For;

   function Borrow_For
     (From : Object'Class; Getter : Id_Getter; What : String)
      return Copendaq.daqBaseObject
   is
      ID : daqIntfID;
   begin
      if From.Is_Null then
         raise Cast_Error with "cast of null object to " & What;
      end if;
      Getter (ID);
      return Borrow_For (From, ID, What);
   end Borrow_For;

   --  Borrowed (non-addRef'd) view of an interface; valid while From lives.
   function Borrow_Iface
     (From : Object'Class; Getter : Id_Getter; What : String)
      return daqBaseObject renames Borrow_For;

   ----------------------------------------------------------------
   --  Boxed values
   ----------------------------------------------------------------

   function Core_Type (Self : Object'Class) return Copendaq.daqCoreType is
      --  coretype.h ships no daqCoreType_getInterfaceId function, so this is
      --  the one place the hand-written core uses an interface-id DATA import.
      CT    : daqCoreType := daqCtUndefined;
      Out_H : daqBaseObject := Null_Object;
   begin
      if Self.Is_Null
        or else Failed
          (daqBaseObject_borrowInterface
             (Self.H, Copendaq.Intf_IDs.DAQ_CORE_TYPE_INTF_ID, Out_H))
      then
         return daqCtUndefined;
      end if;
      Check
        (daqCoreType_getCoreType
           (Copendaq.Types.daqCoreTypeObject (Out_H), CT),
         "daqCoreType_getCoreType");
      return CT;
   end Core_Type;

   function As_Boolean (Self : Object'Class) return Boolean is
      V : daqBool := 0;
   begin
      Check
        (daqBoolean_getValue
           (Copendaq.Types.daqBoolean
              (Borrow_Iface
                 (Self, daqBoolean_getInterfaceId'Access, "IBoolean")),
            V),
         "daqBoolean_getValue");
      return V /= 0;
   end As_Boolean;

   function As_Integer (Self : Object'Class) return Long_Long_Integer is
      V : daqInt := 0;
   begin
      Check
        (daqNumber_getIntValue
           (Copendaq.Types.daqNumber
              (Borrow_Iface
                 (Self, daqNumber_getInterfaceId'Access, "INumber")),
            V),
         "daqNumber_getIntValue");
      return Long_Long_Integer (V);
   end As_Integer;

   function As_Float (Self : Object'Class) return Long_Float is
      V : daqFloat := 0.0;
   begin
      Check
        (daqNumber_getFloatValue
           (Copendaq.Types.daqNumber
              (Borrow_Iface
                 (Self, daqNumber_getInterfaceId'Access, "INumber")),
            V),
         "daqNumber_getFloatValue");
      return Long_Float (V);
   end As_Float;

   function As_String (Self : Object'Class) return String is
      P : daqConstCharPtr := Interfaces.C.Strings.Null_Ptr;
   begin
      if Supports (Self, daqString_getInterfaceId'Access) then
         Check
           (daqString_getCharPtr
              (Copendaq.Types.daqString
                 (Borrow_Iface
                    (Self, daqString_getInterfaceId'Access, "IString")),
               P),
            "daqString_getCharPtr");
         return Interfaces.C.Strings.Value (P);
      else
         return To_String (Self);
      end if;
   end As_String;

   function To_Daq (Value : Boolean) return Object'Class is
      H : Copendaq.Types.daqBoolean;
   begin
      Check (daqBoolean_createBoolean (H, (if Value then 1 else 0)),
             "daqBoolean_createBoolean");
      return Take (daqBaseObject (H));
   end To_Daq;

   function To_Daq (Value : Long_Long_Integer) return Object'Class is
      H : Copendaq.Types.daqInteger;
   begin
      Check (daqInteger_createInteger (H, daqInt (Value)),
             "daqInteger_createInteger");
      return Take (daqBaseObject (H));
   end To_Daq;

   function To_Daq (Value : Long_Float) return Object'Class is
      H : Copendaq.Types.daqFloatObject;
   begin
      Check (daqFloatObject_createFloat (H, daqFloat (Value)),
             "daqFloatObject_createFloat");
      return Take (daqBaseObject (H));
   end To_Daq;

   function To_Daq (Value : String) return Object'Class is
   begin
      return Take (New_String_Handle (Value));
   end To_Daq;

   ----------------------------------------------------------------
   --  daqString helpers
   ----------------------------------------------------------------

   function From_Daq_String_Handle
     (H : Copendaq.daqBaseObject) return String
   is
      P      : daqConstCharPtr := Interfaces.C.Strings.Null_Ptr;
      Handle : daqBaseObject := H;
   begin
      if H = Null_Object then
         return "";
      end if;
      declare
         Code : constant daqErrCode :=
           daqString_getCharPtr (Copendaq.Types.daqString (H), P);
      begin
         if Failed (Code) then
            Release_Handle (Handle);
            Check (Code, "daqString_getCharPtr");
         end if;
      end;
      declare
         S : constant String := Interfaces.C.Strings.Value (P);
      begin
         Release_Handle (Handle);
         return S;
      end;
   end From_Daq_String_Handle;

   function New_String_Handle (S : String) return Copendaq.daqBaseObject is
      use Interfaces.C.Strings;
      C : chars_ptr := New_String (S);
      H : Copendaq.Types.daqString;
      Code : daqErrCode;
   begin
      Code := daqString_createString (H, C);
      Free (C);
      Check (Code, "daqString_createString");
      return daqBaseObject (H);
   end New_String_Handle;

   procedure Release_Handle (H : in out Copendaq.daqBaseObject) is
      Ignore : Interfaces.C.int;
   begin
      if H /= Null_Object then
         Ignore := daqBaseObject_releaseRef (H);
         H := Null_Object;
      end if;
   end Release_Handle;

end Daq;
