with Ada.Characters.Handling; use Ada.Characters.Handling;

package body Codegen.Names is

   Reserved : constant array (Positive range <>) of Unbounded_String :=
     (+"abort", +"abs", +"abstract", +"accept", +"access", +"aliased",
      +"all", +"and", +"array", +"at", +"begin", +"body", +"case",
      +"constant", +"declare", +"delay", +"delta", +"digits", +"do",
      +"else", +"elsif", +"end", +"entry", +"exception", +"exit", +"for",
      +"function", +"generic", +"goto", +"if", +"in", +"interface", +"is",
      +"limited", +"loop", +"mod", +"new", +"not", +"null", +"of", +"or",
      +"others", +"out", +"overriding", +"package", +"parallel", +"pragma",
      +"private", +"procedure", +"protected", +"raise", +"range", +"record",
      +"rem", +"renames", +"requeue", +"return", +"reverse", +"select",
      +"separate", +"some", +"subtype", +"synchronized", +"tagged",
      +"task", +"terminate", +"then", +"type", +"until", +"use", +"when",
      +"while", +"with", +"xor");

   function Is_Reserved (Name : String) return Boolean is
      L : constant String := To_Lower (Name);
   begin
      for R of Reserved loop
         if -R = L then
            return True;
         end if;
      end loop;
      return False;
   end Is_Reserved;

   function Sanitize_Param (Name : String; Position : Positive) return String is
   begin
      if Name = "" then
         declare
            Img : constant String := Position'Image;
         begin
            return "Arg" & Img (Img'First + 1 .. Img'Last);
         end;
      elsif Is_Reserved (Name) then
         return Name & "_P";
      elsif Name (Name'Last) = '_' then
         --  e.g. C's keyword-dodging "struct_" — Ada forbids a trailing '_'
         return Name & "P";
      elsif Name (Name'First) = '_' then
         return "P" & Name;
      else
         return Name;
      end if;
   end Sanitize_Param;

   function To_Ada_Case (Name : String) return String is
      Result : Unbounded_String;
      Prev_Lower_Or_Digit : Boolean := False;
   begin
      for I in Name'Range loop
         declare
            C : constant Character := Name (I);
         begin
            if C = '_' then
               Append (Result, '_');
               Prev_Lower_Or_Digit := False;
            else
               if Is_Upper (C) and then Prev_Lower_Or_Digit then
                  Append (Result, '_');
               end if;
               if Length (Result) = 0
                 or else Element (Result, Length (Result)) = '_'
               then
                  Append (Result, To_Upper (C));
               else
                  Append (Result, C);
               end if;
               Prev_Lower_Or_Digit := Is_Lower (C) or else Is_Digit (C);
            end if;
         end;
      end loop;
      declare
         S : constant String := -Result;
      begin
         if Is_Reserved (S) then
            return S & "_X";
         end if;
         return S;
      end;
   end To_Ada_Case;

end Codegen.Names;
