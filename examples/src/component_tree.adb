with Ada.Command_Line;
with Ada.Strings.Fixed;
with Ada.Text_IO;

with Daq;      use Daq;
with Daq.API;  use Daq.API;
with Daq.Boot;

with Example_Support; use Example_Support;

--  Walk the component tree, printing each component's name and kind plus
--  its visible properties (name, value type, current value).
procedure Component_Tree is
   use Ada.Text_IO;

   Nodes : Natural := 0;

   function Kind_Of (C : Component'Class) return String is
   begin
      --  Most-derived first.
      if Is_Channel (C) then
         return "Channel";
      elsif Is_Device (C) then
         return "Device";
      elsif Is_Function_Block (C) then
         return "FunctionBlock";
      elsif Is_Signal (C) then
         return "Signal";
      elsif Is_Input_Port (C) then
         return "InputPort";
      elsif Is_Folder (C) then
         return "Folder";
      else
         return "Component";
      end if;
   end Kind_Of;

   function Value_Image
     (C : Component'Class; Property_Name : String) return String is
   begin
      return To_String (C.Get_Property_Value (Property_Name));
   exception
      when others =>
         return "<unreadable>";
   end Value_Image;

   procedure Print_Properties (C : Component'Class; Indent : String) is
   begin
      for P of C.Get_Visible_Properties loop
         declare
            Prop : constant Property'Class := As_Property (P);
            Name : constant String := Prop.Get_Name;
         begin
            Put_Line (Indent & "  - " & Name & " : "
                      & Prop.Get_Value_Type'Image & " = "
                      & Value_Image (C, Name));
         end;
      end loop;
   end Print_Properties;

   procedure Walk (C : Component'Class; Depth : Natural) is
      Indent : constant String := Ada.Strings.Fixed."*" (2 * Depth, ' ');
   begin
      Nodes := Nodes + 1;
      Put_Line (Indent & C.Get_Name & ": " & Kind_Of (C));
      Print_Properties (C, Indent);
      if Is_Folder (C) then
         for Item of As_Folder (C).Get_Items (No_Filter) loop
            Walk (As_Component (Item), Depth + 1);
         end loop;
      end if;
   end Walk;

   Inst : constant Instance'Class :=
     Daq.Boot.Create_Instance (Default_Module_Path);
   Dev  : constant Device'Class := Connect_By_Prefix (Inst, "daqref");
begin
   if Dev.Is_Null then
      Put_Line ("component_tree: FAIL - no daqref device");
      Ada.Command_Line.Set_Exit_Status (1);
      return;
   end if;

   Walk (Dev, 0);

   Put_Line ("component_tree:" & Nodes'Image & " components");
   if Nodes > 1 then
      Put_Line ("component_tree: OK");
   else
      Put_Line ("component_tree: FAIL - tree did not expand");
      Ada.Command_Line.Set_Exit_Status (1);
   end if;
end Component_Tree;
