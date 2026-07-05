with Ada.Directories;
with Ada.Direct_IO;
with Ada.Strings.Fixed;
with Ada.Text_IO;
with Interfaces;

with Codegen.Config;
with Codegen.Names;

package body Codegen.C_Parse is

   use C_Model;
   use type Interfaces.Unsigned_32;
   use type Config.Prelude_Kind;

   subtype U32 is Interfaces.Unsigned_32;

   ----------------------------------------------------------------
   --  File reading
   ----------------------------------------------------------------

   function Read_File (Path : String) return String is
      package Char_IO is new Ada.Direct_IO (Character);
      use Char_IO;
      Size : constant Natural :=
        Natural (Ada.Directories.Size (Path));
      F      : Char_IO.File_Type;
      Result : String (1 .. Size);
      C      : Character;
   begin
      Open (F, In_File, Path);
      for I in Result'Range loop
         Read (F, C);
         Result (I) := C;
      end loop;
      Close (F);
      return Result;
   exception
      when others =>
         if Is_Open (F) then
            Close (F);
         end if;
         raise;
   end Read_File;

   ----------------------------------------------------------------
   --  Cleaning helpers (ports of strip_comments / normalize_ws)
   ----------------------------------------------------------------

   function Strip_Comments (S : String) return String is
      B : Unbounded_String;
      I : Natural := S'First;
   begin
      while I <= S'Last loop
         if I < S'Last and then S (I) = '/' and then S (I + 1) = '*' then
            I := I + 2;
            while I < S'Last
              and then not (S (I) = '*' and then S (I + 1) = '/')
            loop
               I := I + 1;
            end loop;
            I := I + 2;
            Append (B, ' ');
         elsif I < S'Last and then S (I) = '/' and then S (I + 1) = '/' then
            while I <= S'Last and then S (I) /= ASCII.LF loop
               I := I + 1;
            end loop;
         else
            Append (B, S (I));
            I := I + 1;
         end if;
      end loop;
      return -B;
   end Strip_Comments;

   function Normalize_WS (S : String) return String is
      B          : Unbounded_String;
      Prev_Space : Boolean := False;
   begin
      for C of S loop
         if C = ' ' or else C = ASCII.HT
           or else C = ASCII.LF or else C = ASCII.CR
         then
            if not Prev_Space then
               Append (B, ' ');
            end if;
            Prev_Space := True;
         else
            Append (B, C);
            Prev_Space := False;
         end if;
      end loop;
      declare
         R     : constant String := -B;
         First : Natural := R'First;
         Last  : Natural := R'Last;
      begin
         while First <= Last and then R (First) = ' ' loop
            First := First + 1;
         end loop;
         while Last >= First and then R (Last) = ' ' loop
            Last := Last - 1;
         end loop;
         return R (First .. Last);
      end;
   end Normalize_WS;

   function Trim (S : String) return String is
     (Ada.Strings.Fixed.Trim (S, Ada.Strings.Both));

   function Starts_With (S, Prefix : String) return Boolean is
     (S'Length >= Prefix'Length
      and then S (S'First .. S'First + Prefix'Length - 1) = Prefix);

   function Is_Ident_Char (C : Character) return Boolean is
     (C = '_' or else C in 'a' .. 'z' or else C in 'A' .. 'Z'
      or else C in '0' .. '9');

   --  Strip a leading qualifier word ("const", "struct", "enum").
   function Strip_Word (S, Word : String) return String is
      Cur : Unbounded_String := +S;
   begin
      loop
         declare
            T : constant String := -Cur;
         begin
            if Starts_With (T, Word & " ") then
               Cur := +Trim (T (T'First + Word'Length .. T'Last));
            elsif T = Word then
               return "";
            else
               return T;
            end if;
         end;
      end loop;
   end Strip_Word;

   ----------------------------------------------------------------
   --  Statement splitting (port of statements_of)
   ----------------------------------------------------------------

   procedure For_Each_Statement
     (Path    : String;
      Process : not null access procedure (Stmt : String))
   is
      Clean  : constant String := Strip_Comments (Read_File (Path));
      Joined : Unbounded_String;
   begin
      --  Drop preprocessor lines and the C++ linkage line; join the rest.
      declare
         Line_Start : Natural := Clean'First;
      begin
         for I in Clean'First .. Clean'Last + 1 loop
            if I > Clean'Last or else Clean (I) = ASCII.LF then
               declare
                  Line : constant String :=
                    Trim (Clean (Line_Start .. I - 1));
               begin
                  if Line /= ""
                    and then Line (Line'First) /= '#'
                    and then not Starts_With (Line, "extern ""C""")
                  then
                     Append (Joined, Line);
                     Append (Joined, ' ');
                  end if;
               end;
               Line_Start := I + 1;
            end if;
         end loop;
      end;

      --  Split on ';', trim leading extern-"C" braces.
      declare
         J     : constant String := -Joined;
         Start : Natural := J'First;
      begin
         for I in J'First .. J'Last + 1 loop
            if I > J'Last or else J (I) = ';' then
               declare
                  Raw  : constant String := Normalize_WS (J (Start .. I - 1));
                  From : Natural := Raw'First;
               begin
                  while From <= Raw'Last
                    and then (Raw (From) = '{' or else Raw (From) = '}'
                              or else Raw (From) = ' ')
                  loop
                     From := From + 1;
                  end loop;
                  if From <= Raw'Last then
                     Process (Raw (From .. Raw'Last));
                  end if;
               end;
               Start := I + 1;
            end if;
         end loop;
      end;
   end For_Each_Statement;

   ----------------------------------------------------------------
   --  #define collection & C integer literals
   ----------------------------------------------------------------

   function Parse_C_Uint (Tok : String; Value : out U32) return Boolean is
      S : Unbounded_String := +Trim (Tok);
   begin
      Value := 0;
      --  strip wrapping parentheses
      loop
         declare
            T : constant String := -S;
         begin
            exit when T'Length < 2
              or else T (T'First) /= '('
              or else T (T'Last) /= ')';
            S := +Trim (T (T'First + 1 .. T'Last - 1));
         end;
      end loop;
      declare
         T    : String := -S;
         Last : Natural := T'Last;
         Base : U32 := 10;
         Frst : Natural := T'First;
      begin
         while Last >= Frst
           and then (T (Last) in 'u' | 'U' | 'l' | 'L')
         loop
            Last := Last - 1;
         end loop;
         if Last < Frst then
            return False;
         end if;
         if Last - Frst >= 1
           and then T (Frst) = '0'
           and then (T (Frst + 1) = 'x' or else T (Frst + 1) = 'X')
         then
            Base := 16;
            Frst := Frst + 2;
         end if;
         if Last < Frst then
            return False;
         end if;
         for I in Frst .. Last loop
            declare
               C : constant Character := T (I);
               D : U32;
            begin
               case C is
                  when '0' .. '9' =>
                     D := Character'Pos (C) - Character'Pos ('0');
                  when 'a' .. 'f' =>
                     D := Character'Pos (C) - Character'Pos ('a') + 10;
                  when 'A' .. 'F' =>
                     D := Character'Pos (C) - Character'Pos ('A') + 10;
                  when others =>
                     return False;
               end case;
               if D >= Base then
                  return False;
               end if;
               Value := Value * Base + D;
            end;
         end loop;
         return True;
      end;
   end Parse_C_Uint;

   procedure For_Each_Define
     (Path    : String;
      Process : not null access procedure (Name, Rest : String))
   is
      Clean      : constant String := Strip_Comments (Read_File (Path));
      Line_Start : Natural := Clean'First;
   begin
      for I in Clean'First .. Clean'Last + 1 loop
         if I > Clean'Last or else Clean (I) = ASCII.LF then
            declare
               Line : constant String := Trim (Clean (Line_Start .. I - 1));
            begin
               if Starts_With (Line, "#define ") then
                  declare
                     Decl : constant String :=
                       Trim (Line (Line'First + 8 .. Line'Last));
                     J : Natural := Decl'First;
                  begin
                     while J <= Decl'Last
                       and then Is_Ident_Char (Decl (J))
                     loop
                        J := J + 1;
                     end loop;
                     --  '(' directly after the name => function-like: skip
                     if J > Decl'First
                       and then (J > Decl'Last or else Decl (J) /= '(')
                     then
                        Process
                          (Decl (Decl'First .. J - 1),
                           Normalize_WS (Decl (J .. Decl'Last)));
                     end if;
                  end;
               end if;
            end;
            Line_Start := I + 1;
         end if;
      end loop;
   end For_Each_Define;

   function Eval_Error_Code
     (DB : Database; Expr : String; Value : out U32) return Boolean
   is
      Open_P  : constant Natural :=
        Ada.Strings.Fixed.Index (Expr, "(");
      Close_P : constant Natural :=
        Ada.Strings.Fixed.Index (Expr, ")", Going => Ada.Strings.Backward);
      Comma   : Natural := 0;
      Type_Id, Code : U32;
   begin
      Value := 0;
      if Open_P = 0 or else Close_P = 0 or else Close_P < Open_P then
         return False;
      end if;
      for I in Open_P + 1 .. Close_P - 1 loop
         if Expr (I) = ',' then
            Comma := I;
            exit;
         end if;
      end loop;
      if Comma = 0 then
         return False;
      end if;
      declare
         Type_Tok : constant String := Trim (Expr (Open_P + 1 .. Comma - 1));
         Code_Tok : constant String := Trim (Expr (Comma + 1 .. Close_P - 1));
      begin
         if not Parse_C_Uint (Type_Tok, Type_Id) then
            if DB.Int_Defines.Contains (Type_Tok) then
               Type_Id := DB.Int_Defines.Element (Type_Tok);
            else
               return False;
            end if;
         end if;
         if not Parse_C_Uint (Code_Tok, Code) then
            return False;
         end if;
         Value := 16#8000_0000#
           or Interfaces.Shift_Left (Type_Id, 16) or Code;
         return True;
      end;
   end Eval_Error_Code;

   ----------------------------------------------------------------
   --  Header discovery
   ----------------------------------------------------------------

   procedure Collect_Headers
     (Dir : String; Out_Paths : in out String_Vectors.Vector)
   is
      use Ada.Directories;
      Search : Search_Type;
      Item   : Directory_Entry_Type;
   begin
      Start_Search (Search, Dir, "",
                    Filter => (Directory => True, Ordinary_File => True,
                               others => False));
      while More_Entries (Search) loop
         Get_Next_Entry (Search, Item);
         declare
            Name : constant String := Simple_Name (Item);
            Full : constant String := Full_Name (Item);
         begin
            if Kind (Item) = Directory then
               if Name /= "." and then Name /= ".."
                 and then Name /= "private"
               then
                  Collect_Headers (Full, Out_Paths);
               end if;
            elsif Name'Length > 2
              and then Name (Name'Last - 1 .. Name'Last) = ".h"
              and then not Config.Skip_Header (Name)
            then
               Out_Paths.Append (Full);
            end if;
         end;
      end loop;
      End_Search (Search);
   end Collect_Headers;

   --  Sort paths for deterministic output.
   procedure Sort_Paths (V : in out String_Vectors.Vector) is
      package Sorting is new String_Vectors.Generic_Sorting ("<" => "<");
   begin
      Sorting.Sort (V);
   end Sort_Paths;

   ----------------------------------------------------------------
   --  Statement handlers
   ----------------------------------------------------------------

   --  "typedef struct daqString daqString" (no braces) -> name
   function Opaque_Struct_Name (Stmt : String; Name : out Unbounded_String)
     return Boolean
   is
   begin
      Name := Null_Unbounded_String;
      if Ada.Strings.Fixed.Index (Stmt, "{") /= 0 then
         return False;
      end if;
      --  last blank-separated token
      declare
         Last_Space : Natural := 0;
         Fields     : Natural := 1;
      begin
         for I in Stmt'Range loop
            if Stmt (I) = ' ' then
               Last_Space := I;
               Fields := Fields + 1;
            end if;
         end loop;
         if Fields >= 4 and then Last_Space > 0 then
            Name := +Stmt (Last_Space + 1 .. Stmt'Last);
            return True;
         end if;
         return False;
      end;
   end Opaque_Struct_Name;

   procedure Split_Params
     (S : String; Process : not null access procedure (P : String))
   is
      Depth : Integer := 0;
      Start : Natural := S'First;
   begin
      for I in S'First .. S'Last + 1 loop
         if I > S'Last then
            declare
               P : constant String := Trim (S (Start .. S'Last));
            begin
               if P /= "" then
                  Process (P);
               end if;
            end;
         else
            case S (I) is
               when '(' => Depth := Depth + 1;
               when ')' => Depth := Depth - 1;
               when ',' =>
                  if Depth = 0 then
                     declare
                        P : constant String := Trim (S (Start .. I - 1));
                     begin
                        if P /= "" then
                           Process (P);
                        end if;
                     end;
                     Start := I + 1;
                  end if;
               when others => null;
            end case;
         end if;
      end loop;
   end Split_Params;

   --  Split "const daqString* self" into base type + ptr depth + name.
   procedure Parse_Param (DB : in out Database; Raw : String; P : out Param) is
      Decl : constant String := Trim (Raw);
      Name_First : Natural := Decl'Last + 1;
      Type_Last  : Natural := Decl'Last;
   begin
      P := (Name => Null_Unbounded_String,
            C_Type => Null_Unbounded_String, Ptr => 0);
      --  Trailing identifier = parameter name (if a type remains before it).
      declare
         I : Natural := Decl'Last;
      begin
         while I >= Decl'First and then Is_Ident_Char (Decl (I)) loop
            I := I - 1;
         end loop;
         if I < Decl'Last and then I >= Decl'First
           and then Decl (I + 1) not in '0' .. '9'
         then
            Name_First := I + 1;
            Type_Last  := I;
         end if;
      end;

      declare
         Type_Str : Unbounded_String :=
           +Trim (Decl (Decl'First .. Type_Last));
      begin
         if Name_First <= Decl'Last then
            P.Name := +Decl (Name_First .. Decl'Last);
         end if;
         --  Count/strip '*'
         loop
            declare
               T : constant String := -Type_Str;
            begin
               exit when T'Length = 0 or else T (T'Last) /= '*';
               P.Ptr := P.Ptr + 1;
               Type_Str := +Trim (T (T'First .. T'Last - 1));
            end;
         end loop;
         declare
            T : String := Strip_Word (-Type_Str, "const");
         begin
            T := Strip_Word (T, "struct");
            T := Strip_Word (T, "enum");
            --  a const can also follow the base type (int const *)
            T := Trim (T);
            P.C_Type := +T;
            if T = "" then
               DB.Unmapped.Include ("<empty>");
            end if;
         end;
      end;
   end Parse_Param;

   ----------------------------------------------------------------
   --  Load
   ----------------------------------------------------------------

   procedure Load
     (Headers_Dir : String;
      DB          : out C_Model.Database;
      Verbose     : Boolean := False)
   is
      Headers : String_Vectors.Vector;

      --  Group (header subdir) of the file currently being parsed.
      Current_Group : Unbounded_String;

      procedure Note_Define (Name, Rest : String) is
      begin
         declare
            F : Natural := Rest'First;
            L : Natural := Rest'Last;
         begin
            --  single-token bodies only
            declare
               T : constant String := Trim (Rest (F .. L));
            begin
               if T /= ""
                 and then Ada.Strings.Fixed.Index (T, " ") = 0
                 and then not DB.Defines.Contains (Name)
               then
                  DB.Defines.Insert (Name, T);
               end if;
            end;
         end;
      end Note_Define;

      procedure Note_Int_Define (Name, Rest : String) is
         V : U32;
      begin
         if Parse_C_Uint (Rest, V)
           and then not DB.Int_Defines.Contains (Name)
         then
            DB.Int_Defines.Insert (Name, V);
         end if;
      end Note_Int_Define;

      procedure Note_Constant (Name, Rest : String) is
         V  : U32;
         OK : Boolean := False;
      begin
         if not Starts_With (Name, "DAQ_")
           or else DB.Const_Seen.Contains (Name)
         then
            return;
         end if;
         if Parse_C_Uint (Rest, V) then
            OK := True;
         elsif Starts_With (Rest, "DAQ_ERROR_CODE(")
           or else Starts_With (Rest, "DAQ_ERROR_CODE (")
         then
            OK := Eval_Error_Code (DB, Rest, V);
         end if;
         if OK then
            DB.Const_Seen.Insert (Name);
            DB.Consts.Append (Const_Decl'(Name => +Name, Value => V));
         end if;
      end Note_Constant;

      procedure Discover_Types (Stmt : String) is
         Name : Unbounded_String;
      begin
         if Starts_With (Stmt, "typedef struct ") then
            if Opaque_Struct_Name (Stmt, Name) then
               DB.Known_Opaque.Include (-Name);
            end if;
         elsif Starts_With (Stmt, "typedef enum ") then
            declare
               Close_B : constant Natural :=
                 Ada.Strings.Fixed.Index
                   (Stmt, "}", Going => Ada.Strings.Backward);
            begin
               if Close_B /= 0 and then Close_B < Stmt'Last then
                  declare
                     Tail : constant String :=
                       Normalize_WS (Stmt (Close_B + 1 .. Stmt'Last));
                  begin
                     if Tail /= ""
                       and then Config.Prelude_Kind_Of (Tail) =
                                Config.Not_Prelude
                     then
                        DB.Known_Enums.Include (Tail);
                     end if;
                  end;
               end if;
            end;
         end if;
      end Discover_Types;

      procedure Handle_Enum (Stmt : String) is
         Open_B  : constant Natural := Ada.Strings.Fixed.Index (Stmt, "{");
         Close_B : constant Natural :=
           Ada.Strings.Fixed.Index (Stmt, "}", Going => Ada.Strings.Backward);
      begin
         if Open_B = 0 or else Close_B = 0 or else Close_B < Open_B
           or else Close_B >= Stmt'Last
         then
            return;
         end if;
         declare
            Name : constant String :=
              Normalize_WS (Stmt (Close_B + 1 .. Stmt'Last));
            Decl : Enum_Decl;
            Next_Implicit : U32 := 0;
            Prev : U32 := 0;
            Have_Prev : Boolean := False;
         begin
            if Name = ""
              or else Config.Prelude_Kind_Of (Name) /= Config.Not_Prelude
              or else DB.Seen.Contains (Name)
            then
               return;
            end if;
            Decl.Name := +Name;

            declare
               Body_S : constant String := Stmt (Open_B + 1 .. Close_B - 1);
               Start  : Natural := Body_S'First;

               procedure Add_Member (Entry_S : String) is
                  M  : Enum_Member;
                  Eq : Natural := 0;
               begin
                  if Entry_S = "" then
                     return;
                  end if;
                  for I in Entry_S'Range loop
                     if Entry_S (I) = '=' then
                        Eq := I;
                        exit;
                     end if;
                  end loop;
                  if Eq /= 0 then
                     M.Name := +Trim (Entry_S (Entry_S'First .. Eq - 1));
                     declare
                        Val : Unbounded_String :=
                          +Trim (Entry_S (Eq + 1 .. Entry_S'Last));
                        V   : U32;
                     begin
                        if DB.Defines.Contains (-Val) then
                           Val := +DB.Defines.Element (-Val);
                        end if;
                        if Parse_C_Uint (-Val, V) then
                           M.Value := V;
                        else
                           Decl.Resolved := False;
                        end if;
                     end;
                  else
                     M.Name := +Entry_S;
                     M.Value := Next_Implicit;
                  end if;
                  Next_Implicit := M.Value + 1;
                  if Have_Prev and then M.Value <= Prev then
                     Decl.Enumerable := False;
                  end if;
                  Prev := M.Value;
                  Have_Prev := True;
                  Decl.Members.Append (M);
               end Add_Member;

            begin
               for I in Body_S'First .. Body_S'Last + 1 loop
                  if I > Body_S'Last or else Body_S (I) = ',' then
                     Add_Member (Trim (Body_S (Start .. I - 1)));
                     Start := I + 1;
                  end if;
               end loop;
            end;

            if not Decl.Resolved then
               Decl.Enumerable := False;
            end if;
            DB.Seen.Insert (Name);
            DB.Enums.Append (Decl);
         end;
      end Handle_Enum;

      procedure Handle_Proc (Stmt : String) is
         Open_P  : constant Natural := Ada.Strings.Fixed.Index (Stmt, "(");
         Close_P : constant Natural :=
           Ada.Strings.Fixed.Index (Stmt, ")", Going => Ada.Strings.Backward);
      begin
         if Open_P = 0 or else Close_P = 0 or else Close_P < Open_P then
            return;
         end if;
         declare
            Head : constant String :=
              Normalize_WS (Stmt (Stmt'First .. Open_P - 1));
            Exp  : constant Natural :=
              Ada.Strings.Fixed.Index (Head, "EXPORTED");
         begin
            if Exp = 0 then
               return;
            end if;
            declare
               Ret_Part  : constant String :=
                 Trim (Head (Head'First .. Exp - 1));
               Name_Part : constant String :=
                 Trim (Head (Exp + 8 .. Head'Last));
               Name_Str  : Unbounded_String;
            begin
               if Ret_Part = "" or else Name_Part = "" then
                  return;
               end if;
               --  name = last token of Name_Part
               declare
                  LS : Natural := 0;
               begin
                  for I in Name_Part'Range loop
                     if Name_Part (I) = ' ' then
                        LS := I;
                     end if;
                  end loop;
                  Name_Str := +Name_Part (LS + 1 .. Name_Part'Last);
               end;
               if DB.Seen.Contains (-Name_Str) then
                  return;
               end if;

               declare
                  Decl : Proc_Decl;
                  N    : Positive := 1;

                  procedure Add_Param (Raw : String) is
                     P : Param;
                  begin
                     Parse_Param (DB, Raw, P);
                     P.Name := +Names.Sanitize_Param (-P.Name, N);
                     N := N + 1;
                     Decl.Params.Append (P);
                  end Add_Param;

               begin
                  Decl.Name  := Name_Str;
                  Decl.Group := Current_Group;
                  if Ret_Part /= "void" then
                     Decl.Ret := +Ret_Part;
                  end if;
                  declare
                     Params_Str : constant String :=
                       Trim (Stmt (Open_P + 1 .. Close_P - 1));
                  begin
                     if Params_Str /= "" and then Params_Str /= "void" then
                        Split_Params (Params_Str, Add_Param'Access);
                     end if;
                  end;
                  DB.Seen.Insert (-Name_Str);
                  DB.Procs.Append (Decl);
               end;
            end;
         end;
      end Handle_Proc;

      procedure Handle_Intf_Id (Stmt : String) is
         LS : Natural := 0;
      begin
         if Ada.Strings.Fixed.Index (Stmt, "extern") = 0 then
            return;
         end if;
         for I in Stmt'Range loop
            if Stmt (I) = ' ' then
               LS := I;
            end if;
         end loop;
         declare
            Name : constant String := Stmt (LS + 1 .. Stmt'Last);
         begin
            if not DB.Seen.Contains (Name) then
               DB.Seen.Insert (Name);
               DB.Intf_Ids.Append (Name);
            end if;
         end;
      end Handle_Intf_Id;

      procedure Parse_Statement (Stmt : String) is
         Name : Unbounded_String;
      begin
         if Starts_With (Stmt, "typedef struct ") then
            if Opaque_Struct_Name (Stmt, Name)
              and then Config.Prelude_Kind_Of (-Name) = Config.Not_Prelude
              and then not DB.Seen.Contains (-Name)
            then
               DB.Seen.Insert (-Name);
               DB.Opaques.Append (-Name);
            end if;
         elsif Starts_With (Stmt, "typedef enum ") then
            Handle_Enum (Stmt);
         elsif Ada.Strings.Fixed.Index (Stmt, "EXPORTED") /= 0 then
            if Ada.Strings.Fixed.Index (Stmt, "(") /= 0 then
               Handle_Proc (Stmt);
            elsif Ada.Strings.Fixed.Index (Stmt, "daqIntfID") /= 0 then
               Handle_Intf_Id (Stmt);
            end if;
         end if;
      end Parse_Statement;

      Canon_Dir : constant String := Ada.Directories.Full_Name (Headers_Dir);

      function Group_Of (Path : String) return String is
         --  Path relative to Canon_Dir; group = containing subdir(s).
         Rel_First : constant Positive := Path'First + Canon_Dir'Length + 1;
         Last_Sep  : Natural := 0;
      begin
         for I in Rel_First .. Path'Last loop
            if Path (I) = '/' then
               Last_Sep := I;
            end if;
         end loop;
         if Last_Sep = 0 then
            return "";
         end if;
         return Path (Rel_First .. Last_Sep - 1);
      end Group_Of;

   begin
      DB := (others => <>);
      DB.Known_Opaque.Include ("daqBaseObject");

      Collect_Headers (Canon_Dir, Headers);
      Sort_Paths (Headers);
      if Headers.Is_Empty then
         raise Program_Error with
           "no headers found under " & Headers_Dir;
      end if;
      if Verbose then
         Ada.Text_IO.Put_Line
           ("c_parse: scanning" & Headers.Length'Image & " headers");
      end if;

      --  Defines & constants (three passes, like the Odin bindgen).
      for Path of Headers loop
         For_Each_Define (Path, Note_Define'Access);
      end loop;
      for Path of Headers loop
         For_Each_Define (Path, Note_Int_Define'Access);
      end loop;
      for Path of Headers loop
         For_Each_Define (Path, Note_Constant'Access);
      end loop;

      --  Types, then declarations.
      for Path of Headers loop
         For_Each_Statement (Path, Discover_Types'Access);
      end loop;
      for Path of Headers loop
         Current_Group := +Group_Of (Path);
         For_Each_Statement (Path, Parse_Statement'Access);
      end loop;
   end Load;

end Codegen.C_Parse;
