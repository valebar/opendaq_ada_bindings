with Copendaq.Core_Types;
with Copendaq.Intf_IDs;
with Copendaq.Types;

package body Daq.Functions is

   use Copendaq;
   use Copendaq.Core_Types;

   --  function.h / procedure.h ship no daqX_getInterfaceId functions, so
   --  these casts go through the interface-id data imports.

   function As_Function
     (Obj : Daq.Object'Class) return Copendaq.Types.daqFunction
   is
      Out_H : daqBaseObject := Null_Object;
   begin
      if Obj.Is_Null then
         raise Cast_Error with "null object is not an IFunction";
      end if;
      Check (daqBaseObject_borrowInterface
               (Handle (Obj), Copendaq.Intf_IDs.DAQ_FUNCTION_INTF_ID,
                Out_H),
             "borrowInterface (IFunction)");
      return Copendaq.Types.daqFunction (Out_H);
   end As_Function;

   function As_Procedure
     (Obj : Daq.Object'Class) return Copendaq.Types.daqProcedure
   is
      Out_H : daqBaseObject := Null_Object;
   begin
      if Obj.Is_Null then
         raise Cast_Error with "null object is not an IProcedure";
      end if;
      Check (daqBaseObject_borrowInterface
               (Handle (Obj), Copendaq.Intf_IDs.DAQ_PROCEDURE_INTF_ID,
                Out_H),
             "borrowInterface (IProcedure)");
      return Copendaq.Types.daqProcedure (Out_H);
   end As_Procedure;

   function Call_Raw
     (Func : Daq.Object'Class; Params : daqBaseObject)
      return Daq.Object'Class
   is
      Result : daqBaseObject := Null_Object;
   begin
      Check (daqFunction_call (As_Function (Func), Params, Result),
             "daqFunction_call");
      return Take (Result);
   end Call_Raw;

   function Call (Func : Daq.Object'Class) return Daq.Object'Class is
     (Call_Raw (Func, Null_Object));

   function Call
     (Func : Daq.Object'Class; Arg : Daq.Object'Class)
      return Daq.Object'Class is
     (Call_Raw (Func, Handle (Arg)));

   function Call_List
     (Func : Daq.Object'Class; Args : Daq.Lists.List'Class)
      return Daq.Object'Class is
     (Call_Raw (Func, Handle (Args)));

   procedure Execute_Raw (Proc : Daq.Object'Class; Params : daqBaseObject)
   is
   begin
      Check (daqProcedure_dispatch (As_Procedure (Proc), Params),
             "daqProcedure_dispatch");
   end Execute_Raw;

   procedure Execute (Proc : Daq.Object'Class) is
   begin
      Execute_Raw (Proc, Null_Object);
   end Execute;

   procedure Execute (Proc : Daq.Object'Class; Arg : Daq.Object'Class) is
   begin
      Execute_Raw (Proc, Handle (Arg));
   end Execute;

   procedure Execute_List
     (Proc : Daq.Object'Class; Args : Daq.Lists.List'Class) is
   begin
      Execute_Raw (Proc, Handle (Args));
   end Execute_List;

end Daq.Functions;
