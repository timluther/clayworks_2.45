unit Views;

{dDEFINE NonStandardVideo}
{$X+}{$g+}{$a+}
{Notes:
  a.) Events must NOT be called in creation of objects.
  b.) Make sure that the root object never tries to cal it's parent
      Non-group objects must allways be owned by a group or procedures
      at null pointers may be called resulting in a crash.
  c.) ALL drawing operations nust be called in a view's 'draw' function
      with possible case statments if only some things need to be drawn.
  d.) make sure all possible command events are handled in some way,
      avoiding misinterpertation(?!@#) of commands.
  e.) The global 'root' must always be set to the top level group object
  f.) The global 'global_select' is also important but it is handled solely
      within the code of this unit.
}


INTERFACE
uses gbasics,ggraph,msmouse,twindraw,ttypes,crt2;

Const
PIDundefined=65535; {for views that don't want to be individuals}

GOsoliddrag = $0001;
{option flags}
ofselectable = $0001;
ofNOoverlap  = $0002;
ofALTkey     = $0004;
ofXorient    = $0008;
ofPopup      = $0010;
ofTopselect  = $0020;
ofautoraise  = $0040;
ofkeygrab    = $0100;
ofclicktopselect = $0200;
oftabcycleselect=$0400;
{ofparentresize  = $0100;}

{status flags}
sfVisible   = $0001;
sfSelected  = $0002;
sfFocused   = $0004;
sfDrawnonce = $0008;
sfdisabled  = $0010;
sfModal     = $0100;
sfexposed   = $0040;
sfmute      = $0080;
sfmouseInView =$0020;

{view drag mode constants
  ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄdmLimitAll = $F0
ÉÍÏÍÑÍÏÍÑÍÏÍÑÍÏÍÑÍÍÍÑÍÍÍÑÍÍÍÑÍÍÍ»
ºmsb³   ³   ³   ³   ³   ³   ³lsbº
ÈÍÑÍÏÍÑÍÏÍÑÍÏÍÑÍÏÍÍÍÏÍÍÍÏÍÑÍÏÍÑÍ¼
  ³   ³   ³   ³           ³   ÀÄÄÄdmDragMove = $01
  ³   ³   ³   ³           ÀÄÄÄÄÄÄÄdmDragGrow = $02
  ³   ³   ³   ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄdmLimitLoX = $10
  ³   ³   ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄdmLimitLoY = $20
  ³   ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄdmLimitHiX = $40
  ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄdmLimitHiY = $80}

TDMove=      $01;
TDGrow =     $02;
TDLimitLoX = $10;
TDLimitLoY = $20;
TDLimitHiX = $40;
TDLimitHiY = $80;
TDLimitAll = $F0;

{Grow mode constants}

TGgrowX1   = $01;
TGgrowY1   = $02;
TGgrowX2   = $04;
TGgrowY2   = $08;
TGdragonX  = $10;  {Only then equiv of the changed side will move, not it's opp}
TGdragonY  = $20;

TGdragX1=TGgrowX1+TGdragonX;
TGdragy1=TGgrowY1+TGdragonY;
TGdragX2=TGgrowX2+TGdragonX;
TGdragY2=TGgrowY2+TGdragonY;
TGrelative = $40;

TGgrowallX  =TGgrowx1+TGgrowx2;
TGgrowallY  =TGgrowy1+TGgrowy2;
TGgrowall = TGgrowallx+TGgrowally;

{TGrowLoX   = right;
TGrowHiX   = left;
TGrowLoY   = bellow;
TGrowHiY   = above;
TGrowRel   = $10;}

{Event constants}
evMouseDown = $0001; { Mouse button depressed }
evMouseUp   = $0002; { Mouse button released  }
evMouseMove = $0004; { Mouse changed location }
evMouseDrag = $0008; { Periodic event while mouse button held down}
evMousepressed=evmousedown+evmousedrag;
evKeyDown   = $0010; { Key pressed    }
evCommand   = $0020; { Command event  }

evNothing  = $0000; { Event already handled}
evMouse    = $000F; { Mouse event   }
evKeyboard = $0010; { Keyboard event}
evMessage  = $FF00; { Message (command, broadcast, or user-defined) event}
evAll      = $FFFF;

{add_and_draw constants}
VPcentre=1;
VPBottomright=2;
VPtopright=3;
VPBottomleft=4;
VPtopleft=5;
VPindent=3;

type
Tcommandset=set of byte;
{CurCommandSet: TCommandSet = [0..255] - [cmZoom, cmClose, cmResize,
cmNext];}
Tgroup=^tgroup_;
Tview=^Tview_;

TEvent = record
  what:byte;
  Command: Word;
  case byte of
    0:(InfoPtr: Pointer);
    1:(InfoLong: Longint);
    2:(InfoWord: Word);
    3:(InfoInt: Integer);
    4:(InfoByte: Byte);
    5:(InfoChar: Char);
    6:(InfoTview: Tview);
    7:(InfoTgroup: Tgroup);
end;

Tobject=object
  constructor create;
  procedure free;
  destructor done;virtual;
end;


Tview_=object(trect)
  growmode,dragmode,state:byte;
  {eventmask,}pid,options:word;
  owner:Tgroup;next:Tview;

  Constructor create(x1_,y1_,x2_,y2_:integer);
  Constructor make;
  destructor done;virtual;
  procedure delete;

  procedure setbounds(var bounds:trect);
  procedure getbounds(var bounds:trect);
  Procedure Tmoveto(mx,my:integer);
  Procedure Tmove(mx,my:integer);
  Procedure Tgrow(gx,gy:integer);

  Procedure calcbounds(change:trect);
  Procedure limitmouse(var bounds:trect);
  procedure reposview(var bounds:trect);
  {this is the one you use if you don't want to redraw the view!}
  procedure changebounds(var bounds:trect);virtual;
  Procedure dragview(mode:byte;limits:trect;minx,miny,maxx,maxy:integer);

  procedure SetState(AState: Word; Enable: Boolean); virtual;
  procedure select;

  procedure drawview;
  procedure draw;virtual;
  procedure handlevent(var event:tevent);virtual;
  procedure doneevent(var event:tevent);
  procedure EvCallBack(Command:word);
  procedure SendCommand(Command:word;Destination:tview;data:pointer);
  procedure Whilemousein;

  Function Prev:Tview;
  Function NextCycle:Tview;
  Procedure putinfrontof(View:Tview);
  Function exposed:boolean;
  Function inview(x,y:integer):boolean;

  {procedure getevent(What:tevent);virtual}
end;

Tgroup_=object(tview_)
  selected,last,first:tview;
  constructor create(x1_,y1_,x2_,y2_:integer);
  constructor make;
  destructor done;virtual;

  procedure changebounds(var bounds:trect);virtual;
  procedure handlevent(var event:tevent);virtual;

  procedure draw;virtual;
  procedure insert(view:tview);
  Function add_and_draw(view:tview;where:byte;pid_:word):tview;
end;

UpdateView=^UpdateView_;
UpdateView_=object(tview_)
  procedure update;virtual;
end;

{UpdateProc=Procedure(obj:tview);
Updatestruct=object(belem);
  time,wait:longint;
  view:UpdateView;
end;}

const
GlobalOptions:byte=GOsoliddrag;
var
KeyCode: Word absolute CharCode;

{----****IMPORTANT GLOBALS****----}
const
maxcallbacks:word=0;
Global_selected:tview=nil;
Root:tgroup=nil;

Procedure initTWIN(root_:tgroup);
{procedure mainloop;
procedure addcallback(view_:updateview;wait_:longint);}
procedure eventmpos;
procedure eventkey;
Procedure closeTWIN;

IMPLEMENTATION

{var
{these variables are used as global loop and action variables hidden in
the private part of the unit. An unstructured way of implementing loops.
perhaps, but it saves in code and memory size where these factors are
importatnt. Make sure you are aware of these variables and their use}

{tmp_currview:tview;}





{***********************====--- TObject ---====***********************}
Constructor Tobject.create; begin end;
Destructor  Tobject.done;   begin end;
Procedure   Tobject.Free;
begin
end;

{***********************====--- Tview ---====***********************}
{make is for view whose dimensions are determined latter -they are minimal
 constructrs}
Constructor Tview_.make;
begin
  dragmode:=TDLimitAll;
  growmode:=TGgrowall;
  owner:=nil;
  next:=nil;
  pid:=pidundefined;
  {eventmask:=evMouseDown + evKeyDown + evCommand;}
  state:=sfvisible;
  options:=ofselectable;
end;

Constructor Tview_.create(x1_,y1_,x2_,y2_:integer);
begin
  x1:=x1_; y1:=y1_;
  x2:=x2_; y2:=y2_;
  pid:=pidundefined;
  dragmode:=TDLimitAll;
  growmode:=TGgrowall;
  owner:=nil;
  next:=nil;
  {eventmask:=evMouseDown + evKeyDown + evCommand;}
  state:=sfvisible;
  options:=ofselectable;
end;

Destructor Tview_.done;begin end;

procedure Tview_.setbounds(var bounds:trect);assembler;
asm
  les di,self
  push ds
    lds si,bounds
    mov cx,4
    rep movsw
  pop ds
end;

procedure Tview_.getbounds(var bounds:trect);assembler;
asm
  les di,bounds
  push ds
    lds si,self
    mov cx,4
    rep movsw
  pop ds
end;

Procedure Tview_.Tmove(mx,my:integer);
var tmp_loader:trect;
Begin
  getbounds(tmp_loader);
  tmp_loader.rmove(mx,my);
  reposview(tmp_loader);
end;

Procedure Tview_.Tmoveto(mx,my:integer);
var tmp_loader:trect;
begin
  getbounds(tmp_loader);
  tmp_loader.rpos(mx,my);
  reposview(tmp_loader);
end;

Procedure Tview_.Tgrow(gx,gy:integer);
var tmp_loader:trect;
begin
  getbounds(tmp_loader);
  tmp_loader.rgrow(gx,gy);
  reposview(tmp_loader);
end;

Procedure Tview_.calcbounds(change:trect);
var dragx,dragy:boolean;
    tmp_loader:trect;
Begin
  getbounds(tmp_loader);
  with tmp_loader do
  if change.empty then
    rmove(change.x1,change.y1)
  else begin
    dragX:=growmode and TGdragonX <> 0;
    dragY:=growmode and TGdragonY <> 0;
    if growmode and TGgrowx1<>0 then begin
      inc(x1,change.x1);if dragx then inc(x2,change.x1);
    end;
    if growmode and TGgrowy1<>0 then begin
      inc(y1,change.y1);if dragy then inc(y2,change.y1);
    end;
    if growmode and TGgrowx2<>0 then begin
      inc(x2,change.x2);if dragx then inc(x1,change.x2);
    end;
    if growmode and TGgrowy2<>0 then begin
      inc(y2,change.y2);if dragy then inc(y1,change.y2);
    end;
  end;
  changebounds(tmp_loader);
end;

Procedure Tview_.dragview(mode:byte;limits:trect;minx,miny,maxx,maxy:integer);
var MoveGrowmode:byte;
    tmp_loader,oldbounds,offsets:trect;
    oldzm:integer;

begin
  MoveGrowmode:=mode and (tdmove+tdgrow);
  getbounds(tmp_loader);
  offsets.x1:=x1-xm;offsets.y1:=y1-ym;
  offsets.x2:=x2-xm;offsets.y2:=y2-ym;
  if (GlobalOptions and GOsoliddrag=0)and(owner<>nil) then
    SC.viewport.intersect(owner^);
  {oldzm:=zm;}
  with limits do setmouserect(x1,y1,x2,y2);
  with tmp_loader do
  while zm<>0{=oldzm} do begin
    mpos;
    oldbounds:=tmp_loader;
    if movegrowmode = tdmove then
      rpos(xm+offsets.x1,ym+offsets.y1)
    else begin
      x2:=xm+offsets.x2; y2:=ym+offsets.y2;
    end;
    if (x2-x1)<minx then x2:=x1+minx;
    if (y2-y1)<miny then y2:=y1+miny;
    if (x2-x1)>maxx then x2:=x1+maxx;
    if (y2-y1)>maxy then y2:=y1+maxy;

    if (GlobalOptions and GOsoliddrag<>0) then begin
      if (not oldbounds.equals(tmp_loader)) and (ms_moved) then
        reposview(tmp_loader);
        waitvbl;
    end else begin
      t_writemode:=(xorput);t_col:=(8);
      mouseoff;ThickRectangle(x1,y1,x2,y2,3);mouseon;
      while (not ms_moved)and(zm<>0)do mpos;
      mouseoff;ThickRectangle(x1,y1,x2,y2,3);mouseon;
      t_writemode:=0;
    end;
  end;
  if (GlobalOptions and GOsoliddrag=0) then begin
    SC.viewport:=SC.screenport;
    reposview(tmp_loader);
  end;
  setmouserect(0,0,SC.size.x-1,SC.size.y-1);
end;

procedure Tview_.reposview(var bounds:trect);
var old,oldvp:trect;
    currview:tview;
begin
  getbounds(old);
  changebounds(bounds);
  drawview;
  if (owner<>nil) then begin
    oldvp:=SC.viewport;
    old.intersect(SC.viewport);
    SC.viewport:=old;
    currview:=next;
    while currview<>nil do begin
      currview^.drawview;
      currview:=currview^.next;
    end;
    SC.viewport:=oldvp;
  end;
end;

Procedure Tview_.changebounds(var bounds:trect);assembler;
asm
  les di,self
  push ds
    lds si,bounds
    mov cx,4
    rep movsw
  pop ds
end;

procedure Tview_.select;
var sf:byte;
    tmpview:tgroup;
    selview:tview;
begin
  if (state and (sfSelected+sfDisabled)=0)and(options and ofSelectable<>0) then begin
    sf:=sfselected+sffocused;
    {traverse tree, deselecting owners}
    while (global_selected<>nil)do begin
      global_selected^.setstate(sf,false);
      global_selected:=global_selected^.owner;
    end;
    global_selected:=@self;

    tmpview:=owner;
    selview:=@self;
    {traverse up tree, selecting owners}
    while (tmpview<>nil) do begin
      {if owner<>nil then begin}
      tmpview^.selected:=selview;
      selview:=tmpview;
      tmpview^.setstate(sffocused,true);
      tmpview:=tmpview^.owner;
      {if owner^.state and sffocused<>0 then inc(sf,sffocused);
    end else inc(sf,sffocused);}
    end;
    setstate(sf,true);
    if options and oftopselect<>0 then begin
      putinfrontof(owner^.first);
    end;
  end;
end;

procedure Tview_.SetState(AState: Word; Enable: Boolean);
begin
  if enable then
    state:=state or astate
  else
    state:=state and not Astate;
end;

{This will draw and redraw the view as few times as is needed to fill
the area}

procedure Tview_.drawview;

var p,oldlop,plop,newp:prectlist;
    oldvp:trect;
    parent:tgroup;
    currview,stopat:tview;
    currect:trect;
begin
  if (overlap(SC.viewport))and(state and sfvisible<>0) then begin
    
    oldvp:=SC.viewport;
    SC.viewport.intersect(self);
    parent:=owner;
    while parent<>nil do begin
      SC.viewport.intersect(parent^);
      parent:=parent^.owner;
    end;
    new(p);
    with SC.viewport do
      p^.rassign(x1,y1,x2,y2);
    p^.next:=nil;
    parent:=owner;
    stopat:=@self;
    while parent<>nil do begin
      currview:=parent^.first;
      if parent^.options and ofNooverlap = 0 then
      while currview<>stopat do begin
        {If the list is empty then restore SC.viewport and exit without drawing}
        if p=nil then begin
          SC.viewport:=oldvp;
          exit;
        end;
        {traverse current rectangle list}
        plop:=p;
        while plop<>nil do begin
          newp:=plop^.cutfrom(currview^);
          case rectlist_status of
            {replace current rectangle with the rectangles cut away from it}
            RSlist:begin
              lastrect^.next:=plop^.next;
              plop^:=newp^;
              dispose(newp);
              plop^.next:=newp^.next;
              plop:=lastrect^.next;
              {should check for 'concatablity' by 'ure}
            end;
            {delete current rectangle if obscured}
            RSobscured:begin
              newp:=plop^.next;
              if plop=p then
                p:=newp
              else begin
                oldlop:=p;
                while (oldlop<>nil)and(oldlop^.next<>plop) do
                  oldlop:=oldlop^.next;
                oldlop^.next:=newp;
              end;
              dispose(plop);
              plop:=newp;
            end else begin
              {or leave it alone if nothing touches it}
              destroyplist(newp);
              plop:=plop^.next;
            end;
          end;
        end;
        currview:=currview^.next;
      end;
      stopat:=parent;
      parent:=parent^.owner;
    end;

    if p<>nil then begin
      {tidy up loop -if two rectangles
      can make one then join them together}
      {plop:=p^.next;
      newp:=p;
      while plop<>nil do begin
        if newp^.concatable(plop^) then begin
          newp^.union(plop^);
          if newp<>p then begin
            oldlop:=p;
            while (oldlop<>nil)and(oldlop^.next<>newp) do
              oldlop:=oldlop^.next;
            oldlop^.next:=newp^.next;
          end;
          dispose(newp);

          newp:=p;
          plop:=p^.next;
        end;
        plop:=plop^.next;
      end;
      {draw loop}
      plop:=p;

      {$ifdef NONSTANDARDVIDEO}
      mouseoff{rect(self)};
      while plop<>nil do begin
        SC.viewport:=plop^;
        draw;
        state:=state or sfdrawnonce;
        plop:=plop^.next;
      end;
      mouseon;
      {$else}
      mouseoff;
      while plop<>nil do begin
        SC.viewport:=plop^;
        draw;
        state:=state or sfdrawnonce;
        plop:=plop^.next;
      end;
      if state and sfdisabled<>0 then begin
        t_col:=midcol;
        setfillpattern(midgreyfill,false);
        plop:=p;
        while plop<>nil do begin
          SC.viewport:=plop^;
          bar(x1,y1,x2,y2);
          plop:=plop^.next;
        end;
        setsolidfill;
      end;
      mouseon;
      {$endif}

      state:=state xor sfdrawnonce;
      destroyplist(p);
    end;
    SC.viewport:=oldvp;
  end;

end;


{the allways overridden standard drawing procedure
try not to call directly but use drawview}
Procedure Tview_.draw;
Begin
end;

{the allways overridden standard handling procedure}
Procedure Tview_.handlevent(var event:tevent);
Begin
  with event do
  if what and evmouse<>0 then begin
    {SetState(SfMouseInView,True);}
    if (options and ofautoraise<>0)or(zm<>0) then
      select;
  end {else
    SetState(sfMouseInView,False);}
end;

Procedure Tview_.doneevent(var event:tevent);
begin
  event.what:=0;
end;

Procedure Tview_.EvCallBack(command:word);
begin
  SendCommand(Command,owner,@self);
end;

procedure Tview_.SendCommand(Command:word;Destination:tview;data:pointer);
var sendevent:tevent;
begin
  sendevent.what:=EvCommand;
  move(data,sendevent.infoptr,4);
  sendevent.command:=command;
  if state and sfmute=0 then
    if Destination<>nil then
      Destination^.handlevent(sendevent)
end;

Procedure Tview_.limitmouse(var bounds:trect);
begin
  setmouserect(bounds.x1-(x1-xm),bounds.y1-(y1-ym),bounds.x2-(x2-xm),bounds.y2-(y2-ym));
end;


Function Tview_.Prev:Tview;
var currview:tview;
Begin
  if (owner<>nil)and(@self<>owner^.first) then begin
    currview:=owner^.first;
    while (currview^.next<>@self)and(currview<>nil) do
      currview:=currview^.next;
    prev:=currview;
  end else
    prev:=nil;
end;

Function Tview_.NextCycle:Tview;
Begin
  if owner<>nil then begin
    if next=nil then
      nextcycle:=Owner^.first
    else
      nextcycle:=next;
  end else
    nextcycle:=nil;
end;

Procedure Tview_.putinfrontof(View:Tview);
var currview,pview:tview;
    oldvp,clipto:trect;
    plist,currp:prectlist;
    nooverlaps:boolean;
Begin
  if (view<>@self)then begin
    currview:=owner^.first;
    clipto:=currview^;

    while (currview<>nil) and (currview<>@self) do begin
      if currview^.overlap(self) then
        clipto.union(currview^);
      currview:=currview^.next;
    end;

    clipto.intersect(self);
    clipto.intersect(SC.screenport);

    {rearrange the list}
    pview:=prev;
    pview^.next:=next;
    if owner^.last=@self then
    owner^.last:=pview;
    next:=owner^.first;
    owner^.first:=@self;

    oldvp:=SC.viewport;
    SC.viewport:=clipto;
    drawview;

    SC.viewport:=oldvp;
  end;
end;

Function Tview_.inview(x,y:integer):boolean;
var parent:tgroup;
  stopat,currview:tview;
Begin
  parent:=owner;
  stopat:=@self;
  if contains(x,y) then begin
    inview:=true;
    while parent<>nil do begin
      currview:=parent^.first;
      if (parent^.options and ofNooverlap = 0) then
      while (currview<>stopat) do begin
        if (currview^.contains(x,y))or(not parent^.contains(x,y)) then begin
          inview:=false;exit;
        end;
        currview:=currview^.next;
      end;
      stopat:=parent;
      parent:=parent^.owner;
    end;
  end else
  inview:=false;
end;

Function Tview_.exposed:boolean;
var parent:tgroup;
    currview,stopat:tview;
Begin
  parent:=owner;
  stopat:=@self;
  while parent<>nil do begin
    currview:=parent^.first;
    if parent^.options and ofNooverlap = 0 then
    while (currview<>stopat ) do begin
      if stopat^.inside(currview^) then begin
        exposed:=false;exit;
      end;
      currview:=currview^.next;
    end;
    stopat:=parent;
    parent:=parent^.owner;
  end;
  exposed:=true;
end;

procedure Tview_.delete;
var oldvp:trect;
    currview,pview:tview;
begin
  {sort out selections}
  root^.select;
  {if global_selected=@self then
    if next=nil then
      owner^.select
    else
      next^.select;}
  oldvp:=SC.viewport;
  SC.viewport:=self;
  SC.viewport.intersect(SC.screenport);

  pview:=prev;
  if pview<>nil then begin
    pview^.next:=next;
    if @self=owner^.last then
      owner^.last:=pview;
  end else {it's the first view, prev=nil}
    owner^.first:=next;

  currview:=next;
  while currview<>nil do begin
    currview^.drawview;
    currview:=currview^.next;
  end;
  currview^.drawview;
  SC.viewport:=oldvp;
  dispose(tview(@self),done);
end;

procedure tview_.whilemousein;
begin
  while contains(xm,ym) and (zm<>0) do
    mpos;
end;

{***********************====--- TGroup_ ---====***********************}

constructor Tgroup_.create(x1_,y1_,x2_,y2_:integer);
begin
  tview_.create(x1_,y1_,x2_,y2_);
  {eventmask:=evall;}
  last:=nil;
  first:=nil;
  selected:=nil;
end;

constructor Tgroup_.make;
begin
  tview_.make;
  last:=nil;
  first:=nil;
  selected:=nil;

end;

procedure Tgroup_.handlevent(var event:tevent);
var currview:tview;
begin
  inherited handlevent(event);

  with event do
    if what and EVmouse<>0 then begin
      currview:=first;
      while (what<>0)and(currview<>nil) do with currview^ do begin
        if (inview(xm,ym))and(state and sfdisabled=0) then begin
          SetState(SfMouseInView,true);
          handlevent(event);
        end else
          SetState(SfMouseInView,false);

        currview:=next;
      end;

    end else
    if what and EVkeydown<>0 then begin
      if (charcode=tabkey)and(options and oftabcycleselect<>0)and
      (global_selected^.owner=@self) then begin
        {sound(100);delay(10);nosound;}
        currview:=global_selected^.nextcycle;
        while (currview<>global_selected) and (currview^.options and oftabcycleselect=0) do
          currview:=currview^.nextcycle;
        if currview<>global_selected then
          currview^.select;
        what:=0;
      end else begin
        currview:=first;
          while (what<>0)and(currview<>nil) do with currview^ do begin
          if (currview<>global_selected)and(state and sfdisabled=0)and
          (options and OfKeyGrab<>0) then
            handlevent(event);
          currview:=next;
        end;
      end;
    end;
end;

procedure Tgroup_.insert(view:tview);
begin
  if last=nil then begin
    last:=view;
    first:=view;
  end else begin
    view^.next:=first;
    first:=view;
  end;
  last^.next:=nil;
  view^.owner:=@self;
  {state:=state and not sfvisible;
  view^.select;
  state:=state or sfvisible;}
end;

Function Tgroup_.add_and_draw(view:tview;where:byte;pid_:word):tview;
var tmprect:trect;currview:tview;
begin
  currview:=first;
  while currview<>nil do begin
    if (currview^.pid<>pidundefined)and(currview^.pid=pid_) then begin
      currview^.putinfrontof(first);
      dispose(view,done);
      add_and_draw:=currview;
      exit;
    end;
    currview:=currview^.next;
  end;
  insert(view);
  view^.pid:=pid_;

  with view^ do begin
    tmprect:=view^;
    case where of
    VPCentre:
      tmprect.rpos(self.x1+self.halfx-halfx,self.y1+self.halfy-halfy);
    VPBottomright:
      tmprect.rpos(self.x2-(x2-x1)-VPindent,self.y2-(y2-y1)-VPindent);
    VPtopright:
      tmprect.rpos(self.x2-(x2-x1)-VPindent,self.y1+VPindent);
    end;
    if where<>0 then changebounds(tmprect);
    drawview;
  end;

  add_and_draw:=view;
end;

destructor Tgroup_.done;
var nextview:Tview;
begin
  if first<>nil then begin
    nextview:=first;
    while nextview<>nil do begin
      nextview:=first^.next;
      dispose(first,done);
      first:=nextview;
    end;
  end;
  inherited done;

end;

Procedure Tgroup_.draw;
var currview:tview;
    oldvp:trect;
Begin
  if first<>nil then begin
    currview:=first;
      while currview<>nil do begin
        with currview^ do
        if self.options and ofNooverlap = ofNooverlap then begin
          if (overlap(SC.viewport)){and(state and sfvisible<>0)} then begin
            oldvp:=SC.viewport;
            SC.viewport.intersect(currview^);
            draw;
            SC.viewport:=oldvp;
          end;
        end else
          drawview;
        currview:=currview^.next;
      end;
  end;
  if state and sfdisabled<>0 then begin
    t_col:=midcol;
    setfillpattern(midgreyfill,false);
    bar(x1,y1,x2,y2);
    setsolidfill;
  end;
end;

procedure Tgroup_.changebounds(var bounds:trect);
var diff:trect;
    currview:tview;
begin
  {get the difference between the old rectangle and the new}
  diff.x1:=bounds.x1-x1;
  diff.y1:=bounds.y1-y1;
  diff.x2:=bounds.x2-x2;
  diff.y2:=bounds.y2-y2;
  setbounds(bounds);

  currview:=first;
  {options:=options or ofparentresize; }
  while currview<>nil do begin
    currview^.calcbounds(diff);
    currview:=currview^.next;
  end;
  {options:=options xor ofparentresize;}
end;

procedure updateview_.update;
begin
end;


{Core key and mouse event handling}
procedure eventmpos;
var mevent:tevent;
begin
  mpos;
  with mevent do begin
    what:=0;
    if ms_released then inc(what,evMouseup) else begin
      if zm<>0 then inc(what,evMousedrag);
      if ms_pressed then inc(what,evMousedown);
    end;
    if ms_moved then
      inc(what,evMouseMove);
    if what<>0 then
      root^.handlevent(mevent);
  end;
end;

procedure eventkey;
var keyevent:tevent;
    currview:tview;
begin
  if keypressed then begin
    readkey;
    keyevent.what:=evkeydown;
    if global_selected<>nil then begin
      currview:=global_selected;
      while (keyevent.what<>0)and(currview<>nil)do begin
        currview^.handlevent(keyevent);
        currview:=currview^.owner;
      end;
    end;
  end;
end;

{procedure addcallback(view_:updateview;wait_:longint);
begin
  if maxcallbacks<=255 then begin
  inc(maxcallbacks);
  with callbacks[maxcallbacks-1] do begin
    wait:=wait_;
    time:=0;
    view:=view_;
  end;
  end;
end;

procedure mainloop;
var lop:word;
begin
  eventmpos;
  eventkey;
  if maxcallbacks>0 then
  for lop:=0 to maxcallbacks-1 do with callbacks[maxcallbacks] do
    if time>=wait then begin
      view^.update;
      time:=0;
    end else
      inc(time);
end;}

Procedure InitTwin(root_:tgroup);
begin
  root:=root_;
  root^.select;
  setmouseshape(0,0,arrow);
  resetmouse;
  setmouserect(0,0,SC.size.x-1,SC.size.y-1);
end;


Procedure CloseTwin;
begin
  dispose(root,done);
end;

end.
