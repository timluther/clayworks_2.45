UNIT PITtimer;


INTERFACE
Uses Dos;

{$F+} { Force far mode, a good idea when mucking around with interrupts }

const TIMERINTR = 8;
       PIT_FREQ = $1234DD;

procedure SetTimer(TimerHandler : pointer; frequency : word);
procedure CleanupTimer;

IMPLEMENTATION
var BIOSTimerHandler : procedure;
    clock_ticks, counter : longint;
    PHandle:procedure;

{Ok, here's our actual handler. This particular handler just writes an
asterix (*) to the screen. Then it does the checks to see if the BIOS
handler should be called. If so it calls it, if not it acknowledges the
interrupt itself.}

procedure Handler; Interrupt;
begin

  Phandle;
  { Adjust the count of clock ticks }
  inc(clock_ticks,counter);

  { Is it time for the BIOS handler to do it's thang? }
  if clock_ticks >= $10000 then begin
    { Yep! So adjust the count and call the BIOS handler }
    clock_ticks := 0;

    asm pushf end;
    BIOSTimerHandler;
  end

  { If not then just acknowledge the interrupt }
  else
    Port[$20] := $20;
end;

{
The clock_ticks variable will keep track of how many cycles the PIT has
had, it'll be intialised to 0. The counter variable will hold the new
channel 0 counter value. We'll also be adding this number to clock_ticks
every time our handler is called.

Next we need to do some initialization:}

procedure SetTimer(TimerHandler : pointer; frequency : word);
begin

  { Do some initialization }
  clock_ticks := 0;
  counter := $1234DD div frequency;

  { Store the current BIOS handler and set up our own }
  GetIntVec(TIMERINTR, @BIOSTimerHandler);
  SetIntVec(TIMERINTR, @Handler);
  @Phandle:=timerHandler;

  { Set the PIT channel 0 frequency }
  Port[$43] := $34;
  Port[$40] := counter mod 256;
  Port[$40] := counter div 256;
end;
{
Pretty straightforward stuff. We save the address of the BIOS handler,
install our own, set up the variables we'll use and program PIT channel 0
for the divide-by-N mode at the frequency we need.

This next bit is what we need to do once our program is finished. It just
resets everything back to normal.}

procedure CleanUpTimer;
begin
  { Restore the normal clock frequency }
  Port[$43] := $34;
  Port[$40] := 0;
  Port[$40] := 0;

  { Restore the normal ticker handler }
  SetIntVec(TIMERINTR, @BIOSTimerHandler);
end;
{
And finally our calling program. What follows is just an example program
which sets everything up, waits for us to press a key and then cleans up
after itself.
}

end.