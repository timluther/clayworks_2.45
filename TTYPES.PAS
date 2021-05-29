Unit Ttypes;
  INTERFACE
  const
  stringsize=20;

  type
  stdstring=string[stringsize];

  stringptr=^string;
  realptr=^real;
  integerptr=^integer;
  wordptr=^word;
  byteptr=^byte;

  Stringarray=^Stringarray_;
  Stringarray_=array[0..0] of stdstring;

  bytearray=^bytearray_;
  bytearray_=array[0..0] of byte;

  CharArray=^CharArray_;
  CharArray_=array[0..0] of Char;

  ShortArray=^ShortArray_;
  ShortArray_=array[0..0] of ShortInt;

  Integerarray=^Integerarray_;
  Integerarray_=array[0..0] of Integer;

  Wordarray=^Wordarray_;
  Wordarray_=array[0..0] of word;

  Longintarray=^Longintarray_;
  Longintarray_=array[0..0] of longint;

  realarray=^realarray_;
  realarray_=array[0..0] of real;

  PointerArray=^PointerArray_;
  PointerArray_=array[0..0] of pointer;

  BytePointerArray=^BytePointerArray_;
  BytePointerArray_=array[0..0] of BytePtr;

  BElemPtr=^BElem;

  BElem=object
    {Prev,}Next:Pointer;
  end;

  LinkedList=Object
    Count,size:word;

    first,Last:pointer;

    Function Prev(Elem:BElemPtr):Pointer;
    Procedure Add(Elem:BelemPtr);
    Procedure Insert(By,Elem:BElemPtr);
    Procedure Delete(Elem:BelemPtr);
    function GetByIndex(index:word):Pointer;
    Constructor Create(Size_:word);
    Destructor Done;virtual;
  end;

  linkedlistptr=^linkedlist;

  wordlistelem=object(belem)
    data:word;
  end;
  wordlistelemptr=^wordlistelem;

  integerlistelem=object(belem)
    data:integer;
  end;
  integerlistelemptr=^integerlistelem;
  longintlistelem=object(belem)
    data:longint;
  end;
  longintlistelemptr=^longintlistelem;
  reallistelem=object(belem)
    data:real;
  end;
  reallistelemptr=^reallistelem;

  Function CountFrom(elem:belemptr;count:word):Pointer;
  function createwordelem(data:word):belemptr;
  function createintegerelem(data:integer):belemptr;
  IMPLEMENTATION
  function createwordelem(data:word):belemptr;
  var new:belemptr;
  begin
    getmem(new,sizeof(wordlistelem));
    wordlistelemptr(new)^.data:=data;
    createwordelem:=new;
  end;

  function createintegerelem(data:integer):belemptr;
  var new:belemptr;
  begin
    getmem(new,sizeof(integerlistelem));
    integerlistelemptr(new)^.data:=data;
    createintegerelem:=new;
  end;




  Function CountFrom(elem:belemptr;count:word):Pointer;
  var lop:word;
  begin
    For lop:=1 to count-1 do
      elem:=elem^.next;
    CountFrom:=elem;
  end;

  Function LinkedList.Prev(Elem:BelemPtr):Pointer;
  var E:BelemPtr;
  begin
    E:=First;
    While (E<>nil)and(E^.next<>Elem) do
      E:=E^.next;
    Prev:=E;
  end;

  Constructor LinkedList.Create(Size_:word);
  begin
    Count:=0;
    first:=nil;
    Last:=nil;
    Size:=Size_;
  end;

  Destructor LinkedList.Done;
  var next:BelemPtr;
  begin
    while first<>nil do begin
      next:=BelemPtr(first)^.next;
      Freemem(BelemPtr(first),size);
      first:=next;
    end;
    Count:=0;
    last:=nil;
    first:=nil;
  end;

  {assumes Elem^.next = nil}
  Procedure LinkedList.add(Elem:BelemPtr);
  begin
    BelemPtr(Elem)^.next:=nil;
    if First=nil then
      First:=Elem
    else
      BelemPtr(last)^.next:=Elem;
    last:=Elem;
    inc(count);
  end;

  Procedure LinkedList.delete(Elem:BelemPtr);
  var Previous:BelemPtr;
  begin
    if Elem=first then begin
      first:=Elem^.next;
      Previous:=nil;
    end else begin
      Previous:=Prev(elem);
      Previous^.next:=Elem^.next;
    end;
    if elem=last then last:=Previous;
    Freemem(Elem,Size);
    dec(count);
  end;

  Procedure LinkedList.insert(by,elem:BelemPtr);
  var previous:BelemPtr;
  begin
    if by=first then begin
      elem^.next:=by;
      first:=elem;
    end else begin
      Previous:=Prev(by);
      Elem^.next:=Previous^.next;
      Previous^.next:=Elem;
    end;
    inc(count);
  end;

  function LinkedList.GetByIndex(index:word):Pointer;
  var lop:word;
      CurrElem:BelemPtr;
  begin
    if index>count then
      GetByIndex:=Last
    else begin
      Currelem:=First;
      for lop:=1 to index do
        Currelem:=Currelem^.next;
      GetByIndex:=CurrElem;
    end;
  end;


begin
  asm cwd;end;
end.