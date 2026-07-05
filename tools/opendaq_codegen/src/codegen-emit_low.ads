with Codegen.C_Model;
with Codegen.Output;

--  Emits the thin-layer packages into opendaq_bindings/src/gen:
--    Copendaq.Types      all opaque handles + enums
--    Copendaq.Errors     DAQ_* error/status constants
--    Copendaq.Intf_IDs   DAQ_*_INTF_ID data imports (quarantined)
--    Copendaq.<Group>    imported subprograms, one package per header subdir
package Codegen.Emit_Low is

   procedure Run
     (DB      : C_Model.Database;
      Out_Dir : String;
      W       : in out Output.Writer);

end Codegen.Emit_Low;
