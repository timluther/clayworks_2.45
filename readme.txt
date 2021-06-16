2020: 
uploaded this to Github for historical fun

2000: 
Claworks 2.45 source code information.

This zip file contains the source code to version 2.45 of Claworks.
  This code is several years old and has not been maintained. I am releasing it into the public domain as several people have asked for it and it might help somebody in some small way.
  The code is probably quite messy, may contain poorly spelt or offensive comments and should not in any way be considered 'good code'. Hey, I was a kid when I wrote most of this!
  I haven't had time to really go through everything and check for obvious mistakes as I am quite busy
writing the new version of clayworks, working at www.aicube.com and generally doing stuff.
The source is mostly in Pascal but there are some smatterings of 80386 assembler in there too.
To compile this code and run clayworks you need to have Borland Pascal 6 or greater. Set your output
and unit directory to the 'bin' sub directory found in the zip file (if unzipping this file using 
dos pkunzip, using the -d switch to preserve the directory structure). In side that directory, there
are several files essential to clayworks including a few internal text files, a pcx image and 
  In preparing this source, I have simply isolated the Pascal files needed by clayworks from all the  other Pascal sources inside my aging Pascal directory. Some files may still be extraneous but I  haven't looked through well enough to determine which ones are and which ones are not.
  All of the core UI code is contained in the files 'views.pas','tdwin.pas', 'gadgets.pas' and 'dialogs.pas'.
The rendering code is contained in the files 'vga16.pas','vga256.pas' and 'xvga256.pas' although only  'vga16.pas' is used in clayworks (4bit colour mode). I'm not sure how up to data the other units are,  perhaps you could get them working. I remember I did have clayworks running at 640x400 with 8bit  colour on a standard vga card using the modex library but that was some time ago and not all monitors  would sync to the weird rate that the mode required. Lower modes such as 320x240x256 should sync ok.
  However, I take no responsibility for any damage you might do to your monitor (or yourself) if you  decide to use that library.



Synopsis of files:

BASIC3D.PAS    :Basic 3d definitions
BITMAP16.PAS   :Code for drawing on 4bit bitmaps
BITMAP25.PAS   :Code for drawing on 8bit bitmaps (n.b. almost exactly the same as vga256.pas)
CHARDEF.PAS    :Font structures and definitions
CLAYCP.PAS     :Main clayworks source file
COLOUR.PAS     :Colour palette manipulation; gradients, colour matching and rgb<->hsv convertion
CPUTYPE.PAS    :CPU identification (n.b from the dark ages, don't expect it to identify your itanium!)
CRT2.PAS       :Bare bones replacement for the buggy Borland crt.tpu unit (runtime error 200)
DIALOGS.PAS    :Dialog boxes structures and code (file, colour picker etc)
DISKOP.PAS     :Some disk io helper functions
DMA.PAS        :DMA transfer. Not sure If I actually use this, it did work sometime in the last decade
EMSUNIT.PAS    :EMS memory extender. Not used but included anyway.. I always hated EMS anyway
GADGETS.PAS    :Some extra UI widgets
GBASICS.PAS    :Basic graphical definitions. Defines certain types such as points & rects.
GGRAPH.PAS     :Used for graphical initialisation
LCD.PAS	       :No idea why this is in here, I used it for doing an lcd-a-like clock years ago
MSMOUSE.PAS    :Interface to a Microsoft compatible mouse driver
PCX256.PAS     :Loads pcx images
PITTIMER.PAS   :Low-level timer stuff. Not really used much.
SINCOS.PAS     :Tables for sine and cosine. Ha, those were the days.
STDPAL.PAS     :Standard clayworks palette
SVGA256.PAS    :Mode 13h (320x200x256) drawing code. 
TDB.PAS        :Scene manipulation and 3d projection code
TDEDITB.PAS    :Scene manipulation extensions for 3d modelling
TDWIN.PAS      :UI interface for manipulating 3d objects
TMATHS.PAS     :Maths helper functions
TMENUST.PAS    :UI menu elements (the st stands for 'static', I have another dynamic library)
TTYPES.PAS     :Basic types
TWINB.PAS      :UI widgets. Buttons, scrollbars, lists, toolbars etc
TWINDRAW.PAS   :Some higher level drawing code for certain useful shapes(for clayworks anyway)
VECTFONT.PAS   :Borland vector font manipulation code
VESAINFO.PAS   :Looks at the vesa modes on your card, not used.
VESATEST.PAS   :Tests vesa stuff
VGA16.PAS      :4bit drawing library. Includes lines, points, bitmap pasting, text rendering etc
VGA256.PAS     :as above only 8bit
VIEWS.PAS      :Core UI code
XVGA256.PAS    :8bit rendering code only using the tweaked mode X.


Have fun with the source and improve it if you like. However, if you wish to release a new version of
clayworks based on this source code, you must contact me first so that we can discuss how this should
be done. The main purpose of releasing the source is to help people understand what goes into a simple
3d modelling program, rather than to start a big GPL thing. Besides, who codes in Pascal these days?
  I hope you find this useful, I recommend looking at the UI code as it's probably the most advanced thing in here (I used this as a base for the rewrite of clayworks also, although It's evolved greatly over the years).

Finally, I reserve the right to the name 'Clayworks' and do not accept liability for any damages incurred through using this source.


Tim Lewis.
Tokyo, 31/8/2000.


