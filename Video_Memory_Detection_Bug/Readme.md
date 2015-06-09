### I have a sneaking suspicion...
I can smell a video card detection routine gone bad from here. This has nothing to do with Windows and\or DirectDraw (well partially it does, but not the way you think). It's just an old game makes assumptions that are no longer valid. It's not uncommon. For example Oni game [crashes on modern videocards][1]:

> This problem has been traced to the overflow of a particular text
> buffer - the one that lists the OpenGL extensions in the `startup.txt`
> file. When Oni was written, the OpenGL extension list dump was much
> shorter, and the developers did not allow for a larger dump. Modern
> graphics cards almost always cause this overflow.

### We need to go deeper
I don't own Nascar Heat 2002, but I've downloaded a [NASCAR Heat Demo][2] and it's exhibits exactly the same problem. So I've unholstered my [debugger][3] and [disassembler][4] and spent an evening trying to figure out what's wrong with the game.

The game actually consists of two executables, communicating with each other via [semaphore][5]: the main executable (`NASCAR Heat Demo.exe` in my case), and the actual game engine (`.\run\race.bin`). The videocard detection routine is in the `race.bin`. On game launch the main executable copies `race.bin` to the Windows TEMP folder as `heat.bin` and runs it from there. If you try to rename `race.bin` to `race.exe` and run it, it searches for semaphore that should be created by the main executable, and if it's not found displays this message:

![Sneaky user! Where is my canary!][6]

After a disassembly and quick look at the string references, I've found a function call that prints `vid: 0 meg card (reported:0.523438)` message. It's actually a part of videocard memory size detection procedure, that in pseudocode looks like this (oversimplified):

<!-- language: lang-c -->

    RawVidMemSize = GetVidMemSizeFromDirectDraw()
    
    // Add 614400 bytes (600Kb - 640x480 mode?) to vidmem size (what for?!)
    RawVidMemSize = RawVidMemSize + 614400
    
    if (RawVidMemSize < 2000000)
    {
    	MemSize = 0
    }
    else
    {
    	if (RawVidMemSize < 4000000)
    		{
    			MemSize = 2
    		}
    
    	if (RawVidMemSize < 8000000)
    		{
    			MemSize = 4
    		}
    
    	if (RawVidMemSize < 12000000)
    		{
    			MemSize = 8
    		}
    
    	if (RawVidMemSize < 16000000)
    		{
    			MemSize = 12
    		}
    
    	if (RawVidMemSize < 32000000)
    		{
    			MemSize = 16
    		}
     
    	if (RawVidMemSize < 64000000)
    		{
    			MemSize = 32
    		}
    
    	if (RawVidMemSize > 64000000)
    		{
    			MemSize = 64
    		}
    }


For ones interested, here is actual control flow of the function from the IDA with my comments. [Full-size image][7] onclick.

[![Videocard memory size detection][8]][7]

Now it's time to actually look at what's happens inside this procedure. I've used a classical break & enter trick (patched the first instruction at `race.bin`'s entry point with `int3`), launched `NASCAR Heat Demo.exe` and waited for debugger to pop up. And that's when the things became clear.

Video memory size returned from `GetVidMemSizeFromDirectDraw()` is `0xFFFF0000` (`4294901760 bytes = 4095MB`) and it's has nothing to do with the real thing (should be 1Gb on my PC). It turns out that [DirectDraw is not well suited for the modern videocard\PC architecture][10]

> With the growth of physical memories both RAM and VRAM, this API is also having problems coping since it returns 32-bit DWORD counts of the size in bytes.

and [tends to report whatever it feels like][11]:
 
> You have a system with 1GB or greater of Video memory, and 4GB or greater of system memory (RAM).
> 
> You run the Direct-X Diagnostics tool, and it reports that you have an unexpectedly low amount of Approximate Total Memory on the display tab.
> 
> You may also see issues with some games or applications not allowing you to select the highest detail settings.
> 
> The API that DXDiag uses to approximate the system memory was not designed to handle systems in this configuration
> 
> On a system with 1GB of video memory, the following values are returned with the associated system memory:

	╔═══════════════╦═══════════════════════════════════╗
	║ System Memory ║ Reported Approximate Total Memory ║
	╠═══════════════╬═══════════════════════════════════╣
	║ 4GB           ║ 3496MB                            ║
	║ 6GB           ║ 454MB                             ║
	║ 8GB           ║ 1259MB                            ║
	╚═══════════════╩═══════════════════════════════════╝

