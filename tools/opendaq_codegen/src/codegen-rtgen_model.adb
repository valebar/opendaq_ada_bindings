with Ada.Directories;
with Ada.Text_IO;

with JSON.Parsers;
with JSON.Types;

with Codegen.C_Model;

package body Codegen.RTGen_Model is

   package Types is new JSON.Types (Long_Integer, Long_Float);
   package Parsers is new JSON.Parsers (Types);

   procedure Load
     (Model_Dir  : String;
      Interfaces : out Interface_Vectors.Vector;
      Verbose    : Boolean := False)
   is
      use Ada.Directories;
      use Types;

      Files : C_Model.String_Vectors.Vector;
      Seen  : C_Model.String_Sets.Set;

      procedure Collect is
         Search : Search_Type;
         Item   : Directory_Entry_Type;
      begin
         Start_Search (Search, Model_Dir, "*.json",
                       Filter => (Ordinary_File => True, others => False));
         while More_Entries (Search) loop
            Get_Next_Entry (Search, Item);
            Files.Append (Full_Name (Item));
         end loop;
         End_Search (Search);
      end Collect;

      package Sorting is new
        C_Model.String_Vectors.Generic_Sorting ("<" => "<");

      procedure Load_File (Path : String) is
         Parser : Parsers.Parser :=
           Parsers.Create_From_File (Path, Maximum_Depth => 128);
         Root   : constant JSON_Value := Parser.Parse;
      begin
         if not Root.Contains ("Classes") then
            return;
         end if;
         declare
            Classes : constant JSON_Value := Root.Get ("Classes");
         begin
            for I in 1 .. Classes.Length loop
               declare
                  C    : constant JSON_Value := Classes.Get (I);
                  T    : constant JSON_Value := C.Get ("Type");
                  Name : constant String :=
                    T.Get ("NonInterfaceName").Value;
                  Base : Unbounded_String;
               begin
                  if C.Contains ("BaseType")
                    and then C.Get ("BaseType").Kind = Object_Kind
                    and then C.Get ("BaseType").Contains ("NonInterfaceName")
                  then
                     Base := +String'
                       (C.Get ("BaseType").Get ("NonInterfaceName").Value);
                  end if;
                  if not Seen.Contains (Name) then
                     Seen.Include (Name);
                     Interfaces.Append
                       (Interface_Info'(Name => +Name, Base => Base));
                  end if;
               end;
            end loop;
         end;
      exception
         when others =>
            Ada.Text_IO.Put_Line
              ("rtgen_model: WARNING could not parse " & Path);
      end Load_File;

   begin
      Interfaces.Clear;
      Collect;
      Sorting.Sort (Files);
      for F of Files loop
         Load_File (F);
      end loop;
      if Verbose then
         Ada.Text_IO.Put_Line
           ("rtgen_model:" & Interfaces.Length'Image & " interfaces");
      end if;
   end Load;

end Codegen.RTGen_Model;
