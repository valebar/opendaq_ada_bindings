with Ada.Command_Line;
with Ada.Exceptions;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Codegen;
with Codegen.C_Model;
with Codegen.C_Parse;
with Codegen.Emit_Low;
with Codegen.Emit_High;
with Codegen.Output;

--  opendaq_codegen <gen-low|gen-high|all|check> [options]
--
--  Options: --headers-dir DIR  --model-dir DIR  --low-out DIR  --high-out DIR
--           --symbols FILE     --check          --verbose
--
--  Exit codes: 0 ok, 1 error, 2 --check drift.
procedure Opendaq_Codegen is
   use Ada.Command_Line;
   use Ada.Text_IO;
   use Ada.Strings.Unbounded;
   use Codegen;

   Opts    : Options := Defaults;
   Command : Unbounded_String := To_Unbounded_String ("all");

   procedure Parse_Args is
      I : Positive := 1;

      function Value_Of (Flag : String; Arg : String) return String is
         --  supports "--flag=value" and "--flag value"
         Eq : constant Natural := Ada.Strings.Fixed.Index (Arg, "=");
      begin
         if Eq /= 0 then
            return Arg (Eq + 1 .. Arg'Last);
         end if;
         I := I + 1;
         if I > Argument_Count then
            raise Program_Error with "missing value for " & Flag;
         end if;
         return Argument (I);
      end Value_Of;

      function Is_Flag (Arg, Name : String) return Boolean is
        (Arg = Name
         or else (Arg'Length > Name'Length
                  and then Arg (Arg'First .. Arg'First + Name'Length - 1) =
                           Name
                  and then Arg (Arg'First + Name'Length) = '='));
   begin
      while I <= Argument_Count loop
         declare
            Arg : constant String := Argument (I);
         begin
            if Is_Flag (Arg, "--headers-dir") then
               Opts.Headers_Dir := +Value_Of ("--headers-dir", Arg);
            elsif Is_Flag (Arg, "--model-dir") then
               Opts.Model_Dir := +Value_Of ("--model-dir", Arg);
            elsif Is_Flag (Arg, "--low-out") then
               Opts.Low_Out := +Value_Of ("--low-out", Arg);
            elsif Is_Flag (Arg, "--high-out") then
               Opts.High_Out := +Value_Of ("--high-out", Arg);
            elsif Is_Flag (Arg, "--symbols") then
               Opts.Symbols := +Value_Of ("--symbols", Arg);
            elsif Arg = "--check" then
               Opts.Check := True;
            elsif Arg = "--verbose" then
               Opts.Verbose := True;
            elsif Arg'Length > 0 and then Arg (Arg'First) /= '-' then
               Command := To_Unbounded_String (Arg);
            else
               raise Program_Error with "unknown option: " & Arg;
            end if;
         end;
         I := I + 1;
      end loop;
   end Parse_Args;

   DB : Codegen.C_Model.Database;
   W  : Codegen.Output.Writer;

   Do_Low, Do_High : Boolean := False;
begin
   Parse_Args;

   declare
      Cmd : constant String := To_String (Command);
   begin
      if Cmd = "gen-low" then
         Do_Low := True;
      elsif Cmd = "gen-high" then
         Do_High := True;
      elsif Cmd = "all" then
         Do_Low := True;
         Do_High := True;
      elsif Cmd = "check" then
         Do_Low := True;
         Do_High := True;
         Opts.Check := True;
      else
         Put_Line (Standard_Error, "unknown command: " & Cmd);
         Set_Exit_Status (1);
         return;
      end if;
   end;

   W.Check := Opts.Check;

   --  Both halves need the parsed C headers (the high half reconciles the
   --  model against real C symbols).
   Codegen.C_Parse.Load (-Opts.Headers_Dir, DB, Opts.Verbose);
   Put_Line ("parsed:" & DB.Opaques.Length'Image & " opaque types,"
             & DB.Enums.Length'Image & " enums,"
             & DB.Procs.Length'Image & " procedures,"
             & DB.Intf_Ids.Length'Image & " interface ids,"
             & DB.Consts.Length'Image & " constants");

   if Do_Low then
      Codegen.Emit_Low.Run (DB, -Opts.Low_Out, W);
      Codegen.Output.Report (W, "gen-low");
   end if;

   if Do_High then
      Codegen.Emit_High.Run (DB, Opts, W);
   end if;

   if Codegen.Output.Has_Drift (W) then
      Put_Line ("check: generated code is out of date; run ./daq gen");
      Set_Exit_Status (2);
   end if;

exception
   when E : others =>
      Put_Line (Standard_Error,
                "error: " & Ada.Exceptions.Exception_Message (E));
      Set_Exit_Status (1);
end Opendaq_Codegen;
