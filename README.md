# tetris-fasm
this is my implementation of famous tetris game in fasm. There i used some material from my laborotory works from second term in BSUIR.
to work properly, its requires proc16.inc file (into fasm\include\macro folder) and win xp OS for example. I made it doublebuffered with just occupuing next segment to mine for videomem. That means, it may work incorrectly if other programms will try to use this segment. 
To compile it requires fasm.
This tetris version tested on win xp emulators (Oracle VM) and with original DOS.
This version marked as full, I tried to decrease weight of .com file. My best result is 1766 bytes (all unnecessary strings, letters and procedures were excluded from .com file but game functionality didnt change).
13h graphical mode size is 320*200 pixels.
