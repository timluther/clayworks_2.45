Unit Tmenust;
{$X+}{$g+}{$a+}
{Only 'Tpopupmenu's can be submenus. All menus can be 'rootmenu's
however. 'Tpopupmenu's save the area beneath them as a bitmap and
replace it *before* the 'commandlist' is exectuted (the command list
is allways exectuted by the 'rootmenu') so as to avoid screen corruption
if the area saved is graphically changed by the menu command}

INTERFACE
uses views,twindraw,gbasics,ggraph,chardef,msmouse,ttypes,tmaths;

const
{vertical size for horizontal menus}
vbord=fontheight+2;

popupindent=2;
optyoffs=(12 shr 1)-(Fontheight shr 1);

yseperatorsize=8;
ygapsize=5;
textindent      = 4;

menuxorient     = $0001;
menuPopup       = $0002;
menuSubMenu     = $0004;
menuindent      =$0008;


{menu item options}
moptButton      = $0001; {if set then the menu item will appear in bas relief}
moptCentre      = $0002; {if set, text will centre justify}
moptDisabled    = $0004; {if set then text will appear in disabled colour and option will not highlight}
moptTitle       = $0008+moptcentre+moptButton; {An unselectable title box}
moptseperator   = $0010;
mopttoggler     = $0020;
moptUnselectable =$0008+moptDisabled+moptseperator;
moptchangename   =$0100;
MenuDrawAll=1;
MenuDrawchange=2;
MenuDrawFinish=3;

type
{Itempalette=^Itempalette_;
Itempalette_=record
  backCol,foreCol,
  backselCol,foreselCol,
  titlebackCol,titleforeCol,
  disabledCol:byte;
end;}

CommandElementptr=^CommandElement;
CommandElement=object(belem)
  command:word;
end;


Tmenuview=^Tmenuview_;
Tmenuitem=^Tmenuitem_;
Tpopupmenu=^Tpopupmenu_;


Tmenuitem_=object
  name:string[20];
  attrib:word;
  keycode,command:word;
  submenu:tpopupmenu;
  extratext:string[10];

  {internal}
  toggleref:^boolean;
  offset:integer;
  name_length:byte;
  optgap:byte{=vbord-2};

end;

tmenuarray=^tmenuarray_;
tmenuarray_=array[0..0] of tmenuitem;



Tmenuview_=object(tview_)
  maxopts,Mattrib,drawmode,indent:byte;
  private

  maxnamelength,maxoffset:integer;
  commandlist:linkedlist;
  noevent:boolean;
  parent,rootmenu:Tmenuview;
  menu:Tmenuitem;
  oldsel,current:Tmenuitem;
  public
  constructor create(x,y:integer;menulist:tmenuitem;maxopts_,indent_,attrib_:byte);
  procedure calcsize(x,y:integer);

  procedure handlevent(var event:tevent);virtual;
  procedure draw;virtual;
  procedure additem(item:tmenuitem);

  private
  procedure getItemrect(item:Tmenuitem;var bounds:trect);
  function  insideitem(item:Tmenuitem):boolean;
  procedure drawitem(item:Tmenuitem;selecting:boolean);
  Function  getoptselect{(x,y:integer)}:tmenuitem;
end;

Tpopupmenu_=object(Tmenuview_)
  backpic:bitmaptypeptr;
  {Constructor create(x,y:integer;menulist:tmenuitem;maxopts_,indent_,attrib_:byte);
  destructor done;virtual;}
  procedure makesubmenuof(ParentMenu:TmenuView);
  procedure doevent(x,y:integer;var event:tevent;rootmenu_:Tmenuview;owner_:tgroup);
end;

Tmenubar=^tmenubar_;
Tmenubar_=object(Tmenuview_)
  procedure handlevent(var event:tevent);virtual;
end;

{var
pallete:Itempalette;}

