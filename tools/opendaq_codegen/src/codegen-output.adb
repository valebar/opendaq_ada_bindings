with Ada.Directories;
with Ada.Streams.Stream_IO;
with Ada.Text_IO;

package body Codegen.Output is

   function Read_File (Path : String) return String is
      use Ada.Streams.Stream_IO;
      F    : File_Type;
      Size : constant Natural := Natural (Ada.Directories.Size (Path));
      S    : String (1 .. Size);
   begin
      Open (F, In_File, Path);
      String'Read (Stream (F), S);
      Close (F);
      return S;
   end Read_File;

   procedure Emit (W : in out Writer; Path : String; Content : String) is
      use Ada.Directories;
      Exists : constant Boolean := Ada.Directories.Exists (Path);
   begin
      W.Produced.Include (Simple_Name (Path));
      if Exists and then Read_File (Path) = Content then
         W.Unchanged := W.Unchanged + 1;
         return;
      end if;
      if W.Check then
         W.Drifted.Append (Path);
         return;
      end if;
      Create_Path (Containing_Directory (Path));
      declare
         use Ada.Streams.Stream_IO;
         F : File_Type;
      begin
         Create (F, Out_File, Path);
         String'Write (Stream (F), Content);
         Close (F);
      end;
      W.Written := W.Written + 1;
   end Emit;

   procedure Sweep (W : in out Writer; Dir : String) is
      use Ada.Directories;
      Search : Search_Type;
      Item   : Directory_Entry_Type;
   begin
      if not Exists (Dir) then
         return;
      end if;
      Start_Search (Search, Dir, "",
                    Filter => (Ordinary_File => True, others => False));
      while More_Entries (Search) loop
         Get_Next_Entry (Search, Item);
         declare
            Name : constant String := Simple_Name (Item);
            Ext  : constant String := Extension (Name);
         begin
            if (Ext = "ads" or else Ext = "adb")
              and then not W.Produced.Contains (Name)
            then
               if W.Check then
                  W.Drifted.Append (Full_Name (Item) & " (stale)");
               else
                  Delete_File (Full_Name (Item));
                  Ada.Text_IO.Put_Line ("  removed stale " & Name);
               end if;
            end if;
         end;
      end loop;
      End_Search (Search);
   end Sweep;

   function Has_Drift (W : Writer) return Boolean is
     (not W.Drifted.Is_Empty);

   procedure Report (W : Writer; Label : String) is
      use Ada.Text_IO;
   begin
      Put_Line (Label & ":" & W.Written'Image & " written,"
                & W.Unchanged'Image & " unchanged");
      for P of W.Drifted loop
         Put_Line ("  would change: " & P);
      end loop;
   end Report;

end Codegen.Output;
