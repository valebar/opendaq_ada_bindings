--  Name mangling shared by both emitters: Ada reserved-word handling,
--  camelCase -> Ada_Mixed_Case (high level), collision checks.
package Codegen.Names is

   --  True for any Ada 2022 reserved word (case-insensitive).
   function Is_Reserved (Name : String) return Boolean;

   --  Parameter name made safe for Ada: "" -> ArgN, reserved -> Name_P.
   function Sanitize_Param (Name : String; Position : Positive) return String;

   --  camelCase / PascalCase -> Ada_Mixed_Case: "getSymbolicName" ->
   --  "Get_Symbolic_Name", "localID" -> "Local_ID".
   function To_Ada_Case (Name : String) return String;

end Codegen.Names;
