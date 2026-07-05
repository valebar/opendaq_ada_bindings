with Ada.Finalization;

with Copendaq;

--  High-level Ada API for openDAQ (root package): the hand-written core the
--  generated wrappers (Daq.API) build on.
--
--  Lifetime model: Object is a controlled, reference-counted wrapper around
--  a COM-style copendaq handle. Copying addRefs (Adjust), destruction
--  releaseRefs (Finalize) — deterministic RAII. Wrappers around the C API's
--  +1 factory results are built with Take; Borrow addRefs an existing handle.
package Daq is

   type Object is new Ada.Finalization.Controlled with private;

   Opendaq_Error : exception;  --  raised by Check on any failed daqErrCode
   Cast_Error    : exception;  --  raised by As_X casts when unsupported

   function Is_Null (Self : Object'Class) return Boolean;
   function Handle (Self : Object'Class) return Copendaq.daqBaseObject;
   --  The raw handle (escape hatch to the low-level bindings). No transfer
   --  of ownership: do not releaseRef it.

   function Take (H : Copendaq.daqBaseObject) return Object;
   --  Adopt an owned (+1) reference, e.g. a C factory / getter result.

   function Borrow (H : Copendaq.daqBaseObject) return Object;
   --  Wrap a handle we do not own: addRefs (the wrapper owns the new ref).

   function No_Object return Object;
   --  A null wrapper (Is_Null = True).

   procedure Check (Code : Copendaq.daqErrCode; Operation : String);
   --  Raises Opendaq_Error when Code carries the failure bit (bit 31).
   --  Non-failure status codes (DAQ_NOTFOUND, DAQ_LOWER, ...) pass through.

   function Error_Name (Code : Copendaq.daqErrCode) return String;
   --  Symbolic name for common codes, hex image otherwise.

   ----------------------------------------------------------------
   --  Object services (IBaseObject)
   ----------------------------------------------------------------

   function To_String (Self : Object'Class) return String;
   function Equals (A, B : Object'Class) return Boolean;
   function Hash (Self : Object'Class) return Copendaq.daqSizeT;

   ----------------------------------------------------------------
   --  Boxed values (IBoolean / IInteger / IFloat / INumber / IString)
   ----------------------------------------------------------------

   function Core_Type (Self : Object'Class) return Copendaq.daqCoreType;
   --  daqCtUndefined when the object does not expose ICoreType.

   function As_Boolean (Self : Object'Class) return Boolean;
   function As_Integer (Self : Object'Class) return Long_Long_Integer;
   function As_Float   (Self : Object'Class) return Long_Float;
   function As_String  (Self : Object'Class) return String;

   --  Class-wide results on purpose: a function returning the specific
   --  Object type would be a primitive, inherited (renamed result type) by
   --  every derived wrapper — making unqualified To_Daq calls ambiguous
   --  wherever an Object'Class is expected.
   function To_Daq (Value : Boolean) return Object'Class;
   function To_Daq (Value : Long_Long_Integer) return Object'Class;
   function To_Daq (Value : Long_Float) return Object'Class;
   function To_Daq (Value : String) return Object'Class;

   ----------------------------------------------------------------
   --  Support for generated code (public but rarely user-facing)
   ----------------------------------------------------------------

   type Id_Getter is access procedure (Id : in out Copendaq.daqIntfID)
     with Convention => C;
   --  Profile of the generated daqX_getInterfaceId imports.

   function Query_Handle
     (From : Object'Class; Getter : Id_Getter; What : String)
      return Copendaq.daqBaseObject;
   --  queryInterface: returns an owned (+1) handle; raises Cast_Error when
   --  the interface is not supported or From is null.

   function Supports (From : Object'Class; Getter : Id_Getter) return Boolean;
   --  borrowInterface probe; False for null objects.

   --  Borrowed (non-addRef'd) interface pointer, valid while From lives.
   --  Needed when a C parameter is a SPECIFIC interface (daqNumber*, ...):
   --  pointer identity only holds along the single-inheritance interface
   --  chain, and e.g. INumber is a sibling of IInteger — the pointer must
   --  come from borrowInterface, not a cast. Raises Cast_Error when the
   --  interface is unsupported or From is null.
   function Borrow_For
     (From : Object'Class; Getter : Id_Getter; What : String)
      return Copendaq.daqBaseObject;
   function Borrow_For
     (From : Object'Class; Id : Copendaq.daqIntfID; What : String)
      return Copendaq.daqBaseObject;
   --  Id-based variant for interfaces whose headers ship no
   --  daqX_getInterfaceId function (IFunction, IProcedure, ...).

   function From_Daq_String_Handle
     (H : Copendaq.daqBaseObject) return String;
   --  Content of an OWNED daqString handle; releases it (for getter results).

   function New_String_Handle (S : String) return Copendaq.daqBaseObject;
   --  New daqString (+1). Callers release with Release_Handle.

   procedure Release_Handle (H : in out Copendaq.daqBaseObject);
   --  Null-safe releaseRef; sets H to Null_Object.

private

   type Object is new Ada.Finalization.Controlled with record
      H     : Copendaq.daqBaseObject := Copendaq.Null_Object;
      Owned : Boolean := False;
   end record;

   overriding procedure Adjust (Self : in out Object);
   overriding procedure Finalize (Self : in out Object);

end Daq;