IMPLEMENTATION
Function tmenuview_.insideitem(item:tmenuitem):boolean;
var tmp_rect:trect;
begin
  getitemrect(item,tmp_rect);
  if mattrib and menuxorient<>0 then begin
    dec(tmp_rect.y1,textindent);inc(tmp_rect.y2,textindent);
  end else begin
    dec(tmp_rect.x1,textindent);inc(tmp_rect.x2,textindent);
  end;
  insideitem:=tmp_rect.contains(xm,ym);
end;

{creates a menu}

procedure tmenuview_.calcsize(x,y:integer);
var offset:integer;
    indented:integer;

begin
  indented:=indent shl 1;

  if mattrib and menuxorient<>0 then
    rassign(x,y,x+maxoffset+indented,y+vbord+indented)
  else
    rassign(x,y,x+maxnamelength+indented,y+maxoffset+indented);

end;

procedure tmenuview_.additem(item:tmenuitem);

var
optgap:integer;

begin
  with item^ do begin
    if submenu<>nil then
      submenu^.makesubmenuof(@self);
    offset:=maxoffset;
    if attrib and moptseperator<>0 then
      optgap:=yseperatorsize
    else
      optgap:=fontheight+ygapsize;

    name_length:=(textindent shl 1)+TStrlen(name,@tcharset)+Tstrlen(extratext,@tcharset);
    if name_length>maxnamelength then maxnamelength:=name_length;
    if mattrib and menuxorient<>0 then begin
      inc(maxoffset,name_length);
    end else
      inc(maxoffset,optgap);

  end;


  inc(maxopts);
  {sort out size and shape depending on orientation}

end;
constructor tmenuview_.create(x,y:integer;menulist:tmenuitem;maxopts_,indent_,attrib_:byte);
var
    optloop:tmenuitem;
    lop:byte;
    tmp_loader:trect;
begin

  menu:=menulist;
  maxopts:=0;
  indent:=indent_;
  mattrib:=attrib_;

  CommandList.Create(sizeof(CommandElement));
  parent:=nil; current:=nil; oldsel:=nil;
  drawmode:=MenuDrawall;

  maxnamelength:=0;
  maxoffset:=0;

  rootmenu:=@self;
  inherited make;

  {for easy positioning}
  optloop:=menu;
  For lop:=1 to maxopts_ do begin
    {initialize for submenu}
    additem(optloop);

    inc(optloop);
  end;

  calcsize(x,y);
  {set up grow behaviour}

  growmode:=TGgrowx1+TGgrowy1+TGdragonx+TGdragony;

end;

{this function returns the box that contains x and y}
Function tmenuview_.getoptselect{(x,y:integer)}:tmenuitem;
var optlop:tmenuitem;
    lop:byte;
begin
  optlop:=menu;
  getoptselect:=nil;
  for lop:=1 to maxopts do begin
    if (insideitem(optlop))then begin
      if(optlop^.attrib and moptunselectable=0) then
      getoptselect:=optlop;
      exit;
    end;
    inc(optlop);
  end;
End;

function CheckClicked(altmethod:boolean;zm:byte):boolean;
begin

  checkclicked:=((zm=1) and not(altmethod))or((altmethod) and (zm=0));
end;
var
altmethod:boolean;
procedure Tmenuview_.handlevent(var event:tevent);
var currsub:tpopupmenu;

