with Interfaces;
with Interfaces.C;
with Interfaces.C.Strings;
with System;

--  Hand-written prelude of the thin openDAQ bindings: the base types of the
--  copendaq C ABI, mirroring bindings/c/include/ccommon.h. Everything else
--  (handles, enums, imported subprograms) is generated into src/gen by
--  tools/opendaq_codegen.
--
--  Naming deliberately keeps the exact C identifiers (daqErrCode, daqSignal,
--  daqString_createString, ...) so the four openDAQ binding code bases
--  (C/Dart/Odin/Ada) stay grep-compatible.
package Copendaq is

   --  Scalars ---------------------------------------------------------------

   type daqErrCode is new Interfaces.Unsigned_32;
   --  Bit 31 set = failure (see DAQ_FAILED in ccoretypes/errors.h).

   type daqBool is new Interfaces.Unsigned_8;
   --  C: uint8_t. Deliberately NOT Ada Boolean.

   type daqInt is new Interfaces.Integer_64;
   type daqUInt is new Interfaces.Unsigned_64;
   type daqFloat is new Interfaces.IEEE_Float_64;
   type daqSizeT is new Interfaces.C.size_t;
   type daqEnumType is new Interfaces.Unsigned_32;

   daqTrue  : constant daqBool := 1;
   daqFalse : constant daqBool := 0;

   function Failed (Code : daqErrCode) return Boolean is
     ((Code and 16#8000_0000#) /= 0);
   function Succeeded (Code : daqErrCode) return Boolean is
     (not Failed (Code));

   --  Pointers --------------------------------------------------------------

   subtype daqCharPtr is Interfaces.C.Strings.chars_ptr;
   subtype daqConstCharPtr is Interfaces.C.Strings.chars_ptr;
   subtype daqVoidPtr is System.Address;

   --  Object handles: an Ada handle value is the C interface POINTER
   --  (typedef void daqBaseObject; used as daqBaseObject*). Every interface
   --  handle in Copendaq.Types derives from daqBaseObject, so explicit
   --  conversions in both directions are legal.
   type daqBaseObject is new System.Address;

   Null_Object : constant daqBaseObject :=
     daqBaseObject (System.Null_Address);

   function Is_Null (H : daqBaseObject) return Boolean is
     (H = Null_Object);

   --  Interface id (compacted COM GUID: Data4 is a single uint64_t).
   --  C_Pass_By_Copy is load-bearing: daqBaseObject_queryInterface takes
   --  daqIntfID BY VALUE; a plain Convention C record would be passed as a
   --  pointer per RM B.3(71).
   type daqIntfID is record
      Data1 : Interfaces.Unsigned_32 := 0;
      Data2 : Interfaces.Unsigned_16 := 0;
      Data3 : Interfaces.Unsigned_16 := 0;
      Data4 : Interfaces.Unsigned_64 := 0;
   end record
     with Convention => C_Pass_By_Copy;

   --  Callbacks (NO user-data pointer — see the high-level trampoline pool).

   type daqFuncCall is access function
     (Params : daqBaseObject; Result : access daqBaseObject)
      return daqErrCode
     with Convention => C;

   type daqProcCall is access function
     (Params : daqBaseObject) return daqErrCode
     with Convention => C;

   type daqEventCall is access procedure
     (Sender : daqBaseObject; Args : daqBaseObject)
     with Convention => C;

   --  Enums from ccommon.h --------------------------------------------------

   type daqCoreType is
     (daqCtBool,
      daqCtInt,
      daqCtFloat,
      daqCtString,
      daqCtList,
      daqCtDict,
      daqCtRatio,
      daqCtProc,
      daqCtObject,
      daqCtBinaryData,
      daqCtFunc,
      daqCtComplexNumber,
      daqCtStruct,
      daqCtEnumeration,
      daqCtUndefined);
   for daqCoreType use
     (daqCtBool          => 0,
      daqCtInt           => 1,
      daqCtFloat         => 2,
      daqCtString        => 3,
      daqCtList          => 4,
      daqCtDict          => 5,
      daqCtRatio         => 6,
      daqCtProc          => 7,
      daqCtObject        => 8,
      daqCtBinaryData    => 9,
      daqCtFunc          => 10,
      daqCtComplexNumber => 11,
      daqCtStruct        => 12,
      daqCtEnumeration   => 13,
      daqCtUndefined     => 16#FFFF#);
   for daqCoreType'Size use 32;
   pragma Convention (C, daqCoreType);

   type daqLockingStrategy is
     (daqOwnLock,
      daqInheritLock,
      daqForwardOwnerLockOwn);
   for daqLockingStrategy'Size use 32;
   pragma Convention (C, daqLockingStrategy);

end Copendaq;
