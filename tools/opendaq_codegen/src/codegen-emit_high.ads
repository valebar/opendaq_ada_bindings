with Codegen.C_Model;
with Codegen.Output;

--  Emits the thick-layer package (Daq.API) into opendaq/src/gen from the
--  RTGen JSON model, reconciled against the parsed C headers and the
--  exported-symbol list.
package Codegen.Emit_High is

   procedure Run
     (DB   : C_Model.Database;
      Opts : Options;
      W    : in out Output.Writer);

end Codegen.Emit_High;
