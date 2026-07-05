with Ada.Text_IO;

with Daq.API;
with Daq.Dicts;

package body Core_Event_Handler is

   use Daq;
   use Daq.API;

   Count : Natural := 0 with Atomic;

   procedure Handle (Sender, Args : Daq.Object) is
      use Ada.Text_IO;
   begin
      Put_Line ("  ---- core event");
      if Is_Component (Sender) then
         Put_Line ("  sender => " & As_Component (Sender).Get_Name);
      end if;
      if Is_Core_Event_Args (Args) then
         declare
            E      : constant Core_Event_Args'Class :=
              As_Core_Event_Args (Args);
            Params : constant Daq.Dicts.Dict := E.Get_Parameters;
         begin
            Put_Line ("  event  => " & E.Get_Event_Name);
            if Params.Has_Key ("Name") then
               Put_Line ("  name   => "
                         & As_String (Params.Get ("Name")));
            end if;
            if Params.Has_Key ("Value") then
               Put_Line ("  value  => "
                         & As_String (Params.Get ("Value")));
            end if;
         end;
      end if;
      Count := Count + 1;
   exception
      when others =>
         null;  --  never propagate out of an event callback
   end Handle;

   function Events_Seen return Natural is (Count);

end Core_Event_Handler;
