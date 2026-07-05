with Daq.API;

--  Shared plumbing for the examples: module-path discovery and typed nulls.
package Example_Support is

   function Default_Module_Path return String;
   --  "" when $OPENDAQ_MODULE_PATH is set (Daq.Boot reads it itself);
   --  otherwise <repo>/vendor/copendaq/lib located relative to the
   --  executable, so examples/bin/<x> runs directly.

   function No_Filter return Daq.API.Search_Filter'Class;
   function No_Config return Daq.API.Property_Object'Class;

   function Connect_By_Prefix
     (Inst   : Daq.API.Instance'Class;
      Prefix : String) return Daq.API.Device'Class;
   --  Discover available devices, print them, and connect the first whose
   --  connection string starts with Prefix ("daqref", "daq.simulator", ...).
   --  Returns a null wrapper (Is_Null) when nothing matches.

end Example_Support;
