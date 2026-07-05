with Copendaq.Core_Types;
with Copendaq.Types;

package body Daq.Dicts is

   use Copendaq;
   use Copendaq.Core_Types;

   function Self_H (Self : Dict) return Copendaq.Types.daqDict is
     (Copendaq.Types.daqDict (Handle (Self)));

   function Create return Dict is
      H : Copendaq.Types.daqDict;
   begin
      Check (daqDict_createDict (H), "daqDict_createDict");
      return Take (daqBaseObject (H));  --  Dict's inherited Take
   end Create;

   function Count (Self : Dict) return Natural is
      N : daqSizeT := 0;
   begin
      if Self.Is_Null then
         return 0;
      end if;
      Check (daqDict_getCount (Self_H (Self), N), "daqDict_getCount");
      return Natural (N);
   end Count;

   function Get (Self : Dict; Key : Daq.Object'Class) return Daq.Object is
      Out_H : daqBaseObject := Null_Object;
   begin
      Check (daqDict_get (Self_H (Self), Handle (Key), Out_H),
             "daqDict_get");
      return Daq.Take (Out_H);
   end Get;

   function Get (Self : Dict; Key : String) return Daq.Object is
   begin
      return Get (Self, Daq.To_Daq (Key));
   end Get;

   procedure Set (Self : Dict; Key, Value : Daq.Object'Class) is
   begin
      Check (daqDict_set (Self_H (Self), Handle (Key), Handle (Value)),
             "daqDict_set");
   end Set;

   procedure Set (Self : Dict; Key : String; Value : Daq.Object'Class) is
   begin
      Set (Self, Daq.To_Daq (Key), Value);
   end Set;

   function Has_Key (Self : Dict; Key : String) return Boolean is
      B : daqBool := 0;
      K : constant Daq.Object'Class := Daq.To_Daq (Key);
   begin
      Check (daqDict_hasKey (Self_H (Self), Handle (K), B),
             "daqDict_hasKey");
      return B /= 0;
   end Has_Key;

   function Keys (Self : Dict) return Daq.Lists.List is
      Out_H : Copendaq.Types.daqList;
   begin
      Check (daqDict_getKeyList (Self_H (Self), Out_H),
             "daqDict_getKeyList");
      return Daq.Lists.Take (daqBaseObject (Out_H));
   end Keys;

   function Values (Self : Dict) return Daq.Lists.List is
      Out_H : Copendaq.Types.daqList;
   begin
      Check (daqDict_getValueList (Self_H (Self), Out_H),
             "daqDict_getValueList");
      return Daq.Lists.Take (daqBaseObject (Out_H));
   end Values;

end Daq.Dicts;