So in my case it's just reports the value that almost fits into the 32-bit integer. And that's where the things go bad. Remember this line?

<!-- language: lang-c -->

    RawVidMemSize = RawVidMemSize + 614400

It becomes this:

<!-- language: lang-c -->
    
    RawVidMemSize = 4294901760 + 614400 (= 4295516160)


And `4295516160` is `548865` more than 32-bit value can handle (`0xFFFFFFFF = 4294967295`). Hence the integer overflow and the final result is `548864`. So now, the game thinks that my vidmem size is whopping **536KB** and refuses to run.

You can check this yourself in this [online x86 Assembly emulator][12]. Enter the code below, in right left corner click `Windows` and check `Registers` checkbox. Click the `Step` button and watch how `0xFFFF0000` in *EAX* register becomes `0x00086000` with `Carry` flag. If you click on register value it will toggle between hex and decimal representation of a number.

    mov    eax, 0xFFFF0000
    add    eax, 0x96000

### How do I fix it?

DirectDraw will probably never return a value more than 32-bit integer can handle<sup>1</sup> (it's seems to be capped to fit regardless of actual memory size. So the easiest way to fix this problem is to remove `RawVidMemSize = RawVidMemSize + 614400` operation from the code, so it wouldn't trigger the overflow. In executable it looks like this:

 - Assembly mnemonic: `add eax, 96000h`
 - Actual opcodes (hex): `0500600900`

To remove it we need to replace it with [NOP][13] instructions (hex: `90`). I already know the file offset, but it can be diferent in your executable. Fortunately, hex-string `0500600900` is unique in my `race.bin` and probably in yours. So get hex-editor (I recommend [HxD][14]: it's free, portable and easy to use) and open your `bin` file.

Do a hex-string search:

![hex-string search][15]

Once hex-string is found

![hex-string found][16]

Replace it with `90`

![Patch!][17]

Save the file. HxD will automatically create backup of the file, wich you can restore if something goes wrong.

In my case this was enough and I was able to start the game. Here is how `heat.log` looks after the patch:

> 21.33.564: ddraw: created directdraw with aticfx32.dll (AMD Radeon HD 5800 Series)  
> 21.33.564: ddraw: version 0.0.0.0  
> 21.34.296: vid: **64** meg card (reported:**4095.937500**)  
> 21.34.296: vid: using AGP textures (3231), total: 64  
> 21.34.305: vid: triple buffer on  

If your file by chance will contain several occurrences of `0500600900`, replace the first one, then try to start game and if doesn't work, restore file from backup and try next. Don't replace everything at once, this is not a good idea.

It's also have been [confirmed][18] that the same bug exists in [Viper Racing][19]. Viper Racing uses slightly different (older?) version of the game engine than Nascar but the bug is the same: it too tries to add `614400` bytes to the video memory size. The values to search are different because in this case compiler decided not to use registers and just accessed variable from stack, i.e.:

 - Assembly mnemonic: `add [esp+18h+var_14], 96000h`
 - Actual opcodes (hex): `8144240400600900`

### Happy driving!

 1. This is one of those *assumptions* I've been talking about.


  [1]: http://wiki.oni2.net/Troubleshooting/Blam
  [2]: http://www.fileplanet.com/48531/40000/fileinfo/NASCAR-Heat-Demo-v1.1
  [3]: http://www.ollydbg.de
  [4]: https://www.hex-rays.com/products/ida/support/download_freeware.shtml
  [5]: https://msdn.microsoft.com/en-us/library/ms682438.aspx
  [6]: Images/Sneaky_User.png?raw=true
  [7]: Images/IDA_Flow.png?raw=true
  [8]: Images/IDA_Flow_Preview.png?raw=true
  [10]: http://blogs.msdn.com/b/chuckw/archive/2010/06/16/wither-directdraw.aspx
  [11]: http://support2.microsoft.com/default.aspx?kbid=2026022
  [12]: http://carlosrafaelgn.com.br/Asm86/
  [13]: http://en.wikipedia.org/wiki/NOP
  [14]: http://mh-nexus.de/en/hxd
  [15]: Images/HxD_Search.png?raw=true
  [16]: Images/HxD_Found.png?raw=true
  [17]: Images/HxD_Fill_with_NOPs.png?raw=true
  [18]: http://www.vogons.org/viewtopic.php?f=8&t=41693
  [19]: http://en.wikipedia.org/wiki/Viper_Racing
