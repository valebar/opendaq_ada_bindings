with Daq.API;

--  One-call bootstrap, mirroring the Odin/Dart examples' convention:
--  module path from the parameter, else $OPENDAQ_MODULE_PATH, else the
--  openDAQ default search behavior.
package Daq.Boot is

   function Create_Instance
     (Module_Path : String := "") return Daq.API.Instance'Class;

end Daq.Boot;