begin
  inherited handlevent(event);
  with event do
  if what and EvMouseDown<>0 then begin
    oldsel:=nil;
    currsub:=nil;
    noevent:=false;
    if rootmenu=@self then
    altmethod:=false;
    while checkclicked(altmethod,zm) do begin
      mpos;
      if rootmenu=@self then
      if ((zm=0)and(not ms_moved)) then altmethod:=true;
      oldsel:=current;
      if (parent<>nil)then with parent^ do
      if (contains(xm,ym)) and not(insideitem(current)) then begin
        self.noevent:=true;
        exit;
      end;
      current:=getoptselect;
      if oldsel<>current then begin
        drawmode:=MenuDrawChange;
        mouseoff;
        draw;
        mouseon;
        Drawmode:=MenuDrawall;
        if current<>nil then with current^ do begin
          if (submenu<>nil) then
            currsub:=pointer(submenu)
          else
            currsub:=nil;
          if (currsub<>nil ) then with currsub^ do begin
            parent:=@self;
            if self.mattrib and menuxorient<>0 then
              doevent(self.x1+offset+self.indent,self.y2+1,event,self.rootmenu,self.owner)
            else
              doevent(self.x2+1,self.y1+offset+self.indent,event,self.rootmenu,self.owner);
          end;
        end;
      end;
    end;
    what:=0;
    Drawmode:=MenuDrawFinish;
    drawview;
    Drawmode:=MenuDrawall;
  end else noevent:=true;
end;

procedure Tmenuview_.getItemrect(item:Tmenuitem;var bounds:trect);
var temp:byte;
begin
  {the '-1's are there to prevent overwrite by the next box}
  temp:=0;
  with item^ do begin
  if attrib and mopttitle <> mopttitle then temp:=indent;
  if mattrib and menuxorient<>0 then
    bounds.rassign(x1+offset+temp,y1+temp,
                   x1+offset+temp+name_length-1,y2-temp)
  else
    bounds.rassign(x1+temp,y1+offset+temp,
                   x2-temp,y1+offset+temp+optgap-1);
  end;
end;

procedure Tmenuview_.drawitem(item:Tmenuitem;selecting:boolean);
var drawbox,oldvp:trect;
    textoffs:integer;
    inabit:byte;
    button,selected:boolean;
    olddrawmode:byte;
begin
  if item<>nil then
  with item^ do begin
    getitemrect(item,drawbox);
    with drawbox do begin
      if attrib and moptseperator <>0 then begin
      t_col:=lightcol;
      hline3d(self.x1,self.x2-2,y1+(y2-y1) shr 1)
      end else begin
        button:=(attrib and moptbutton<>0);
        selected:=current=item;
        inabit:=0;

        textoffs:=inabit+textindent;

        if attrib and moptcentre<>0 then
          inc(textoffs,1+((x2-x1)shr 1)-((name_length)shr 1));
        {different colours}
        if attrib and mopttitle = mopttitle then
          T_fillcol:=titlecol
        else if (selected)and(not button) then begin
          T_fillcol:=menuselcolback;
          T_col:=menuselcolfore;
        end else begin
          T_col:=textcol;
          t_fillcol:=midcol;
        end;
        if button then begin
          if (selected)and(selecting) then begin
            inboxcol(x1,y1,x2,y2);
            inabit:=2;
          end else
            outboxcol(x1,y1,x2,y2)

        end else if (selected) or (not selecting) then begin
          if (selected) then
            buttonbardown(x1,y1,x2-1,y2)
          else
            buttonbar(x1,y1,x2-1,y2);

        end;

        if attrib and moptdisabled <>0 then begin
          T_col:=lightcol;

          outtextxy(x1+textoffs+inabit,y1+2+inabit+((y2-y1) shr 1)-(Fontsizey shr 1),name);
          outtextxy(x2-textoffs-inabit-Tstrlen(extratext,@tcharset),y1+inabit+((y2-y1) shr 1)-(Fontsizey shr 1),extratext);
          T_col:=Disabledcol;
        end;
        outtextxy(x1+textoffs+inabit-1,y1+1+inabit+((y2-y1) shr 1)-(Fontsizey shr 1),name);
        outtextxy(x2-textoffs-inabit-Tstrlen(extratext,@tcharset),y1+inabit+((y2-y1) shr 1)-(Fontsizey shr 1),extratext);
        if attrib and mopttoggler<>0 then begin
          if toggleref^ then
            t_fillcol:=biege
          else
            t_fillcol:=midcol;
          inboxcolb(x2-7,y1+((y2-y1) shr 1)-3,x2-2,y1+((y2-y1) shr 1)+3);
        end;
      end;
    end;
  end;
