with Daq.Lists;

--  Calling IFunction / IProcedure property values (e.g. the simulator
--  device's "Protected.Sum"). openDAQ's calling convention for the params
--  argument: null for no arguments, the object itself for one argument, an
--  IList for several.
package Daq.Functions is

   --  The multi-argument variants carry distinct names (not overloads):
   --  a List is itself an Object'Class, so "Call (F, My_List)" would be
   --  ambiguous between "one list argument" and "these arguments".

   function Call (Func : Daq.Object'Class) return Daq.Object'Class;
   function Call
     (Func : Daq.Object'Class; Arg : Daq.Object'Class)
      return Daq.Object'Class;
   function Call_List
     (Func : Daq.Object'Class; Args : Daq.Lists.List'Class)
      return Daq.Object'Class;

   procedure Execute (Proc : Daq.Object'Class);
   procedure Execute (Proc : Daq.Object'Class; Arg : Daq.Object'Class);
   procedure Execute_List
     (Proc : Daq.Object'Class; Args : Daq.Lists.List'Class);

end Daq.Functions;
