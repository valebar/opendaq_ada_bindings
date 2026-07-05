with Copendaq.Core_Types;
with Copendaq.Types;

package body Daq.Lists is

   use Copendaq;
   use Copendaq.Core_Types;

   function Self_H (Self : List) return Copendaq.Types.daqList is
     (Copendaq.Types.daqList (Handle (Self)));

   function Create return List is
      H : Copendaq.Types.daqList;
   begin
      Check (daqList_createList (H), "daqList_createList");
      return Take (daqBaseObject (H));  --  List's inherited Take
   end Create;

   function Count (Self : List) return Natural is
      N : daqSizeT := 0;
   begin
      if Self.Is_Null then
         return 0;
      end if;
      Check (daqList_getCount (Self_H (Self), N), "daqList_getCount");
      return Natural (N);
   end Count;

   function Element (Self : List; Index : Natural) return Daq.Object is
      Out_H : daqBaseObject := Null_Object;
   begin
      Check (daqList_getItemAt (Self_H (Self), daqSizeT (Index), Out_H),
             "daqList_getItemAt");
      return Daq.Take (Out_H);
   end Element;

   procedure Append (Self : List; Item : Daq.Object'Class) is
   begin
      Check (daqList_pushBack (Self_H (Self), Handle (Item)),
             "daqList_pushBack");
   end Append;

end Daq.Lists;
