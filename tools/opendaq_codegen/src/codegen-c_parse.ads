with Codegen.C_Model;

--  Parses the copendaq C headers (RTGen-machine-generated, hence very
--  regular) into Codegen.C_Model.Database: strip comments and preprocessor
--  lines, join, split on ';', then pattern-match statements.
package Codegen.C_Parse is

   procedure Load
     (Headers_Dir : String;
      DB          : out C_Model.Database;
      Verbose     : Boolean := False);

end Codegen.C_Parse;