end;

procedure Tmenuview_.draw;
var optloop:tmenuitem;lop:byte;
begin
  case drawmode of
  MenuDrawAll:begin
    if mattrib and menuindent=0 then
      outbox(x1,y1,x2,y2)
    else
      outbox(x2-1,y2-1,x1,y1);
    optloop:=menu;
    for lop:=1 to maxopts do begin
      drawitem(optloop,true);
      inc(optloop);
    end;
  end;
  MenuDrawchange:if oldsel<>current then begin
    drawitem(oldsel,false);
    drawitem(current,true);
  end;
  MenuDrawFinish:
    drawitem(current,false);
  end;
end;

{******************* Pop up *********************}
{Constructor Tpopupmenu_.create(x,y:integer;menulist:tmenuitem;maxopts_,indent_,attrib_:byte);
begin
 backpic.create((x2-x1)+16,(y2-y1)+1);
 inherited create(x,y,menulist,maxopts_,indent_,attrib_);
end;

destructor Tpopupmenu_.done;
begin
  inherited done;
  backpic.done;
end;}

procedure Tpopupmenu_.doevent(x,y:integer;var event:tevent;rootmenu_:tmenuview;owner_:tgroup);
var newcommand:CommandElementptr;
begin
  {set up owners and rootmenu}
  rootmenu:=rootmenu_;
  owner:=owner_;
  if x+(x2-x1)>SC.screenport.x2 then dec(x,x+(x2-x1)-SC.screenport.x2);
  if y+(y2-y1)>SC.screenport.y2 then dec(y,y+(y2-y1)-SC.screenport.y2);
  rpos(x,y);
  mouseoff;
  {Backpic:=getbitmap(x1,y1,width+1,height+1);}
  draw;
  mouseon;
  handlevent(event);
  SC.viewport:=self;
  root^.drawview;
  SC.viewport:=SC.screenport;
  {mouseoff;
  putbitmap(x1,y1,backpic);
  mouseon;
  DestroyBitmap(backpic);}

  if not noevent then begin
    {add command to rootmenu's command list}
    new(newcommand);
    newcommand^.command:=current^.command;
    rootmenu^.commandlist.add(newcommand);
    if current^.attrib and moptchangename<>0 then begin
      rootmenu^.current^.name:='got here' {current^.name};
      rootmenu^.drawview;
    end;
    if mattrib and MenuSubmenu=0 then begin
      {if this is a root menu, execute command list}
      newcommand:=commandlist.first;
      while newcommand<>nil do begin
        Evcallback(newcommand^.command);
        newcommand:=newcommand^.next;
      end;
      commandlist.done;
    end;
  end;
  current:=nil;
end;

{******************* Menu bar *********************}

Procedure tpopupmenu_.MakeSubmenuOf(ParentMenu:TmenuView);
begin
  parent:=ParentMenu;
  mattrib:=mattrib or MenuSubMenu;
  {rootmenu:=ParentMenu^.rootmenu;}
end;

procedure Tmenubar_.handlevent(var event:tevent);
var currcommand:CommandElementptr;
    oldcurrent:tmenuitem;
begin
  inherited handlevent(event);
  if not noevent then begin
    {this is a root menu, execute command list}
    currcommand:=commandlist.first;
    while currcommand<>nil do begin
      Evcallback(currcommand^.command);
      currcommand:=currcommand^.next;
    end;
    commandlist.done;
    {exectute the top level instruction}
    Evcallback(current^.command);
    oldcurrent:=current;
    current:=nil;
    mouseoff;
    drawitem(oldcurrent,false);
    mouseon;
  end;
  current:=nil;
end;

end.
