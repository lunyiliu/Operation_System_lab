
obj/kern/kernel：     文件格式 elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 20 19 10 f0       	push   $0xf0101920
f0100050:	e8 70 09 00 00       	call   f01009c5 <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 fc 06 00 00       	call   f0100777 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 3c 19 10 f0       	push   $0xf010193c
f0100087:	e8 39 09 00 00       	call   f01009c5 <cprintf>
}
f010008c:	83 c4 10             	add    $0x10,%esp
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 db 13 00 00       	call   f010148c <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 8f 04 00 00       	call   f0100545 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 57 19 10 f0       	push   $0xf0101957
f01000c3:	e8 fd 08 00 00       	call   f01009c5 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 5c 07 00 00       	call   f010083d <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000fd:	fa                   	cli    
f01000fe:	fc                   	cld    

	va_start(ap, fmt);
f01000ff:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100102:	83 ec 04             	sub    $0x4,%esp
f0100105:	ff 75 0c             	pushl  0xc(%ebp)
f0100108:	ff 75 08             	pushl  0x8(%ebp)
f010010b:	68 72 19 10 f0       	push   $0xf0101972
f0100110:	e8 b0 08 00 00       	call   f01009c5 <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 80 08 00 00       	call   f010099f <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 ae 19 10 f0 	movl   $0xf01019ae,(%esp)
f0100126:	e8 9a 08 00 00       	call   f01009c5 <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 05 07 00 00       	call   f010083d <monitor>
f0100138:	83 c4 10             	add    $0x10,%esp
f010013b:	eb f1                	jmp    f010012e <_panic+0x48>

f010013d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100144:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100147:	ff 75 0c             	pushl  0xc(%ebp)
f010014a:	ff 75 08             	pushl  0x8(%ebp)
f010014d:	68 8a 19 10 f0       	push   $0xf010198a
f0100152:	e8 6e 08 00 00       	call   f01009c5 <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 3c 08 00 00       	call   f010099f <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 ae 19 10 f0 	movl   $0xf01019ae,(%esp)
f010016a:	e8 56 08 00 00       	call   f01009c5 <cprintf>
	va_end(ap);
}
f010016f:	83 c4 10             	add    $0x10,%esp
f0100172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100175:	c9                   	leave  
f0100176:	c3                   	ret    

f0100177 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100177:	55                   	push   %ebp
f0100178:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010017f:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100180:	a8 01                	test   $0x1,%al
f0100182:	74 0b                	je     f010018f <serial_proc_data+0x18>
f0100184:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100189:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010018a:	0f b6 c0             	movzbl %al,%eax
f010018d:	eb 05                	jmp    f0100194 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010018f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100194:	5d                   	pop    %ebp
f0100195:	c3                   	ret    

f0100196 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100196:	55                   	push   %ebp
f0100197:	89 e5                	mov    %esp,%ebp
f0100199:	53                   	push   %ebx
f010019a:	83 ec 04             	sub    $0x4,%esp
f010019d:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019f:	eb 2b                	jmp    f01001cc <cons_intr+0x36>
		if (c == 0)
f01001a1:	85 c0                	test   %eax,%eax
f01001a3:	74 27                	je     f01001cc <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a5:	8b 0d 24 25 11 f0    	mov    0xf0112524,%ecx
f01001ab:	8d 51 01             	lea    0x1(%ecx),%edx
f01001ae:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
f01001b4:	88 81 20 23 11 f0    	mov    %al,-0xfeedce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001ba:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c0:	75 0a                	jne    f01001cc <cons_intr+0x36>
			cons.wpos = 0;
f01001c2:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001c9:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001cc:	ff d3                	call   *%ebx
f01001ce:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001d1:	75 ce                	jne    f01001a1 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d3:	83 c4 04             	add    $0x4,%esp
f01001d6:	5b                   	pop    %ebx
f01001d7:	5d                   	pop    %ebp
f01001d8:	c3                   	ret    

f01001d9 <kbd_proc_data>:
f01001d9:	ba 64 00 00 00       	mov    $0x64,%edx
f01001de:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001df:	a8 01                	test   $0x1,%al
f01001e1:	0f 84 f0 00 00 00    	je     f01002d7 <kbd_proc_data+0xfe>
f01001e7:	ba 60 00 00 00       	mov    $0x60,%edx
f01001ec:	ec                   	in     (%dx),%al
f01001ed:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001ef:	3c e0                	cmp    $0xe0,%al
f01001f1:	75 0d                	jne    f0100200 <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f01001f3:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f01001fa:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001ff:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100200:	55                   	push   %ebp
f0100201:	89 e5                	mov    %esp,%ebp
f0100203:	53                   	push   %ebx
f0100204:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100207:	84 c0                	test   %al,%al
f0100209:	79 36                	jns    f0100241 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010020b:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100211:	89 cb                	mov    %ecx,%ebx
f0100213:	83 e3 40             	and    $0x40,%ebx
f0100216:	83 e0 7f             	and    $0x7f,%eax
f0100219:	85 db                	test   %ebx,%ebx
f010021b:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010021e:	0f b6 d2             	movzbl %dl,%edx
f0100221:	0f b6 82 00 1b 10 f0 	movzbl -0xfefe500(%edx),%eax
f0100228:	83 c8 40             	or     $0x40,%eax
f010022b:	0f b6 c0             	movzbl %al,%eax
f010022e:	f7 d0                	not    %eax
f0100230:	21 c8                	and    %ecx,%eax
f0100232:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f0100237:	b8 00 00 00 00       	mov    $0x0,%eax
f010023c:	e9 9e 00 00 00       	jmp    f01002df <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f0100241:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100247:	f6 c1 40             	test   $0x40,%cl
f010024a:	74 0e                	je     f010025a <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010024c:	83 c8 80             	or     $0xffffff80,%eax
f010024f:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100251:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100254:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f010025a:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010025d:	0f b6 82 00 1b 10 f0 	movzbl -0xfefe500(%edx),%eax
f0100264:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f010026a:	0f b6 8a 00 1a 10 f0 	movzbl -0xfefe600(%edx),%ecx
f0100271:	31 c8                	xor    %ecx,%eax
f0100273:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100278:	89 c1                	mov    %eax,%ecx
f010027a:	83 e1 03             	and    $0x3,%ecx
f010027d:	8b 0c 8d e0 19 10 f0 	mov    -0xfefe620(,%ecx,4),%ecx
f0100284:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100288:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010028b:	a8 08                	test   $0x8,%al
f010028d:	74 1b                	je     f01002aa <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f010028f:	89 da                	mov    %ebx,%edx
f0100291:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100294:	83 f9 19             	cmp    $0x19,%ecx
f0100297:	77 05                	ja     f010029e <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f0100299:	83 eb 20             	sub    $0x20,%ebx
f010029c:	eb 0c                	jmp    f01002aa <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f010029e:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002a1:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002a4:	83 fa 19             	cmp    $0x19,%edx
f01002a7:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002aa:	f7 d0                	not    %eax
f01002ac:	a8 06                	test   $0x6,%al
f01002ae:	75 2d                	jne    f01002dd <kbd_proc_data+0x104>
f01002b0:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002b6:	75 25                	jne    f01002dd <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01002b8:	83 ec 0c             	sub    $0xc,%esp
f01002bb:	68 a4 19 10 f0       	push   $0xf01019a4
f01002c0:	e8 00 07 00 00       	call   f01009c5 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c5:	ba 92 00 00 00       	mov    $0x92,%edx
f01002ca:	b8 03 00 00 00       	mov    $0x3,%eax
f01002cf:	ee                   	out    %al,(%dx)
f01002d0:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
f01002d5:	eb 08                	jmp    f01002df <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002d7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002dc:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002dd:	89 d8                	mov    %ebx,%eax
}
f01002df:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002e2:	c9                   	leave  
f01002e3:	c3                   	ret    

f01002e4 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002e4:	55                   	push   %ebp
f01002e5:	89 e5                	mov    %esp,%ebp
f01002e7:	57                   	push   %edi
f01002e8:	56                   	push   %esi
f01002e9:	53                   	push   %ebx
f01002ea:	83 ec 1c             	sub    $0x1c,%esp
f01002ed:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002ef:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f4:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002f9:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002fe:	eb 09                	jmp    f0100309 <cons_putc+0x25>
f0100300:	89 ca                	mov    %ecx,%edx
f0100302:	ec                   	in     (%dx),%al
f0100303:	ec                   	in     (%dx),%al
f0100304:	ec                   	in     (%dx),%al
f0100305:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100306:	83 c3 01             	add    $0x1,%ebx
f0100309:	89 f2                	mov    %esi,%edx
f010030b:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010030c:	a8 20                	test   $0x20,%al
f010030e:	75 08                	jne    f0100318 <cons_putc+0x34>
f0100310:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100316:	7e e8                	jle    f0100300 <cons_putc+0x1c>
f0100318:	89 f8                	mov    %edi,%eax
f010031a:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010031d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100322:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100323:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100328:	be 79 03 00 00       	mov    $0x379,%esi
f010032d:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100332:	eb 09                	jmp    f010033d <cons_putc+0x59>
f0100334:	89 ca                	mov    %ecx,%edx
f0100336:	ec                   	in     (%dx),%al
f0100337:	ec                   	in     (%dx),%al
f0100338:	ec                   	in     (%dx),%al
f0100339:	ec                   	in     (%dx),%al
f010033a:	83 c3 01             	add    $0x1,%ebx
f010033d:	89 f2                	mov    %esi,%edx
f010033f:	ec                   	in     (%dx),%al
f0100340:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100346:	7f 04                	jg     f010034c <cons_putc+0x68>
f0100348:	84 c0                	test   %al,%al
f010034a:	79 e8                	jns    f0100334 <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010034c:	ba 78 03 00 00       	mov    $0x378,%edx
f0100351:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100355:	ee                   	out    %al,(%dx)
f0100356:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010035b:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100360:	ee                   	out    %al,(%dx)
f0100361:	b8 08 00 00 00       	mov    $0x8,%eax
f0100366:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100367:	89 fa                	mov    %edi,%edx
f0100369:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010036f:	89 f8                	mov    %edi,%eax
f0100371:	80 cc 07             	or     $0x7,%ah
f0100374:	85 d2                	test   %edx,%edx
f0100376:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100379:	89 f8                	mov    %edi,%eax
f010037b:	0f b6 c0             	movzbl %al,%eax
f010037e:	83 f8 09             	cmp    $0x9,%eax
f0100381:	74 74                	je     f01003f7 <cons_putc+0x113>
f0100383:	83 f8 09             	cmp    $0x9,%eax
f0100386:	7f 0a                	jg     f0100392 <cons_putc+0xae>
f0100388:	83 f8 08             	cmp    $0x8,%eax
f010038b:	74 14                	je     f01003a1 <cons_putc+0xbd>
f010038d:	e9 99 00 00 00       	jmp    f010042b <cons_putc+0x147>
f0100392:	83 f8 0a             	cmp    $0xa,%eax
f0100395:	74 3a                	je     f01003d1 <cons_putc+0xed>
f0100397:	83 f8 0d             	cmp    $0xd,%eax
f010039a:	74 3d                	je     f01003d9 <cons_putc+0xf5>
f010039c:	e9 8a 00 00 00       	jmp    f010042b <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f01003a1:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003a8:	66 85 c0             	test   %ax,%ax
f01003ab:	0f 84 e6 00 00 00    	je     f0100497 <cons_putc+0x1b3>
			crt_pos--;
f01003b1:	83 e8 01             	sub    $0x1,%eax
f01003b4:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003ba:	0f b7 c0             	movzwl %ax,%eax
f01003bd:	66 81 e7 00 ff       	and    $0xff00,%di
f01003c2:	83 cf 20             	or     $0x20,%edi
f01003c5:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003cb:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003cf:	eb 78                	jmp    f0100449 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003d1:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003d8:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003d9:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003e0:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003e6:	c1 e8 16             	shr    $0x16,%eax
f01003e9:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003ec:	c1 e0 04             	shl    $0x4,%eax
f01003ef:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f01003f5:	eb 52                	jmp    f0100449 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003f7:	b8 20 00 00 00       	mov    $0x20,%eax
f01003fc:	e8 e3 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f0100401:	b8 20 00 00 00       	mov    $0x20,%eax
f0100406:	e8 d9 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f010040b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100410:	e8 cf fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f0100415:	b8 20 00 00 00       	mov    $0x20,%eax
f010041a:	e8 c5 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f010041f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100424:	e8 bb fe ff ff       	call   f01002e4 <cons_putc>
f0100429:	eb 1e                	jmp    f0100449 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010042b:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100432:	8d 50 01             	lea    0x1(%eax),%edx
f0100435:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f010043c:	0f b7 c0             	movzwl %ax,%eax
f010043f:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100445:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100449:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f0100450:	cf 07 
f0100452:	76 43                	jbe    f0100497 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100454:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100459:	83 ec 04             	sub    $0x4,%esp
f010045c:	68 00 0f 00 00       	push   $0xf00
f0100461:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100467:	52                   	push   %edx
f0100468:	50                   	push   %eax
f0100469:	e8 6b 10 00 00       	call   f01014d9 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010046e:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100474:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010047a:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100480:	83 c4 10             	add    $0x10,%esp
f0100483:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100488:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010048b:	39 d0                	cmp    %edx,%eax
f010048d:	75 f4                	jne    f0100483 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010048f:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f0100496:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100497:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f010049d:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004a2:	89 ca                	mov    %ecx,%edx
f01004a4:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004a5:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004ac:	8d 71 01             	lea    0x1(%ecx),%esi
f01004af:	89 d8                	mov    %ebx,%eax
f01004b1:	66 c1 e8 08          	shr    $0x8,%ax
f01004b5:	89 f2                	mov    %esi,%edx
f01004b7:	ee                   	out    %al,(%dx)
f01004b8:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004bd:	89 ca                	mov    %ecx,%edx
f01004bf:	ee                   	out    %al,(%dx)
f01004c0:	89 d8                	mov    %ebx,%eax
f01004c2:	89 f2                	mov    %esi,%edx
f01004c4:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004c5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004c8:	5b                   	pop    %ebx
f01004c9:	5e                   	pop    %esi
f01004ca:	5f                   	pop    %edi
f01004cb:	5d                   	pop    %ebp
f01004cc:	c3                   	ret    

f01004cd <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004cd:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004d4:	74 11                	je     f01004e7 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004d6:	55                   	push   %ebp
f01004d7:	89 e5                	mov    %esp,%ebp
f01004d9:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004dc:	b8 77 01 10 f0       	mov    $0xf0100177,%eax
f01004e1:	e8 b0 fc ff ff       	call   f0100196 <cons_intr>
}
f01004e6:	c9                   	leave  
f01004e7:	f3 c3                	repz ret 

f01004e9 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004e9:	55                   	push   %ebp
f01004ea:	89 e5                	mov    %esp,%ebp
f01004ec:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004ef:	b8 d9 01 10 f0       	mov    $0xf01001d9,%eax
f01004f4:	e8 9d fc ff ff       	call   f0100196 <cons_intr>
}
f01004f9:	c9                   	leave  
f01004fa:	c3                   	ret    

f01004fb <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004fb:	55                   	push   %ebp
f01004fc:	89 e5                	mov    %esp,%ebp
f01004fe:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100501:	e8 c7 ff ff ff       	call   f01004cd <serial_intr>
	kbd_intr();
f0100506:	e8 de ff ff ff       	call   f01004e9 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010050b:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f0100510:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100516:	74 26                	je     f010053e <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100518:	8d 50 01             	lea    0x1(%eax),%edx
f010051b:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f0100521:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100528:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f010052a:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100530:	75 11                	jne    f0100543 <cons_getc+0x48>
			cons.rpos = 0;
f0100532:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100539:	00 00 00 
f010053c:	eb 05                	jmp    f0100543 <cons_getc+0x48>
		return c;
	}
	return 0;
f010053e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100543:	c9                   	leave  
f0100544:	c3                   	ret    

f0100545 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100545:	55                   	push   %ebp
f0100546:	89 e5                	mov    %esp,%ebp
f0100548:	57                   	push   %edi
f0100549:	56                   	push   %esi
f010054a:	53                   	push   %ebx
f010054b:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010054e:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100555:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010055c:	5a a5 
	if (*cp != 0xA55A) {
f010055e:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100565:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100569:	74 11                	je     f010057c <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010056b:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f0100572:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100575:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010057a:	eb 16                	jmp    f0100592 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010057c:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100583:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f010058a:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010058d:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100592:	8b 3d 30 25 11 f0    	mov    0xf0112530,%edi
f0100598:	b8 0e 00 00 00       	mov    $0xe,%eax
f010059d:	89 fa                	mov    %edi,%edx
f010059f:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005a0:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005a3:	89 da                	mov    %ebx,%edx
f01005a5:	ec                   	in     (%dx),%al
f01005a6:	0f b6 c8             	movzbl %al,%ecx
f01005a9:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ac:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005b1:	89 fa                	mov    %edi,%edx
f01005b3:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005b4:	89 da                	mov    %ebx,%edx
f01005b6:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005b7:	89 35 2c 25 11 f0    	mov    %esi,0xf011252c
	crt_pos = pos;
f01005bd:	0f b6 c0             	movzbl %al,%eax
f01005c0:	09 c8                	or     %ecx,%eax
f01005c2:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c8:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005cd:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d2:	89 f2                	mov    %esi,%edx
f01005d4:	ee                   	out    %al,(%dx)
f01005d5:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005da:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005df:	ee                   	out    %al,(%dx)
f01005e0:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005e5:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005ea:	89 da                	mov    %ebx,%edx
f01005ec:	ee                   	out    %al,(%dx)
f01005ed:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005f2:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f7:	ee                   	out    %al,(%dx)
f01005f8:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005fd:	b8 03 00 00 00       	mov    $0x3,%eax
f0100602:	ee                   	out    %al,(%dx)
f0100603:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100608:	b8 00 00 00 00       	mov    $0x0,%eax
f010060d:	ee                   	out    %al,(%dx)
f010060e:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100613:	b8 01 00 00 00       	mov    $0x1,%eax
f0100618:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100619:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010061e:	ec                   	in     (%dx),%al
f010061f:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100621:	3c ff                	cmp    $0xff,%al
f0100623:	0f 95 05 34 25 11 f0 	setne  0xf0112534
f010062a:	89 f2                	mov    %esi,%edx
f010062c:	ec                   	in     (%dx),%al
f010062d:	89 da                	mov    %ebx,%edx
f010062f:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100630:	80 f9 ff             	cmp    $0xff,%cl
f0100633:	75 10                	jne    f0100645 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f0100635:	83 ec 0c             	sub    $0xc,%esp
f0100638:	68 b0 19 10 f0       	push   $0xf01019b0
f010063d:	e8 83 03 00 00       	call   f01009c5 <cprintf>
f0100642:	83 c4 10             	add    $0x10,%esp
}
f0100645:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100648:	5b                   	pop    %ebx
f0100649:	5e                   	pop    %esi
f010064a:	5f                   	pop    %edi
f010064b:	5d                   	pop    %ebp
f010064c:	c3                   	ret    

f010064d <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010064d:	55                   	push   %ebp
f010064e:	89 e5                	mov    %esp,%ebp
f0100650:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100653:	8b 45 08             	mov    0x8(%ebp),%eax
f0100656:	e8 89 fc ff ff       	call   f01002e4 <cons_putc>
}
f010065b:	c9                   	leave  
f010065c:	c3                   	ret    

f010065d <getchar>:

int
getchar(void)
{
f010065d:	55                   	push   %ebp
f010065e:	89 e5                	mov    %esp,%ebp
f0100660:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100663:	e8 93 fe ff ff       	call   f01004fb <cons_getc>
f0100668:	85 c0                	test   %eax,%eax
f010066a:	74 f7                	je     f0100663 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010066c:	c9                   	leave  
f010066d:	c3                   	ret    

f010066e <iscons>:

int
iscons(int fdnum)
{
f010066e:	55                   	push   %ebp
f010066f:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100671:	b8 01 00 00 00       	mov    $0x1,%eax
f0100676:	5d                   	pop    %ebp
f0100677:	c3                   	ret    

f0100678 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100678:	55                   	push   %ebp
f0100679:	89 e5                	mov    %esp,%ebp
f010067b:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010067e:	68 00 1c 10 f0       	push   $0xf0101c00
f0100683:	68 1e 1c 10 f0       	push   $0xf0101c1e
f0100688:	68 23 1c 10 f0       	push   $0xf0101c23
f010068d:	e8 33 03 00 00       	call   f01009c5 <cprintf>
f0100692:	83 c4 0c             	add    $0xc,%esp
f0100695:	68 e8 1c 10 f0       	push   $0xf0101ce8
f010069a:	68 2c 1c 10 f0       	push   $0xf0101c2c
f010069f:	68 23 1c 10 f0       	push   $0xf0101c23
f01006a4:	e8 1c 03 00 00       	call   f01009c5 <cprintf>
f01006a9:	83 c4 0c             	add    $0xc,%esp
f01006ac:	68 35 1c 10 f0       	push   $0xf0101c35
f01006b1:	68 48 1c 10 f0       	push   $0xf0101c48
f01006b6:	68 23 1c 10 f0       	push   $0xf0101c23
f01006bb:	e8 05 03 00 00       	call   f01009c5 <cprintf>
	return 0;
}
f01006c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01006c5:	c9                   	leave  
f01006c6:	c3                   	ret    

f01006c7 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006c7:	55                   	push   %ebp
f01006c8:	89 e5                	mov    %esp,%ebp
f01006ca:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006cd:	68 52 1c 10 f0       	push   $0xf0101c52
f01006d2:	e8 ee 02 00 00       	call   f01009c5 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006d7:	83 c4 08             	add    $0x8,%esp
f01006da:	68 0c 00 10 00       	push   $0x10000c
f01006df:	68 10 1d 10 f0       	push   $0xf0101d10
f01006e4:	e8 dc 02 00 00       	call   f01009c5 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006e9:	83 c4 0c             	add    $0xc,%esp
f01006ec:	68 0c 00 10 00       	push   $0x10000c
f01006f1:	68 0c 00 10 f0       	push   $0xf010000c
f01006f6:	68 38 1d 10 f0       	push   $0xf0101d38
f01006fb:	e8 c5 02 00 00       	call   f01009c5 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100700:	83 c4 0c             	add    $0xc,%esp
f0100703:	68 11 19 10 00       	push   $0x101911
f0100708:	68 11 19 10 f0       	push   $0xf0101911
f010070d:	68 5c 1d 10 f0       	push   $0xf0101d5c
f0100712:	e8 ae 02 00 00       	call   f01009c5 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100717:	83 c4 0c             	add    $0xc,%esp
f010071a:	68 00 23 11 00       	push   $0x112300
f010071f:	68 00 23 11 f0       	push   $0xf0112300
f0100724:	68 80 1d 10 f0       	push   $0xf0101d80
f0100729:	e8 97 02 00 00       	call   f01009c5 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010072e:	83 c4 0c             	add    $0xc,%esp
f0100731:	68 44 29 11 00       	push   $0x112944
f0100736:	68 44 29 11 f0       	push   $0xf0112944
f010073b:	68 a4 1d 10 f0       	push   $0xf0101da4
f0100740:	e8 80 02 00 00       	call   f01009c5 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100745:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f010074a:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010074f:	83 c4 08             	add    $0x8,%esp
f0100752:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100757:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010075d:	85 c0                	test   %eax,%eax
f010075f:	0f 48 c2             	cmovs  %edx,%eax
f0100762:	c1 f8 0a             	sar    $0xa,%eax
f0100765:	50                   	push   %eax
f0100766:	68 c8 1d 10 f0       	push   $0xf0101dc8
f010076b:	e8 55 02 00 00       	call   f01009c5 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100770:	b8 00 00 00 00       	mov    $0x0,%eax
f0100775:	c9                   	leave  
f0100776:	c3                   	ret    

f0100777 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100777:	55                   	push   %ebp
f0100778:	89 e5                	mov    %esp,%ebp
f010077a:	57                   	push   %edi
f010077b:	56                   	push   %esi
f010077c:	53                   	push   %ebx
f010077d:	83 ec 38             	sub    $0x38,%esp
	cprintf("Stack backtrace:\n");
f0100780:	68 6b 1c 10 f0       	push   $0xf0101c6b
f0100785:	e8 3b 02 00 00       	call   f01009c5 <cprintf>
f010078a:	83 c4 10             	add    $0x10,%esp
		uint32_t arg4=*(int*)(ebp+20);
		uint32_t arg5=*(int*)(ebp+24);
		cprintf("ebp %x  eip %x  args %08x %08x %08x %08x %08x\n",ebp,eip,arg1,arg2,arg3,arg4,arg5);
		struct Eipdebuginfo info_={"<unknown>",0,"<unknown>",9,0,0};
		struct Eipdebuginfo* info= &info_;
		debuginfo_eip(eip,info);
f010078d:	8d 75 d0             	lea    -0x30(%ebp),%esi
f0100790:	eb 05                	jmp    f0100797 <mon_backtrace+0x20>
{
	cprintf("Stack backtrace:\n");
	uint32_t ebp=0xffffffff;
	//cprintf("%x\n",read_ebp());
	while(ebp!=0){
	if(ebp==0xffffffff){
f0100792:	83 fb ff             	cmp    $0xffffffff,%ebx
f0100795:	75 04                	jne    f010079b <mon_backtrace+0x24>

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100797:	89 eb                	mov    %ebp,%ebx
f0100799:	eb 02                	jmp    f010079d <mon_backtrace+0x26>
		ebp=read_ebp();
	}
		else{
		ebp=*(int*)ebp;
f010079b:	8b 1b                	mov    (%ebx),%ebx
		}
		uint32_t eip=*(int*)(ebp+4);
f010079d:	8b 7b 04             	mov    0x4(%ebx),%edi
		uint32_t arg1=*(int*)(ebp+8);
		uint32_t arg2=*(int*)(ebp+12);
		uint32_t arg3=*(int*)(ebp+16);
		uint32_t arg4=*(int*)(ebp+20);
		uint32_t arg5=*(int*)(ebp+24);
		cprintf("ebp %x  eip %x  args %08x %08x %08x %08x %08x\n",ebp,eip,arg1,arg2,arg3,arg4,arg5);
f01007a0:	ff 73 18             	pushl  0x18(%ebx)
f01007a3:	ff 73 14             	pushl  0x14(%ebx)
f01007a6:	ff 73 10             	pushl  0x10(%ebx)
f01007a9:	ff 73 0c             	pushl  0xc(%ebx)
f01007ac:	ff 73 08             	pushl  0x8(%ebx)
f01007af:	57                   	push   %edi
f01007b0:	53                   	push   %ebx
f01007b1:	68 f4 1d 10 f0       	push   $0xf0101df4
f01007b6:	e8 0a 02 00 00       	call   f01009c5 <cprintf>
		struct Eipdebuginfo info_={"<unknown>",0,"<unknown>",9,0,0};
f01007bb:	c7 45 d0 7d 1c 10 f0 	movl   $0xf0101c7d,-0x30(%ebp)
f01007c2:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f01007c9:	c7 45 d8 7d 1c 10 f0 	movl   $0xf0101c7d,-0x28(%ebp)
f01007d0:	c7 45 dc 09 00 00 00 	movl   $0x9,-0x24(%ebp)
f01007d7:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01007de:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		struct Eipdebuginfo* info= &info_;
		debuginfo_eip(eip,info);
f01007e5:	83 c4 18             	add    $0x18,%esp
f01007e8:	56                   	push   %esi
f01007e9:	57                   	push   %edi
f01007ea:	e8 e0 02 00 00       	call   f0100acf <debuginfo_eip>
		//*(p)='\0';
		cprintf("       %s:%d: ",info->eip_file,info->eip_line );
f01007ef:	83 c4 0c             	add    $0xc,%esp
f01007f2:	ff 75 d4             	pushl  -0x2c(%ebp)
f01007f5:	ff 75 d0             	pushl  -0x30(%ebp)
f01007f8:	68 87 1c 10 f0       	push   $0xf0101c87
f01007fd:	e8 c3 01 00 00       	call   f01009c5 <cprintf>
		cprintf("%.*s",info->eip_fn_namelen,info->eip_fn_name);
f0100802:	83 c4 0c             	add    $0xc,%esp
f0100805:	ff 75 d8             	pushl  -0x28(%ebp)
f0100808:	ff 75 dc             	pushl  -0x24(%ebp)
f010080b:	68 96 1c 10 f0       	push   $0xf0101c96
f0100810:	e8 b0 01 00 00       	call   f01009c5 <cprintf>
		cprintf("+%d\n",info->eip_fn_narg);
f0100815:	83 c4 08             	add    $0x8,%esp
f0100818:	ff 75 e4             	pushl  -0x1c(%ebp)
f010081b:	68 9b 1c 10 f0       	push   $0xf0101c9b
f0100820:	e8 a0 01 00 00       	call   f01009c5 <cprintf>
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	cprintf("Stack backtrace:\n");
	uint32_t ebp=0xffffffff;
	//cprintf("%x\n",read_ebp());
	while(ebp!=0){
f0100825:	83 c4 10             	add    $0x10,%esp
f0100828:	85 db                	test   %ebx,%ebx
f010082a:	0f 85 62 ff ff ff    	jne    f0100792 <mon_backtrace+0x1b>
		cprintf("       %s:%d: ",info->eip_file,info->eip_line );
		cprintf("%.*s",info->eip_fn_namelen,info->eip_fn_name);
		cprintf("+%d\n",info->eip_fn_narg);
	}
	return 0;
}
f0100830:	b8 00 00 00 00       	mov    $0x0,%eax
f0100835:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100838:	5b                   	pop    %ebx
f0100839:	5e                   	pop    %esi
f010083a:	5f                   	pop    %edi
f010083b:	5d                   	pop    %ebp
f010083c:	c3                   	ret    

f010083d <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010083d:	55                   	push   %ebp
f010083e:	89 e5                	mov    %esp,%ebp
f0100840:	57                   	push   %edi
f0100841:	56                   	push   %esi
f0100842:	53                   	push   %ebx
f0100843:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100846:	68 24 1e 10 f0       	push   $0xf0101e24
f010084b:	e8 75 01 00 00       	call   f01009c5 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100850:	c7 04 24 48 1e 10 f0 	movl   $0xf0101e48,(%esp)
f0100857:	e8 69 01 00 00       	call   f01009c5 <cprintf>
    cprintf("x=%d y=%d", 3);
f010085c:	83 c4 08             	add    $0x8,%esp
f010085f:	6a 03                	push   $0x3
f0100861:	68 a0 1c 10 f0       	push   $0xf0101ca0
f0100866:	e8 5a 01 00 00       	call   f01009c5 <cprintf>
cprintf("\n");
f010086b:	c7 04 24 ae 19 10 f0 	movl   $0xf01019ae,(%esp)
f0100872:	e8 4e 01 00 00       	call   f01009c5 <cprintf>
f0100877:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f010087a:	83 ec 0c             	sub    $0xc,%esp
f010087d:	68 aa 1c 10 f0       	push   $0xf0101caa
f0100882:	e8 ae 09 00 00       	call   f0101235 <readline>
f0100887:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100889:	83 c4 10             	add    $0x10,%esp
f010088c:	85 c0                	test   %eax,%eax
f010088e:	74 ea                	je     f010087a <monitor+0x3d>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100890:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100897:	be 00 00 00 00       	mov    $0x0,%esi
f010089c:	eb 0a                	jmp    f01008a8 <monitor+0x6b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010089e:	c6 03 00             	movb   $0x0,(%ebx)
f01008a1:	89 f7                	mov    %esi,%edi
f01008a3:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01008a6:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008a8:	0f b6 03             	movzbl (%ebx),%eax
f01008ab:	84 c0                	test   %al,%al
f01008ad:	74 63                	je     f0100912 <monitor+0xd5>
f01008af:	83 ec 08             	sub    $0x8,%esp
f01008b2:	0f be c0             	movsbl %al,%eax
f01008b5:	50                   	push   %eax
f01008b6:	68 ae 1c 10 f0       	push   $0xf0101cae
f01008bb:	e8 8f 0b 00 00       	call   f010144f <strchr>
f01008c0:	83 c4 10             	add    $0x10,%esp
f01008c3:	85 c0                	test   %eax,%eax
f01008c5:	75 d7                	jne    f010089e <monitor+0x61>
			*buf++ = 0;
		if (*buf == 0)
f01008c7:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008ca:	74 46                	je     f0100912 <monitor+0xd5>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008cc:	83 fe 0f             	cmp    $0xf,%esi
f01008cf:	75 14                	jne    f01008e5 <monitor+0xa8>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008d1:	83 ec 08             	sub    $0x8,%esp
f01008d4:	6a 10                	push   $0x10
f01008d6:	68 b3 1c 10 f0       	push   $0xf0101cb3
f01008db:	e8 e5 00 00 00       	call   f01009c5 <cprintf>
f01008e0:	83 c4 10             	add    $0x10,%esp
f01008e3:	eb 95                	jmp    f010087a <monitor+0x3d>
			return 0;
		}
		argv[argc++] = buf;
f01008e5:	8d 7e 01             	lea    0x1(%esi),%edi
f01008e8:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008ec:	eb 03                	jmp    f01008f1 <monitor+0xb4>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008ee:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008f1:	0f b6 03             	movzbl (%ebx),%eax
f01008f4:	84 c0                	test   %al,%al
f01008f6:	74 ae                	je     f01008a6 <monitor+0x69>
f01008f8:	83 ec 08             	sub    $0x8,%esp
f01008fb:	0f be c0             	movsbl %al,%eax
f01008fe:	50                   	push   %eax
f01008ff:	68 ae 1c 10 f0       	push   $0xf0101cae
f0100904:	e8 46 0b 00 00       	call   f010144f <strchr>
f0100909:	83 c4 10             	add    $0x10,%esp
f010090c:	85 c0                	test   %eax,%eax
f010090e:	74 de                	je     f01008ee <monitor+0xb1>
f0100910:	eb 94                	jmp    f01008a6 <monitor+0x69>
			buf++;
	}
	argv[argc] = 0;
f0100912:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100919:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010091a:	85 f6                	test   %esi,%esi
f010091c:	0f 84 58 ff ff ff    	je     f010087a <monitor+0x3d>
f0100922:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100927:	83 ec 08             	sub    $0x8,%esp
f010092a:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010092d:	ff 34 85 80 1e 10 f0 	pushl  -0xfefe180(,%eax,4)
f0100934:	ff 75 a8             	pushl  -0x58(%ebp)
f0100937:	e8 b5 0a 00 00       	call   f01013f1 <strcmp>
f010093c:	83 c4 10             	add    $0x10,%esp
f010093f:	85 c0                	test   %eax,%eax
f0100941:	75 21                	jne    f0100964 <monitor+0x127>
			return commands[i].func(argc, argv, tf);
f0100943:	83 ec 04             	sub    $0x4,%esp
f0100946:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100949:	ff 75 08             	pushl  0x8(%ebp)
f010094c:	8d 55 a8             	lea    -0x58(%ebp),%edx
f010094f:	52                   	push   %edx
f0100950:	56                   	push   %esi
f0100951:	ff 14 85 88 1e 10 f0 	call   *-0xfefe178(,%eax,4)
cprintf("\n");

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100958:	83 c4 10             	add    $0x10,%esp
f010095b:	85 c0                	test   %eax,%eax
f010095d:	78 25                	js     f0100984 <monitor+0x147>
f010095f:	e9 16 ff ff ff       	jmp    f010087a <monitor+0x3d>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100964:	83 c3 01             	add    $0x1,%ebx
f0100967:	83 fb 03             	cmp    $0x3,%ebx
f010096a:	75 bb                	jne    f0100927 <monitor+0xea>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010096c:	83 ec 08             	sub    $0x8,%esp
f010096f:	ff 75 a8             	pushl  -0x58(%ebp)
f0100972:	68 d0 1c 10 f0       	push   $0xf0101cd0
f0100977:	e8 49 00 00 00       	call   f01009c5 <cprintf>
f010097c:	83 c4 10             	add    $0x10,%esp
f010097f:	e9 f6 fe ff ff       	jmp    f010087a <monitor+0x3d>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100984:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100987:	5b                   	pop    %ebx
f0100988:	5e                   	pop    %esi
f0100989:	5f                   	pop    %edi
f010098a:	5d                   	pop    %ebp
f010098b:	c3                   	ret    

f010098c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010098c:	55                   	push   %ebp
f010098d:	89 e5                	mov    %esp,%ebp
f010098f:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0100992:	ff 75 08             	pushl  0x8(%ebp)
f0100995:	e8 b3 fc ff ff       	call   f010064d <cputchar>
	*cnt++;
}
f010099a:	83 c4 10             	add    $0x10,%esp
f010099d:	c9                   	leave  
f010099e:	c3                   	ret    

f010099f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010099f:	55                   	push   %ebp
f01009a0:	89 e5                	mov    %esp,%ebp
f01009a2:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01009a5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009ac:	ff 75 0c             	pushl  0xc(%ebp)
f01009af:	ff 75 08             	pushl  0x8(%ebp)
f01009b2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009b5:	50                   	push   %eax
f01009b6:	68 8c 09 10 f0       	push   $0xf010098c
f01009bb:	e8 60 04 00 00       	call   f0100e20 <vprintfmt>
	return cnt;
}
f01009c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009c3:	c9                   	leave  
f01009c4:	c3                   	ret    

f01009c5 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009c5:	55                   	push   %ebp
f01009c6:	89 e5                	mov    %esp,%ebp
f01009c8:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009cb:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009ce:	50                   	push   %eax
f01009cf:	ff 75 08             	pushl  0x8(%ebp)
f01009d2:	e8 c8 ff ff ff       	call   f010099f <vcprintf>
	va_end(ap);

	return cnt;
}
f01009d7:	c9                   	leave  
f01009d8:	c3                   	ret    

f01009d9 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009d9:	55                   	push   %ebp
f01009da:	89 e5                	mov    %esp,%ebp
f01009dc:	57                   	push   %edi
f01009dd:	56                   	push   %esi
f01009de:	53                   	push   %ebx
f01009df:	83 ec 14             	sub    $0x14,%esp
f01009e2:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01009e5:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01009e8:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01009eb:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01009ee:	8b 1a                	mov    (%edx),%ebx
f01009f0:	8b 01                	mov    (%ecx),%eax
f01009f2:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009f5:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01009fc:	eb 7f                	jmp    f0100a7d <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01009fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a01:	01 d8                	add    %ebx,%eax
f0100a03:	89 c6                	mov    %eax,%esi
f0100a05:	c1 ee 1f             	shr    $0x1f,%esi
f0100a08:	01 c6                	add    %eax,%esi
f0100a0a:	d1 fe                	sar    %esi
f0100a0c:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100a0f:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a12:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0100a15:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a17:	eb 03                	jmp    f0100a1c <stab_binsearch+0x43>
			m--;
f0100a19:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a1c:	39 c3                	cmp    %eax,%ebx
f0100a1e:	7f 0d                	jg     f0100a2d <stab_binsearch+0x54>
f0100a20:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100a24:	83 ea 0c             	sub    $0xc,%edx
f0100a27:	39 f9                	cmp    %edi,%ecx
f0100a29:	75 ee                	jne    f0100a19 <stab_binsearch+0x40>
f0100a2b:	eb 05                	jmp    f0100a32 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a2d:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0100a30:	eb 4b                	jmp    f0100a7d <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a32:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a35:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a38:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100a3c:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a3f:	76 11                	jbe    f0100a52 <stab_binsearch+0x79>
			*region_left = m;
f0100a41:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100a44:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100a46:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a49:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a50:	eb 2b                	jmp    f0100a7d <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a52:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a55:	73 14                	jae    f0100a6b <stab_binsearch+0x92>
			*region_right = m - 1;
f0100a57:	83 e8 01             	sub    $0x1,%eax
f0100a5a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a5d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a60:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a62:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a69:	eb 12                	jmp    f0100a7d <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a6b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a6e:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100a70:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100a74:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a76:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a7d:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a80:	0f 8e 78 ff ff ff    	jle    f01009fe <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a86:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100a8a:	75 0f                	jne    f0100a9b <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0100a8c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a8f:	8b 00                	mov    (%eax),%eax
f0100a91:	83 e8 01             	sub    $0x1,%eax
f0100a94:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a97:	89 06                	mov    %eax,(%esi)
f0100a99:	eb 2c                	jmp    f0100ac7 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a9b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a9e:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100aa0:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100aa3:	8b 0e                	mov    (%esi),%ecx
f0100aa5:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100aa8:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100aab:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100aae:	eb 03                	jmp    f0100ab3 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100ab0:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ab3:	39 c8                	cmp    %ecx,%eax
f0100ab5:	7e 0b                	jle    f0100ac2 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0100ab7:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100abb:	83 ea 0c             	sub    $0xc,%edx
f0100abe:	39 df                	cmp    %ebx,%edi
f0100ac0:	75 ee                	jne    f0100ab0 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100ac2:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100ac5:	89 06                	mov    %eax,(%esi)
	}
}
f0100ac7:	83 c4 14             	add    $0x14,%esp
f0100aca:	5b                   	pop    %ebx
f0100acb:	5e                   	pop    %esi
f0100acc:	5f                   	pop    %edi
f0100acd:	5d                   	pop    %ebp
f0100ace:	c3                   	ret    

f0100acf <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100acf:	55                   	push   %ebp
f0100ad0:	89 e5                	mov    %esp,%ebp
f0100ad2:	57                   	push   %edi
f0100ad3:	56                   	push   %esi
f0100ad4:	53                   	push   %ebx
f0100ad5:	83 ec 3c             	sub    $0x3c,%esp
f0100ad8:	8b 75 08             	mov    0x8(%ebp),%esi
f0100adb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100ade:	c7 03 7d 1c 10 f0    	movl   $0xf0101c7d,(%ebx)
	info->eip_line = 0;
f0100ae4:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100aeb:	c7 43 08 7d 1c 10 f0 	movl   $0xf0101c7d,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100af2:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100af9:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100afc:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b03:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b09:	76 11                	jbe    f0100b1c <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b0b:	b8 ea 73 10 f0       	mov    $0xf01073ea,%eax
f0100b10:	3d bd 5a 10 f0       	cmp    $0xf0105abd,%eax
f0100b15:	77 19                	ja     f0100b30 <debuginfo_eip+0x61>
f0100b17:	e9 b8 01 00 00       	jmp    f0100cd4 <debuginfo_eip+0x205>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b1c:	83 ec 04             	sub    $0x4,%esp
f0100b1f:	68 a4 1e 10 f0       	push   $0xf0101ea4
f0100b24:	6a 7f                	push   $0x7f
f0100b26:	68 b1 1e 10 f0       	push   $0xf0101eb1
f0100b2b:	e8 b6 f5 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b30:	80 3d e9 73 10 f0 00 	cmpb   $0x0,0xf01073e9
f0100b37:	0f 85 9e 01 00 00    	jne    f0100cdb <debuginfo_eip+0x20c>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b3d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b44:	b8 bc 5a 10 f0       	mov    $0xf0105abc,%eax
f0100b49:	2d f0 20 10 f0       	sub    $0xf01020f0,%eax
f0100b4e:	c1 f8 02             	sar    $0x2,%eax
f0100b51:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b57:	83 e8 01             	sub    $0x1,%eax
f0100b5a:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b5d:	83 ec 08             	sub    $0x8,%esp
f0100b60:	56                   	push   %esi
f0100b61:	6a 64                	push   $0x64
f0100b63:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b66:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b69:	b8 f0 20 10 f0       	mov    $0xf01020f0,%eax
f0100b6e:	e8 66 fe ff ff       	call   f01009d9 <stab_binsearch>
	if (lfile == 0)
f0100b73:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b76:	83 c4 10             	add    $0x10,%esp
f0100b79:	85 c0                	test   %eax,%eax
f0100b7b:	0f 84 61 01 00 00    	je     f0100ce2 <debuginfo_eip+0x213>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b81:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b84:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b87:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b8a:	83 ec 08             	sub    $0x8,%esp
f0100b8d:	56                   	push   %esi
f0100b8e:	6a 24                	push   $0x24
f0100b90:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b93:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b96:	b8 f0 20 10 f0       	mov    $0xf01020f0,%eax
f0100b9b:	e8 39 fe ff ff       	call   f01009d9 <stab_binsearch>

	if (lfun <= rfun) {
f0100ba0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100ba3:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100ba6:	83 c4 10             	add    $0x10,%esp
f0100ba9:	39 d0                	cmp    %edx,%eax
f0100bab:	7f 40                	jg     f0100bed <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100bad:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100bb0:	c1 e1 02             	shl    $0x2,%ecx
f0100bb3:	8d b9 f0 20 10 f0    	lea    -0xfefdf10(%ecx),%edi
f0100bb9:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100bbc:	8b b9 f0 20 10 f0    	mov    -0xfefdf10(%ecx),%edi
f0100bc2:	b9 ea 73 10 f0       	mov    $0xf01073ea,%ecx
f0100bc7:	81 e9 bd 5a 10 f0    	sub    $0xf0105abd,%ecx
f0100bcd:	39 cf                	cmp    %ecx,%edi
f0100bcf:	73 09                	jae    f0100bda <debuginfo_eip+0x10b>
		{info->eip_fn_name = stabstr + stabs[lfun].n_strx;}
f0100bd1:	81 c7 bd 5a 10 f0    	add    $0xf0105abd,%edi
f0100bd7:	89 7b 08             	mov    %edi,0x8(%ebx)
				
		info->eip_fn_addr = stabs[lfun].n_value;
f0100bda:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100bdd:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100be0:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100be3:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100be5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100be8:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100beb:	eb 0f                	jmp    f0100bfc <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bed:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100bf0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bf3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100bf6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bf9:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bfc:	83 ec 08             	sub    $0x8,%esp
f0100bff:	6a 3a                	push   $0x3a
f0100c01:	ff 73 08             	pushl  0x8(%ebx)
f0100c04:	e8 67 08 00 00       	call   f0101470 <strfind>
f0100c09:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c0c:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
		stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100c0f:	83 c4 08             	add    $0x8,%esp
f0100c12:	56                   	push   %esi
f0100c13:	6a 44                	push   $0x44
f0100c15:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100c18:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100c1b:	b8 f0 20 10 f0       	mov    $0xf01020f0,%eax
f0100c20:	e8 b4 fd ff ff       	call   f01009d9 <stab_binsearch>
	if(lline<=rline){
f0100c25:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c28:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100c2b:	83 c4 10             	add    $0x10,%esp
f0100c2e:	39 d0                	cmp    %edx,%eax
f0100c30:	0f 8f b3 00 00 00    	jg     f0100ce9 <debuginfo_eip+0x21a>
		info->eip_line = stabs[rline].n_desc;}
f0100c36:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100c39:	0f b7 14 95 f6 20 10 	movzwl -0xfefdf0a(,%edx,4),%edx
f0100c40:	f0 
f0100c41:	89 53 04             	mov    %edx,0x4(%ebx)
	else{
	return -1;}
info->eip_fn_narg=addr;
f0100c44:	89 73 14             	mov    %esi,0x14(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c47:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c4a:	89 c2                	mov    %eax,%edx
f0100c4c:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100c4f:	8d 04 85 f0 20 10 f0 	lea    -0xfefdf10(,%eax,4),%eax
f0100c56:	eb 06                	jmp    f0100c5e <debuginfo_eip+0x18f>
f0100c58:	83 ea 01             	sub    $0x1,%edx
f0100c5b:	83 e8 0c             	sub    $0xc,%eax
f0100c5e:	39 d7                	cmp    %edx,%edi
f0100c60:	7f 34                	jg     f0100c96 <debuginfo_eip+0x1c7>
	       && stabs[lline].n_type != N_SOL
f0100c62:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100c66:	80 f9 84             	cmp    $0x84,%cl
f0100c69:	74 0b                	je     f0100c76 <debuginfo_eip+0x1a7>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c6b:	80 f9 64             	cmp    $0x64,%cl
f0100c6e:	75 e8                	jne    f0100c58 <debuginfo_eip+0x189>
f0100c70:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100c74:	74 e2                	je     f0100c58 <debuginfo_eip+0x189>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c76:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100c79:	8b 14 85 f0 20 10 f0 	mov    -0xfefdf10(,%eax,4),%edx
f0100c80:	b8 ea 73 10 f0       	mov    $0xf01073ea,%eax
f0100c85:	2d bd 5a 10 f0       	sub    $0xf0105abd,%eax
f0100c8a:	39 c2                	cmp    %eax,%edx
f0100c8c:	73 08                	jae    f0100c96 <debuginfo_eip+0x1c7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c8e:	81 c2 bd 5a 10 f0    	add    $0xf0105abd,%edx
f0100c94:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c96:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c99:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c9c:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100ca1:	39 f2                	cmp    %esi,%edx
f0100ca3:	7d 50                	jge    f0100cf5 <debuginfo_eip+0x226>
		for (lline = lfun + 1;
f0100ca5:	83 c2 01             	add    $0x1,%edx
f0100ca8:	89 d0                	mov    %edx,%eax
f0100caa:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100cad:	8d 14 95 f0 20 10 f0 	lea    -0xfefdf10(,%edx,4),%edx
f0100cb4:	eb 04                	jmp    f0100cba <debuginfo_eip+0x1eb>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100cb6:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100cba:	39 c6                	cmp    %eax,%esi
f0100cbc:	7e 32                	jle    f0100cf0 <debuginfo_eip+0x221>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100cbe:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100cc2:	83 c0 01             	add    $0x1,%eax
f0100cc5:	83 c2 0c             	add    $0xc,%edx
f0100cc8:	80 f9 a0             	cmp    $0xa0,%cl
f0100ccb:	74 e9                	je     f0100cb6 <debuginfo_eip+0x1e7>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100ccd:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cd2:	eb 21                	jmp    f0100cf5 <debuginfo_eip+0x226>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100cd4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cd9:	eb 1a                	jmp    f0100cf5 <debuginfo_eip+0x226>
f0100cdb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ce0:	eb 13                	jmp    f0100cf5 <debuginfo_eip+0x226>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100ce2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ce7:	eb 0c                	jmp    f0100cf5 <debuginfo_eip+0x226>
	// Your code here.
		stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if(lline<=rline){
		info->eip_line = stabs[rline].n_desc;}
	else{
	return -1;}
f0100ce9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cee:	eb 05                	jmp    f0100cf5 <debuginfo_eip+0x226>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cf0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100cf5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cf8:	5b                   	pop    %ebx
f0100cf9:	5e                   	pop    %esi
f0100cfa:	5f                   	pop    %edi
f0100cfb:	5d                   	pop    %ebp
f0100cfc:	c3                   	ret    

f0100cfd <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100cfd:	55                   	push   %ebp
f0100cfe:	89 e5                	mov    %esp,%ebp
f0100d00:	57                   	push   %edi
f0100d01:	56                   	push   %esi
f0100d02:	53                   	push   %ebx
f0100d03:	83 ec 1c             	sub    $0x1c,%esp
f0100d06:	89 c7                	mov    %eax,%edi
f0100d08:	89 d6                	mov    %edx,%esi
f0100d0a:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d0d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100d10:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d13:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d16:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100d19:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100d1e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100d21:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100d24:	39 d3                	cmp    %edx,%ebx
f0100d26:	72 05                	jb     f0100d2d <printnum+0x30>
f0100d28:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100d2b:	77 45                	ja     f0100d72 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d2d:	83 ec 0c             	sub    $0xc,%esp
f0100d30:	ff 75 18             	pushl  0x18(%ebp)
f0100d33:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d36:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100d39:	53                   	push   %ebx
f0100d3a:	ff 75 10             	pushl  0x10(%ebp)
f0100d3d:	83 ec 08             	sub    $0x8,%esp
f0100d40:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d43:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d46:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d49:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d4c:	e8 3f 09 00 00       	call   f0101690 <__udivdi3>
f0100d51:	83 c4 18             	add    $0x18,%esp
f0100d54:	52                   	push   %edx
f0100d55:	50                   	push   %eax
f0100d56:	89 f2                	mov    %esi,%edx
f0100d58:	89 f8                	mov    %edi,%eax
f0100d5a:	e8 9e ff ff ff       	call   f0100cfd <printnum>
f0100d5f:	83 c4 20             	add    $0x20,%esp
f0100d62:	eb 18                	jmp    f0100d7c <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d64:	83 ec 08             	sub    $0x8,%esp
f0100d67:	56                   	push   %esi
f0100d68:	ff 75 18             	pushl  0x18(%ebp)
f0100d6b:	ff d7                	call   *%edi
f0100d6d:	83 c4 10             	add    $0x10,%esp
f0100d70:	eb 03                	jmp    f0100d75 <printnum+0x78>
f0100d72:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d75:	83 eb 01             	sub    $0x1,%ebx
f0100d78:	85 db                	test   %ebx,%ebx
f0100d7a:	7f e8                	jg     f0100d64 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d7c:	83 ec 08             	sub    $0x8,%esp
f0100d7f:	56                   	push   %esi
f0100d80:	83 ec 04             	sub    $0x4,%esp
f0100d83:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d86:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d89:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d8c:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d8f:	e8 2c 0a 00 00       	call   f01017c0 <__umoddi3>
f0100d94:	83 c4 14             	add    $0x14,%esp
f0100d97:	0f be 80 bf 1e 10 f0 	movsbl -0xfefe141(%eax),%eax
f0100d9e:	50                   	push   %eax
f0100d9f:	ff d7                	call   *%edi
}
f0100da1:	83 c4 10             	add    $0x10,%esp
f0100da4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100da7:	5b                   	pop    %ebx
f0100da8:	5e                   	pop    %esi
f0100da9:	5f                   	pop    %edi
f0100daa:	5d                   	pop    %ebp
f0100dab:	c3                   	ret    

f0100dac <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100dac:	55                   	push   %ebp
f0100dad:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100daf:	83 fa 01             	cmp    $0x1,%edx
f0100db2:	7e 0e                	jle    f0100dc2 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100db4:	8b 10                	mov    (%eax),%edx
f0100db6:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100db9:	89 08                	mov    %ecx,(%eax)
f0100dbb:	8b 02                	mov    (%edx),%eax
f0100dbd:	8b 52 04             	mov    0x4(%edx),%edx
f0100dc0:	eb 22                	jmp    f0100de4 <getuint+0x38>
	else if (lflag)
f0100dc2:	85 d2                	test   %edx,%edx
f0100dc4:	74 10                	je     f0100dd6 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100dc6:	8b 10                	mov    (%eax),%edx
f0100dc8:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100dcb:	89 08                	mov    %ecx,(%eax)
f0100dcd:	8b 02                	mov    (%edx),%eax
f0100dcf:	ba 00 00 00 00       	mov    $0x0,%edx
f0100dd4:	eb 0e                	jmp    f0100de4 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100dd6:	8b 10                	mov    (%eax),%edx
f0100dd8:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100ddb:	89 08                	mov    %ecx,(%eax)
f0100ddd:	8b 02                	mov    (%edx),%eax
f0100ddf:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100de4:	5d                   	pop    %ebp
f0100de5:	c3                   	ret    

f0100de6 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100de6:	55                   	push   %ebp
f0100de7:	89 e5                	mov    %esp,%ebp
f0100de9:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100dec:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100df0:	8b 10                	mov    (%eax),%edx
f0100df2:	3b 50 04             	cmp    0x4(%eax),%edx
f0100df5:	73 0a                	jae    f0100e01 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100df7:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100dfa:	89 08                	mov    %ecx,(%eax)
f0100dfc:	8b 45 08             	mov    0x8(%ebp),%eax
f0100dff:	88 02                	mov    %al,(%edx)
}
f0100e01:	5d                   	pop    %ebp
f0100e02:	c3                   	ret    

f0100e03 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100e03:	55                   	push   %ebp
f0100e04:	89 e5                	mov    %esp,%ebp
f0100e06:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100e09:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e0c:	50                   	push   %eax
f0100e0d:	ff 75 10             	pushl  0x10(%ebp)
f0100e10:	ff 75 0c             	pushl  0xc(%ebp)
f0100e13:	ff 75 08             	pushl  0x8(%ebp)
f0100e16:	e8 05 00 00 00       	call   f0100e20 <vprintfmt>
	va_end(ap);
}
f0100e1b:	83 c4 10             	add    $0x10,%esp
f0100e1e:	c9                   	leave  
f0100e1f:	c3                   	ret    

f0100e20 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100e20:	55                   	push   %ebp
f0100e21:	89 e5                	mov    %esp,%ebp
f0100e23:	57                   	push   %edi
f0100e24:	56                   	push   %esi
f0100e25:	53                   	push   %ebx
f0100e26:	83 ec 2c             	sub    $0x2c,%esp
f0100e29:	8b 75 08             	mov    0x8(%ebp),%esi
f0100e2c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100e2f:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100e32:	eb 12                	jmp    f0100e46 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100e34:	85 c0                	test   %eax,%eax
f0100e36:	0f 84 89 03 00 00    	je     f01011c5 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0100e3c:	83 ec 08             	sub    $0x8,%esp
f0100e3f:	53                   	push   %ebx
f0100e40:	50                   	push   %eax
f0100e41:	ff d6                	call   *%esi
f0100e43:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e46:	83 c7 01             	add    $0x1,%edi
f0100e49:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100e4d:	83 f8 25             	cmp    $0x25,%eax
f0100e50:	75 e2                	jne    f0100e34 <vprintfmt+0x14>
f0100e52:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100e56:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100e5d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100e64:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100e6b:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e70:	eb 07                	jmp    f0100e79 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e72:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100e75:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e79:	8d 47 01             	lea    0x1(%edi),%eax
f0100e7c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e7f:	0f b6 07             	movzbl (%edi),%eax
f0100e82:	0f b6 c8             	movzbl %al,%ecx
f0100e85:	83 e8 23             	sub    $0x23,%eax
f0100e88:	3c 55                	cmp    $0x55,%al
f0100e8a:	0f 87 1a 03 00 00    	ja     f01011aa <vprintfmt+0x38a>
f0100e90:	0f b6 c0             	movzbl %al,%eax
f0100e93:	ff 24 85 60 1f 10 f0 	jmp    *-0xfefe0a0(,%eax,4)
f0100e9a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e9d:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100ea1:	eb d6                	jmp    f0100e79 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ea3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ea6:	b8 00 00 00 00       	mov    $0x0,%eax
f0100eab:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100eae:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100eb1:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0100eb5:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0100eb8:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0100ebb:	83 fa 09             	cmp    $0x9,%edx
f0100ebe:	77 39                	ja     f0100ef9 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100ec0:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100ec3:	eb e9                	jmp    f0100eae <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100ec5:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ec8:	8d 48 04             	lea    0x4(%eax),%ecx
f0100ecb:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100ece:	8b 00                	mov    (%eax),%eax
f0100ed0:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ed3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100ed6:	eb 27                	jmp    f0100eff <vprintfmt+0xdf>
f0100ed8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100edb:	85 c0                	test   %eax,%eax
f0100edd:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100ee2:	0f 49 c8             	cmovns %eax,%ecx
f0100ee5:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ee8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100eeb:	eb 8c                	jmp    f0100e79 <vprintfmt+0x59>
f0100eed:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100ef0:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100ef7:	eb 80                	jmp    f0100e79 <vprintfmt+0x59>
f0100ef9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100efc:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100eff:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f03:	0f 89 70 ff ff ff    	jns    f0100e79 <vprintfmt+0x59>
				width = precision, precision = -1;
f0100f09:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100f0c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f0f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100f16:	e9 5e ff ff ff       	jmp    f0100e79 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100f1b:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f1e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100f21:	e9 53 ff ff ff       	jmp    f0100e79 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100f26:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f29:	8d 50 04             	lea    0x4(%eax),%edx
f0100f2c:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f2f:	83 ec 08             	sub    $0x8,%esp
f0100f32:	53                   	push   %ebx
f0100f33:	ff 30                	pushl  (%eax)
f0100f35:	ff d6                	call   *%esi
			break;
f0100f37:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f3a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100f3d:	e9 04 ff ff ff       	jmp    f0100e46 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f42:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f45:	8d 50 04             	lea    0x4(%eax),%edx
f0100f48:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f4b:	8b 00                	mov    (%eax),%eax
f0100f4d:	99                   	cltd   
f0100f4e:	31 d0                	xor    %edx,%eax
f0100f50:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f52:	83 f8 07             	cmp    $0x7,%eax
f0100f55:	7f 0b                	jg     f0100f62 <vprintfmt+0x142>
f0100f57:	8b 14 85 c0 20 10 f0 	mov    -0xfefdf40(,%eax,4),%edx
f0100f5e:	85 d2                	test   %edx,%edx
f0100f60:	75 18                	jne    f0100f7a <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0100f62:	50                   	push   %eax
f0100f63:	68 d7 1e 10 f0       	push   $0xf0101ed7
f0100f68:	53                   	push   %ebx
f0100f69:	56                   	push   %esi
f0100f6a:	e8 94 fe ff ff       	call   f0100e03 <printfmt>
f0100f6f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f72:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100f75:	e9 cc fe ff ff       	jmp    f0100e46 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0100f7a:	52                   	push   %edx
f0100f7b:	68 e0 1e 10 f0       	push   $0xf0101ee0
f0100f80:	53                   	push   %ebx
f0100f81:	56                   	push   %esi
f0100f82:	e8 7c fe ff ff       	call   f0100e03 <printfmt>
f0100f87:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f8a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f8d:	e9 b4 fe ff ff       	jmp    f0100e46 <vprintfmt+0x26>
			break;

		// string
		case 's':
				//putch(precision, putdat);
			if ((p = va_arg(ap, char *)) == NULL)
f0100f92:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f95:	8d 50 04             	lea    0x4(%eax),%edx
f0100f98:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f9b:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100f9d:	85 ff                	test   %edi,%edi
f0100f9f:	b8 d0 1e 10 f0       	mov    $0xf0101ed0,%eax
f0100fa4:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100fa7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100fab:	0f 8e 94 00 00 00    	jle    f0101045 <vprintfmt+0x225>
f0100fb1:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100fb5:	0f 84 98 00 00 00    	je     f0101053 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fbb:	83 ec 08             	sub    $0x8,%esp
f0100fbe:	ff 75 d0             	pushl  -0x30(%ebp)
f0100fc1:	57                   	push   %edi
f0100fc2:	e8 5f 03 00 00       	call   f0101326 <strnlen>
f0100fc7:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100fca:	29 c1                	sub    %eax,%ecx
f0100fcc:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0100fcf:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100fd2:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100fd6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100fd9:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100fdc:	89 cf                	mov    %ecx,%edi
		case 's':
				//putch(precision, putdat);
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fde:	eb 0f                	jmp    f0100fef <vprintfmt+0x1cf>
					putch(padc, putdat);
f0100fe0:	83 ec 08             	sub    $0x8,%esp
f0100fe3:	53                   	push   %ebx
f0100fe4:	ff 75 e0             	pushl  -0x20(%ebp)
f0100fe7:	ff d6                	call   *%esi
		case 's':
				//putch(precision, putdat);
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fe9:	83 ef 01             	sub    $0x1,%edi
f0100fec:	83 c4 10             	add    $0x10,%esp
f0100fef:	85 ff                	test   %edi,%edi
f0100ff1:	7f ed                	jg     f0100fe0 <vprintfmt+0x1c0>
f0100ff3:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100ff6:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100ff9:	85 c9                	test   %ecx,%ecx
f0100ffb:	b8 00 00 00 00       	mov    $0x0,%eax
f0101000:	0f 49 c1             	cmovns %ecx,%eax
f0101003:	29 c1                	sub    %eax,%ecx
f0101005:	89 75 08             	mov    %esi,0x8(%ebp)
f0101008:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010100b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010100e:	89 cb                	mov    %ecx,%ebx
f0101010:	eb 4d                	jmp    f010105f <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101012:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101016:	74 1b                	je     f0101033 <vprintfmt+0x213>
f0101018:	0f be c0             	movsbl %al,%eax
f010101b:	83 e8 20             	sub    $0x20,%eax
f010101e:	83 f8 5e             	cmp    $0x5e,%eax
f0101021:	76 10                	jbe    f0101033 <vprintfmt+0x213>
					putch('?', putdat);
f0101023:	83 ec 08             	sub    $0x8,%esp
f0101026:	ff 75 0c             	pushl  0xc(%ebp)
f0101029:	6a 3f                	push   $0x3f
f010102b:	ff 55 08             	call   *0x8(%ebp)
f010102e:	83 c4 10             	add    $0x10,%esp
f0101031:	eb 0d                	jmp    f0101040 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0101033:	83 ec 08             	sub    $0x8,%esp
f0101036:	ff 75 0c             	pushl  0xc(%ebp)
f0101039:	52                   	push   %edx
f010103a:	ff 55 08             	call   *0x8(%ebp)
f010103d:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101040:	83 eb 01             	sub    $0x1,%ebx
f0101043:	eb 1a                	jmp    f010105f <vprintfmt+0x23f>
f0101045:	89 75 08             	mov    %esi,0x8(%ebp)
f0101048:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010104b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010104e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101051:	eb 0c                	jmp    f010105f <vprintfmt+0x23f>
f0101053:	89 75 08             	mov    %esi,0x8(%ebp)
f0101056:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101059:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010105c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010105f:	83 c7 01             	add    $0x1,%edi
f0101062:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101066:	0f be d0             	movsbl %al,%edx
f0101069:	85 d2                	test   %edx,%edx
f010106b:	74 23                	je     f0101090 <vprintfmt+0x270>
f010106d:	85 f6                	test   %esi,%esi
f010106f:	78 a1                	js     f0101012 <vprintfmt+0x1f2>
f0101071:	83 ee 01             	sub    $0x1,%esi
f0101074:	79 9c                	jns    f0101012 <vprintfmt+0x1f2>
f0101076:	89 df                	mov    %ebx,%edi
f0101078:	8b 75 08             	mov    0x8(%ebp),%esi
f010107b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010107e:	eb 18                	jmp    f0101098 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101080:	83 ec 08             	sub    $0x8,%esp
f0101083:	53                   	push   %ebx
f0101084:	6a 20                	push   $0x20
f0101086:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101088:	83 ef 01             	sub    $0x1,%edi
f010108b:	83 c4 10             	add    $0x10,%esp
f010108e:	eb 08                	jmp    f0101098 <vprintfmt+0x278>
f0101090:	89 df                	mov    %ebx,%edi
f0101092:	8b 75 08             	mov    0x8(%ebp),%esi
f0101095:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101098:	85 ff                	test   %edi,%edi
f010109a:	7f e4                	jg     f0101080 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010109c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010109f:	e9 a2 fd ff ff       	jmp    f0100e46 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01010a4:	83 fa 01             	cmp    $0x1,%edx
f01010a7:	7e 16                	jle    f01010bf <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f01010a9:	8b 45 14             	mov    0x14(%ebp),%eax
f01010ac:	8d 50 08             	lea    0x8(%eax),%edx
f01010af:	89 55 14             	mov    %edx,0x14(%ebp)
f01010b2:	8b 50 04             	mov    0x4(%eax),%edx
f01010b5:	8b 00                	mov    (%eax),%eax
f01010b7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010ba:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01010bd:	eb 32                	jmp    f01010f1 <vprintfmt+0x2d1>
	else if (lflag)
f01010bf:	85 d2                	test   %edx,%edx
f01010c1:	74 18                	je     f01010db <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f01010c3:	8b 45 14             	mov    0x14(%ebp),%eax
f01010c6:	8d 50 04             	lea    0x4(%eax),%edx
f01010c9:	89 55 14             	mov    %edx,0x14(%ebp)
f01010cc:	8b 00                	mov    (%eax),%eax
f01010ce:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010d1:	89 c1                	mov    %eax,%ecx
f01010d3:	c1 f9 1f             	sar    $0x1f,%ecx
f01010d6:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01010d9:	eb 16                	jmp    f01010f1 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f01010db:	8b 45 14             	mov    0x14(%ebp),%eax
f01010de:	8d 50 04             	lea    0x4(%eax),%edx
f01010e1:	89 55 14             	mov    %edx,0x14(%ebp)
f01010e4:	8b 00                	mov    (%eax),%eax
f01010e6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010e9:	89 c1                	mov    %eax,%ecx
f01010eb:	c1 f9 1f             	sar    $0x1f,%ecx
f01010ee:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01010f1:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01010f4:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01010f7:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01010fc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101100:	79 74                	jns    f0101176 <vprintfmt+0x356>
				putch('-', putdat);
f0101102:	83 ec 08             	sub    $0x8,%esp
f0101105:	53                   	push   %ebx
f0101106:	6a 2d                	push   $0x2d
f0101108:	ff d6                	call   *%esi
				num = -(long long) num;
f010110a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010110d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101110:	f7 d8                	neg    %eax
f0101112:	83 d2 00             	adc    $0x0,%edx
f0101115:	f7 da                	neg    %edx
f0101117:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f010111a:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010111f:	eb 55                	jmp    f0101176 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101121:	8d 45 14             	lea    0x14(%ebp),%eax
f0101124:	e8 83 fc ff ff       	call   f0100dac <getuint>
			base = 10;
f0101129:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f010112e:	eb 46                	jmp    f0101176 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			//putch('o', putdat);
			num = getuint(&ap, lflag);
f0101130:	8d 45 14             	lea    0x14(%ebp),%eax
f0101133:	e8 74 fc ff ff       	call   f0100dac <getuint>
			base = 8;
f0101138:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f010113d:	eb 37                	jmp    f0101176 <vprintfmt+0x356>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f010113f:	83 ec 08             	sub    $0x8,%esp
f0101142:	53                   	push   %ebx
f0101143:	6a 30                	push   $0x30
f0101145:	ff d6                	call   *%esi
			putch('x', putdat);
f0101147:	83 c4 08             	add    $0x8,%esp
f010114a:	53                   	push   %ebx
f010114b:	6a 78                	push   $0x78
f010114d:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010114f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101152:	8d 50 04             	lea    0x4(%eax),%edx
f0101155:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101158:	8b 00                	mov    (%eax),%eax
f010115a:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010115f:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101162:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101167:	eb 0d                	jmp    f0101176 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101169:	8d 45 14             	lea    0x14(%ebp),%eax
f010116c:	e8 3b fc ff ff       	call   f0100dac <getuint>
			base = 16;
f0101171:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101176:	83 ec 0c             	sub    $0xc,%esp
f0101179:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010117d:	57                   	push   %edi
f010117e:	ff 75 e0             	pushl  -0x20(%ebp)
f0101181:	51                   	push   %ecx
f0101182:	52                   	push   %edx
f0101183:	50                   	push   %eax
f0101184:	89 da                	mov    %ebx,%edx
f0101186:	89 f0                	mov    %esi,%eax
f0101188:	e8 70 fb ff ff       	call   f0100cfd <printnum>
			break;
f010118d:	83 c4 20             	add    $0x20,%esp
f0101190:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101193:	e9 ae fc ff ff       	jmp    f0100e46 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101198:	83 ec 08             	sub    $0x8,%esp
f010119b:	53                   	push   %ebx
f010119c:	51                   	push   %ecx
f010119d:	ff d6                	call   *%esi
			break;
f010119f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011a2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01011a5:	e9 9c fc ff ff       	jmp    f0100e46 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01011aa:	83 ec 08             	sub    $0x8,%esp
f01011ad:	53                   	push   %ebx
f01011ae:	6a 25                	push   $0x25
f01011b0:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01011b2:	83 c4 10             	add    $0x10,%esp
f01011b5:	eb 03                	jmp    f01011ba <vprintfmt+0x39a>
f01011b7:	83 ef 01             	sub    $0x1,%edi
f01011ba:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01011be:	75 f7                	jne    f01011b7 <vprintfmt+0x397>
f01011c0:	e9 81 fc ff ff       	jmp    f0100e46 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01011c5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011c8:	5b                   	pop    %ebx
f01011c9:	5e                   	pop    %esi
f01011ca:	5f                   	pop    %edi
f01011cb:	5d                   	pop    %ebp
f01011cc:	c3                   	ret    

f01011cd <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01011cd:	55                   	push   %ebp
f01011ce:	89 e5                	mov    %esp,%ebp
f01011d0:	83 ec 18             	sub    $0x18,%esp
f01011d3:	8b 45 08             	mov    0x8(%ebp),%eax
f01011d6:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01011d9:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01011dc:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01011e0:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01011e3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01011ea:	85 c0                	test   %eax,%eax
f01011ec:	74 26                	je     f0101214 <vsnprintf+0x47>
f01011ee:	85 d2                	test   %edx,%edx
f01011f0:	7e 22                	jle    f0101214 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01011f2:	ff 75 14             	pushl  0x14(%ebp)
f01011f5:	ff 75 10             	pushl  0x10(%ebp)
f01011f8:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01011fb:	50                   	push   %eax
f01011fc:	68 e6 0d 10 f0       	push   $0xf0100de6
f0101201:	e8 1a fc ff ff       	call   f0100e20 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101206:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101209:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010120c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010120f:	83 c4 10             	add    $0x10,%esp
f0101212:	eb 05                	jmp    f0101219 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101214:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101219:	c9                   	leave  
f010121a:	c3                   	ret    

f010121b <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010121b:	55                   	push   %ebp
f010121c:	89 e5                	mov    %esp,%ebp
f010121e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101221:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101224:	50                   	push   %eax
f0101225:	ff 75 10             	pushl  0x10(%ebp)
f0101228:	ff 75 0c             	pushl  0xc(%ebp)
f010122b:	ff 75 08             	pushl  0x8(%ebp)
f010122e:	e8 9a ff ff ff       	call   f01011cd <vsnprintf>
	va_end(ap);

	return rc;
}
f0101233:	c9                   	leave  
f0101234:	c3                   	ret    

f0101235 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101235:	55                   	push   %ebp
f0101236:	89 e5                	mov    %esp,%ebp
f0101238:	57                   	push   %edi
f0101239:	56                   	push   %esi
f010123a:	53                   	push   %ebx
f010123b:	83 ec 0c             	sub    $0xc,%esp
f010123e:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101241:	85 c0                	test   %eax,%eax
f0101243:	74 11                	je     f0101256 <readline+0x21>
		cprintf("%s", prompt);
f0101245:	83 ec 08             	sub    $0x8,%esp
f0101248:	50                   	push   %eax
f0101249:	68 e0 1e 10 f0       	push   $0xf0101ee0
f010124e:	e8 72 f7 ff ff       	call   f01009c5 <cprintf>
f0101253:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101256:	83 ec 0c             	sub    $0xc,%esp
f0101259:	6a 00                	push   $0x0
f010125b:	e8 0e f4 ff ff       	call   f010066e <iscons>
f0101260:	89 c7                	mov    %eax,%edi
f0101262:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101265:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f010126a:	e8 ee f3 ff ff       	call   f010065d <getchar>
f010126f:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101271:	85 c0                	test   %eax,%eax
f0101273:	79 18                	jns    f010128d <readline+0x58>
			cprintf("read error: %e\n", c);
f0101275:	83 ec 08             	sub    $0x8,%esp
f0101278:	50                   	push   %eax
f0101279:	68 e0 20 10 f0       	push   $0xf01020e0
f010127e:	e8 42 f7 ff ff       	call   f01009c5 <cprintf>
			return NULL;
f0101283:	83 c4 10             	add    $0x10,%esp
f0101286:	b8 00 00 00 00       	mov    $0x0,%eax
f010128b:	eb 79                	jmp    f0101306 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010128d:	83 f8 08             	cmp    $0x8,%eax
f0101290:	0f 94 c2             	sete   %dl
f0101293:	83 f8 7f             	cmp    $0x7f,%eax
f0101296:	0f 94 c0             	sete   %al
f0101299:	08 c2                	or     %al,%dl
f010129b:	74 1a                	je     f01012b7 <readline+0x82>
f010129d:	85 f6                	test   %esi,%esi
f010129f:	7e 16                	jle    f01012b7 <readline+0x82>
			if (echoing)
f01012a1:	85 ff                	test   %edi,%edi
f01012a3:	74 0d                	je     f01012b2 <readline+0x7d>
				cputchar('\b');
f01012a5:	83 ec 0c             	sub    $0xc,%esp
f01012a8:	6a 08                	push   $0x8
f01012aa:	e8 9e f3 ff ff       	call   f010064d <cputchar>
f01012af:	83 c4 10             	add    $0x10,%esp
			i--;
f01012b2:	83 ee 01             	sub    $0x1,%esi
f01012b5:	eb b3                	jmp    f010126a <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01012b7:	83 fb 1f             	cmp    $0x1f,%ebx
f01012ba:	7e 23                	jle    f01012df <readline+0xaa>
f01012bc:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01012c2:	7f 1b                	jg     f01012df <readline+0xaa>
			if (echoing)
f01012c4:	85 ff                	test   %edi,%edi
f01012c6:	74 0c                	je     f01012d4 <readline+0x9f>
				cputchar(c);
f01012c8:	83 ec 0c             	sub    $0xc,%esp
f01012cb:	53                   	push   %ebx
f01012cc:	e8 7c f3 ff ff       	call   f010064d <cputchar>
f01012d1:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01012d4:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f01012da:	8d 76 01             	lea    0x1(%esi),%esi
f01012dd:	eb 8b                	jmp    f010126a <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01012df:	83 fb 0a             	cmp    $0xa,%ebx
f01012e2:	74 05                	je     f01012e9 <readline+0xb4>
f01012e4:	83 fb 0d             	cmp    $0xd,%ebx
f01012e7:	75 81                	jne    f010126a <readline+0x35>
			if (echoing)
f01012e9:	85 ff                	test   %edi,%edi
f01012eb:	74 0d                	je     f01012fa <readline+0xc5>
				cputchar('\n');
f01012ed:	83 ec 0c             	sub    $0xc,%esp
f01012f0:	6a 0a                	push   $0xa
f01012f2:	e8 56 f3 ff ff       	call   f010064d <cputchar>
f01012f7:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01012fa:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f0101301:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101306:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101309:	5b                   	pop    %ebx
f010130a:	5e                   	pop    %esi
f010130b:	5f                   	pop    %edi
f010130c:	5d                   	pop    %ebp
f010130d:	c3                   	ret    

f010130e <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010130e:	55                   	push   %ebp
f010130f:	89 e5                	mov    %esp,%ebp
f0101311:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101314:	b8 00 00 00 00       	mov    $0x0,%eax
f0101319:	eb 03                	jmp    f010131e <strlen+0x10>
		n++;
f010131b:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010131e:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101322:	75 f7                	jne    f010131b <strlen+0xd>
		n++;
	return n;
}
f0101324:	5d                   	pop    %ebp
f0101325:	c3                   	ret    

f0101326 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101326:	55                   	push   %ebp
f0101327:	89 e5                	mov    %esp,%ebp
f0101329:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010132c:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010132f:	ba 00 00 00 00       	mov    $0x0,%edx
f0101334:	eb 03                	jmp    f0101339 <strnlen+0x13>
		n++;
f0101336:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101339:	39 c2                	cmp    %eax,%edx
f010133b:	74 08                	je     f0101345 <strnlen+0x1f>
f010133d:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101341:	75 f3                	jne    f0101336 <strnlen+0x10>
f0101343:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101345:	5d                   	pop    %ebp
f0101346:	c3                   	ret    

f0101347 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101347:	55                   	push   %ebp
f0101348:	89 e5                	mov    %esp,%ebp
f010134a:	53                   	push   %ebx
f010134b:	8b 45 08             	mov    0x8(%ebp),%eax
f010134e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101351:	89 c2                	mov    %eax,%edx
f0101353:	83 c2 01             	add    $0x1,%edx
f0101356:	83 c1 01             	add    $0x1,%ecx
f0101359:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010135d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101360:	84 db                	test   %bl,%bl
f0101362:	75 ef                	jne    f0101353 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101364:	5b                   	pop    %ebx
f0101365:	5d                   	pop    %ebp
f0101366:	c3                   	ret    

f0101367 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101367:	55                   	push   %ebp
f0101368:	89 e5                	mov    %esp,%ebp
f010136a:	53                   	push   %ebx
f010136b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010136e:	53                   	push   %ebx
f010136f:	e8 9a ff ff ff       	call   f010130e <strlen>
f0101374:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101377:	ff 75 0c             	pushl  0xc(%ebp)
f010137a:	01 d8                	add    %ebx,%eax
f010137c:	50                   	push   %eax
f010137d:	e8 c5 ff ff ff       	call   f0101347 <strcpy>
	return dst;
}
f0101382:	89 d8                	mov    %ebx,%eax
f0101384:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101387:	c9                   	leave  
f0101388:	c3                   	ret    

f0101389 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101389:	55                   	push   %ebp
f010138a:	89 e5                	mov    %esp,%ebp
f010138c:	56                   	push   %esi
f010138d:	53                   	push   %ebx
f010138e:	8b 75 08             	mov    0x8(%ebp),%esi
f0101391:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101394:	89 f3                	mov    %esi,%ebx
f0101396:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101399:	89 f2                	mov    %esi,%edx
f010139b:	eb 0f                	jmp    f01013ac <strncpy+0x23>
		*dst++ = *src;
f010139d:	83 c2 01             	add    $0x1,%edx
f01013a0:	0f b6 01             	movzbl (%ecx),%eax
f01013a3:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01013a6:	80 39 01             	cmpb   $0x1,(%ecx)
f01013a9:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013ac:	39 da                	cmp    %ebx,%edx
f01013ae:	75 ed                	jne    f010139d <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01013b0:	89 f0                	mov    %esi,%eax
f01013b2:	5b                   	pop    %ebx
f01013b3:	5e                   	pop    %esi
f01013b4:	5d                   	pop    %ebp
f01013b5:	c3                   	ret    

f01013b6 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01013b6:	55                   	push   %ebp
f01013b7:	89 e5                	mov    %esp,%ebp
f01013b9:	56                   	push   %esi
f01013ba:	53                   	push   %ebx
f01013bb:	8b 75 08             	mov    0x8(%ebp),%esi
f01013be:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01013c1:	8b 55 10             	mov    0x10(%ebp),%edx
f01013c4:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01013c6:	85 d2                	test   %edx,%edx
f01013c8:	74 21                	je     f01013eb <strlcpy+0x35>
f01013ca:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01013ce:	89 f2                	mov    %esi,%edx
f01013d0:	eb 09                	jmp    f01013db <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01013d2:	83 c2 01             	add    $0x1,%edx
f01013d5:	83 c1 01             	add    $0x1,%ecx
f01013d8:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01013db:	39 c2                	cmp    %eax,%edx
f01013dd:	74 09                	je     f01013e8 <strlcpy+0x32>
f01013df:	0f b6 19             	movzbl (%ecx),%ebx
f01013e2:	84 db                	test   %bl,%bl
f01013e4:	75 ec                	jne    f01013d2 <strlcpy+0x1c>
f01013e6:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01013e8:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01013eb:	29 f0                	sub    %esi,%eax
}
f01013ed:	5b                   	pop    %ebx
f01013ee:	5e                   	pop    %esi
f01013ef:	5d                   	pop    %ebp
f01013f0:	c3                   	ret    

f01013f1 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01013f1:	55                   	push   %ebp
f01013f2:	89 e5                	mov    %esp,%ebp
f01013f4:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013f7:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01013fa:	eb 06                	jmp    f0101402 <strcmp+0x11>
		p++, q++;
f01013fc:	83 c1 01             	add    $0x1,%ecx
f01013ff:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101402:	0f b6 01             	movzbl (%ecx),%eax
f0101405:	84 c0                	test   %al,%al
f0101407:	74 04                	je     f010140d <strcmp+0x1c>
f0101409:	3a 02                	cmp    (%edx),%al
f010140b:	74 ef                	je     f01013fc <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010140d:	0f b6 c0             	movzbl %al,%eax
f0101410:	0f b6 12             	movzbl (%edx),%edx
f0101413:	29 d0                	sub    %edx,%eax
}
f0101415:	5d                   	pop    %ebp
f0101416:	c3                   	ret    

f0101417 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101417:	55                   	push   %ebp
f0101418:	89 e5                	mov    %esp,%ebp
f010141a:	53                   	push   %ebx
f010141b:	8b 45 08             	mov    0x8(%ebp),%eax
f010141e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101421:	89 c3                	mov    %eax,%ebx
f0101423:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101426:	eb 06                	jmp    f010142e <strncmp+0x17>
		n--, p++, q++;
f0101428:	83 c0 01             	add    $0x1,%eax
f010142b:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010142e:	39 d8                	cmp    %ebx,%eax
f0101430:	74 15                	je     f0101447 <strncmp+0x30>
f0101432:	0f b6 08             	movzbl (%eax),%ecx
f0101435:	84 c9                	test   %cl,%cl
f0101437:	74 04                	je     f010143d <strncmp+0x26>
f0101439:	3a 0a                	cmp    (%edx),%cl
f010143b:	74 eb                	je     f0101428 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010143d:	0f b6 00             	movzbl (%eax),%eax
f0101440:	0f b6 12             	movzbl (%edx),%edx
f0101443:	29 d0                	sub    %edx,%eax
f0101445:	eb 05                	jmp    f010144c <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101447:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010144c:	5b                   	pop    %ebx
f010144d:	5d                   	pop    %ebp
f010144e:	c3                   	ret    

f010144f <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010144f:	55                   	push   %ebp
f0101450:	89 e5                	mov    %esp,%ebp
f0101452:	8b 45 08             	mov    0x8(%ebp),%eax
f0101455:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101459:	eb 07                	jmp    f0101462 <strchr+0x13>
		if (*s == c)
f010145b:	38 ca                	cmp    %cl,%dl
f010145d:	74 0f                	je     f010146e <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010145f:	83 c0 01             	add    $0x1,%eax
f0101462:	0f b6 10             	movzbl (%eax),%edx
f0101465:	84 d2                	test   %dl,%dl
f0101467:	75 f2                	jne    f010145b <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101469:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010146e:	5d                   	pop    %ebp
f010146f:	c3                   	ret    

f0101470 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101470:	55                   	push   %ebp
f0101471:	89 e5                	mov    %esp,%ebp
f0101473:	8b 45 08             	mov    0x8(%ebp),%eax
f0101476:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010147a:	eb 03                	jmp    f010147f <strfind+0xf>
f010147c:	83 c0 01             	add    $0x1,%eax
f010147f:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101482:	38 ca                	cmp    %cl,%dl
f0101484:	74 04                	je     f010148a <strfind+0x1a>
f0101486:	84 d2                	test   %dl,%dl
f0101488:	75 f2                	jne    f010147c <strfind+0xc>
			break;
	return (char *) s;
}
f010148a:	5d                   	pop    %ebp
f010148b:	c3                   	ret    

f010148c <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010148c:	55                   	push   %ebp
f010148d:	89 e5                	mov    %esp,%ebp
f010148f:	57                   	push   %edi
f0101490:	56                   	push   %esi
f0101491:	53                   	push   %ebx
f0101492:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101495:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101498:	85 c9                	test   %ecx,%ecx
f010149a:	74 36                	je     f01014d2 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010149c:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01014a2:	75 28                	jne    f01014cc <memset+0x40>
f01014a4:	f6 c1 03             	test   $0x3,%cl
f01014a7:	75 23                	jne    f01014cc <memset+0x40>
		c &= 0xFF;
f01014a9:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01014ad:	89 d3                	mov    %edx,%ebx
f01014af:	c1 e3 08             	shl    $0x8,%ebx
f01014b2:	89 d6                	mov    %edx,%esi
f01014b4:	c1 e6 18             	shl    $0x18,%esi
f01014b7:	89 d0                	mov    %edx,%eax
f01014b9:	c1 e0 10             	shl    $0x10,%eax
f01014bc:	09 f0                	or     %esi,%eax
f01014be:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01014c0:	89 d8                	mov    %ebx,%eax
f01014c2:	09 d0                	or     %edx,%eax
f01014c4:	c1 e9 02             	shr    $0x2,%ecx
f01014c7:	fc                   	cld    
f01014c8:	f3 ab                	rep stos %eax,%es:(%edi)
f01014ca:	eb 06                	jmp    f01014d2 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01014cc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014cf:	fc                   	cld    
f01014d0:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01014d2:	89 f8                	mov    %edi,%eax
f01014d4:	5b                   	pop    %ebx
f01014d5:	5e                   	pop    %esi
f01014d6:	5f                   	pop    %edi
f01014d7:	5d                   	pop    %ebp
f01014d8:	c3                   	ret    

f01014d9 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01014d9:	55                   	push   %ebp
f01014da:	89 e5                	mov    %esp,%ebp
f01014dc:	57                   	push   %edi
f01014dd:	56                   	push   %esi
f01014de:	8b 45 08             	mov    0x8(%ebp),%eax
f01014e1:	8b 75 0c             	mov    0xc(%ebp),%esi
f01014e4:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01014e7:	39 c6                	cmp    %eax,%esi
f01014e9:	73 35                	jae    f0101520 <memmove+0x47>
f01014eb:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01014ee:	39 d0                	cmp    %edx,%eax
f01014f0:	73 2e                	jae    f0101520 <memmove+0x47>
		s += n;
		d += n;
f01014f2:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014f5:	89 d6                	mov    %edx,%esi
f01014f7:	09 fe                	or     %edi,%esi
f01014f9:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01014ff:	75 13                	jne    f0101514 <memmove+0x3b>
f0101501:	f6 c1 03             	test   $0x3,%cl
f0101504:	75 0e                	jne    f0101514 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0101506:	83 ef 04             	sub    $0x4,%edi
f0101509:	8d 72 fc             	lea    -0x4(%edx),%esi
f010150c:	c1 e9 02             	shr    $0x2,%ecx
f010150f:	fd                   	std    
f0101510:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101512:	eb 09                	jmp    f010151d <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101514:	83 ef 01             	sub    $0x1,%edi
f0101517:	8d 72 ff             	lea    -0x1(%edx),%esi
f010151a:	fd                   	std    
f010151b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010151d:	fc                   	cld    
f010151e:	eb 1d                	jmp    f010153d <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101520:	89 f2                	mov    %esi,%edx
f0101522:	09 c2                	or     %eax,%edx
f0101524:	f6 c2 03             	test   $0x3,%dl
f0101527:	75 0f                	jne    f0101538 <memmove+0x5f>
f0101529:	f6 c1 03             	test   $0x3,%cl
f010152c:	75 0a                	jne    f0101538 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f010152e:	c1 e9 02             	shr    $0x2,%ecx
f0101531:	89 c7                	mov    %eax,%edi
f0101533:	fc                   	cld    
f0101534:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101536:	eb 05                	jmp    f010153d <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101538:	89 c7                	mov    %eax,%edi
f010153a:	fc                   	cld    
f010153b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010153d:	5e                   	pop    %esi
f010153e:	5f                   	pop    %edi
f010153f:	5d                   	pop    %ebp
f0101540:	c3                   	ret    

f0101541 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101541:	55                   	push   %ebp
f0101542:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101544:	ff 75 10             	pushl  0x10(%ebp)
f0101547:	ff 75 0c             	pushl  0xc(%ebp)
f010154a:	ff 75 08             	pushl  0x8(%ebp)
f010154d:	e8 87 ff ff ff       	call   f01014d9 <memmove>
}
f0101552:	c9                   	leave  
f0101553:	c3                   	ret    

f0101554 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101554:	55                   	push   %ebp
f0101555:	89 e5                	mov    %esp,%ebp
f0101557:	56                   	push   %esi
f0101558:	53                   	push   %ebx
f0101559:	8b 45 08             	mov    0x8(%ebp),%eax
f010155c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010155f:	89 c6                	mov    %eax,%esi
f0101561:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101564:	eb 1a                	jmp    f0101580 <memcmp+0x2c>
		if (*s1 != *s2)
f0101566:	0f b6 08             	movzbl (%eax),%ecx
f0101569:	0f b6 1a             	movzbl (%edx),%ebx
f010156c:	38 d9                	cmp    %bl,%cl
f010156e:	74 0a                	je     f010157a <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101570:	0f b6 c1             	movzbl %cl,%eax
f0101573:	0f b6 db             	movzbl %bl,%ebx
f0101576:	29 d8                	sub    %ebx,%eax
f0101578:	eb 0f                	jmp    f0101589 <memcmp+0x35>
		s1++, s2++;
f010157a:	83 c0 01             	add    $0x1,%eax
f010157d:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101580:	39 f0                	cmp    %esi,%eax
f0101582:	75 e2                	jne    f0101566 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101584:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101589:	5b                   	pop    %ebx
f010158a:	5e                   	pop    %esi
f010158b:	5d                   	pop    %ebp
f010158c:	c3                   	ret    

f010158d <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010158d:	55                   	push   %ebp
f010158e:	89 e5                	mov    %esp,%ebp
f0101590:	53                   	push   %ebx
f0101591:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101594:	89 c1                	mov    %eax,%ecx
f0101596:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0101599:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010159d:	eb 0a                	jmp    f01015a9 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010159f:	0f b6 10             	movzbl (%eax),%edx
f01015a2:	39 da                	cmp    %ebx,%edx
f01015a4:	74 07                	je     f01015ad <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01015a6:	83 c0 01             	add    $0x1,%eax
f01015a9:	39 c8                	cmp    %ecx,%eax
f01015ab:	72 f2                	jb     f010159f <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01015ad:	5b                   	pop    %ebx
f01015ae:	5d                   	pop    %ebp
f01015af:	c3                   	ret    

f01015b0 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01015b0:	55                   	push   %ebp
f01015b1:	89 e5                	mov    %esp,%ebp
f01015b3:	57                   	push   %edi
f01015b4:	56                   	push   %esi
f01015b5:	53                   	push   %ebx
f01015b6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01015b9:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015bc:	eb 03                	jmp    f01015c1 <strtol+0x11>
		s++;
f01015be:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015c1:	0f b6 01             	movzbl (%ecx),%eax
f01015c4:	3c 20                	cmp    $0x20,%al
f01015c6:	74 f6                	je     f01015be <strtol+0xe>
f01015c8:	3c 09                	cmp    $0x9,%al
f01015ca:	74 f2                	je     f01015be <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01015cc:	3c 2b                	cmp    $0x2b,%al
f01015ce:	75 0a                	jne    f01015da <strtol+0x2a>
		s++;
f01015d0:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01015d3:	bf 00 00 00 00       	mov    $0x0,%edi
f01015d8:	eb 11                	jmp    f01015eb <strtol+0x3b>
f01015da:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01015df:	3c 2d                	cmp    $0x2d,%al
f01015e1:	75 08                	jne    f01015eb <strtol+0x3b>
		s++, neg = 1;
f01015e3:	83 c1 01             	add    $0x1,%ecx
f01015e6:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01015eb:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01015f1:	75 15                	jne    f0101608 <strtol+0x58>
f01015f3:	80 39 30             	cmpb   $0x30,(%ecx)
f01015f6:	75 10                	jne    f0101608 <strtol+0x58>
f01015f8:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01015fc:	75 7c                	jne    f010167a <strtol+0xca>
		s += 2, base = 16;
f01015fe:	83 c1 02             	add    $0x2,%ecx
f0101601:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101606:	eb 16                	jmp    f010161e <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0101608:	85 db                	test   %ebx,%ebx
f010160a:	75 12                	jne    f010161e <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010160c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101611:	80 39 30             	cmpb   $0x30,(%ecx)
f0101614:	75 08                	jne    f010161e <strtol+0x6e>
		s++, base = 8;
f0101616:	83 c1 01             	add    $0x1,%ecx
f0101619:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f010161e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101623:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101626:	0f b6 11             	movzbl (%ecx),%edx
f0101629:	8d 72 d0             	lea    -0x30(%edx),%esi
f010162c:	89 f3                	mov    %esi,%ebx
f010162e:	80 fb 09             	cmp    $0x9,%bl
f0101631:	77 08                	ja     f010163b <strtol+0x8b>
			dig = *s - '0';
f0101633:	0f be d2             	movsbl %dl,%edx
f0101636:	83 ea 30             	sub    $0x30,%edx
f0101639:	eb 22                	jmp    f010165d <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f010163b:	8d 72 9f             	lea    -0x61(%edx),%esi
f010163e:	89 f3                	mov    %esi,%ebx
f0101640:	80 fb 19             	cmp    $0x19,%bl
f0101643:	77 08                	ja     f010164d <strtol+0x9d>
			dig = *s - 'a' + 10;
f0101645:	0f be d2             	movsbl %dl,%edx
f0101648:	83 ea 57             	sub    $0x57,%edx
f010164b:	eb 10                	jmp    f010165d <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f010164d:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101650:	89 f3                	mov    %esi,%ebx
f0101652:	80 fb 19             	cmp    $0x19,%bl
f0101655:	77 16                	ja     f010166d <strtol+0xbd>
			dig = *s - 'A' + 10;
f0101657:	0f be d2             	movsbl %dl,%edx
f010165a:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010165d:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101660:	7d 0b                	jge    f010166d <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0101662:	83 c1 01             	add    $0x1,%ecx
f0101665:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101669:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010166b:	eb b9                	jmp    f0101626 <strtol+0x76>

	if (endptr)
f010166d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101671:	74 0d                	je     f0101680 <strtol+0xd0>
		*endptr = (char *) s;
f0101673:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101676:	89 0e                	mov    %ecx,(%esi)
f0101678:	eb 06                	jmp    f0101680 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010167a:	85 db                	test   %ebx,%ebx
f010167c:	74 98                	je     f0101616 <strtol+0x66>
f010167e:	eb 9e                	jmp    f010161e <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0101680:	89 c2                	mov    %eax,%edx
f0101682:	f7 da                	neg    %edx
f0101684:	85 ff                	test   %edi,%edi
f0101686:	0f 45 c2             	cmovne %edx,%eax
}
f0101689:	5b                   	pop    %ebx
f010168a:	5e                   	pop    %esi
f010168b:	5f                   	pop    %edi
f010168c:	5d                   	pop    %ebp
f010168d:	c3                   	ret    
f010168e:	66 90                	xchg   %ax,%ax

f0101690 <__udivdi3>:
f0101690:	55                   	push   %ebp
f0101691:	57                   	push   %edi
f0101692:	56                   	push   %esi
f0101693:	53                   	push   %ebx
f0101694:	83 ec 1c             	sub    $0x1c,%esp
f0101697:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010169b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010169f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01016a3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01016a7:	85 f6                	test   %esi,%esi
f01016a9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01016ad:	89 ca                	mov    %ecx,%edx
f01016af:	89 f8                	mov    %edi,%eax
f01016b1:	75 3d                	jne    f01016f0 <__udivdi3+0x60>
f01016b3:	39 cf                	cmp    %ecx,%edi
f01016b5:	0f 87 c5 00 00 00    	ja     f0101780 <__udivdi3+0xf0>
f01016bb:	85 ff                	test   %edi,%edi
f01016bd:	89 fd                	mov    %edi,%ebp
f01016bf:	75 0b                	jne    f01016cc <__udivdi3+0x3c>
f01016c1:	b8 01 00 00 00       	mov    $0x1,%eax
f01016c6:	31 d2                	xor    %edx,%edx
f01016c8:	f7 f7                	div    %edi
f01016ca:	89 c5                	mov    %eax,%ebp
f01016cc:	89 c8                	mov    %ecx,%eax
f01016ce:	31 d2                	xor    %edx,%edx
f01016d0:	f7 f5                	div    %ebp
f01016d2:	89 c1                	mov    %eax,%ecx
f01016d4:	89 d8                	mov    %ebx,%eax
f01016d6:	89 cf                	mov    %ecx,%edi
f01016d8:	f7 f5                	div    %ebp
f01016da:	89 c3                	mov    %eax,%ebx
f01016dc:	89 d8                	mov    %ebx,%eax
f01016de:	89 fa                	mov    %edi,%edx
f01016e0:	83 c4 1c             	add    $0x1c,%esp
f01016e3:	5b                   	pop    %ebx
f01016e4:	5e                   	pop    %esi
f01016e5:	5f                   	pop    %edi
f01016e6:	5d                   	pop    %ebp
f01016e7:	c3                   	ret    
f01016e8:	90                   	nop
f01016e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01016f0:	39 ce                	cmp    %ecx,%esi
f01016f2:	77 74                	ja     f0101768 <__udivdi3+0xd8>
f01016f4:	0f bd fe             	bsr    %esi,%edi
f01016f7:	83 f7 1f             	xor    $0x1f,%edi
f01016fa:	0f 84 98 00 00 00    	je     f0101798 <__udivdi3+0x108>
f0101700:	bb 20 00 00 00       	mov    $0x20,%ebx
f0101705:	89 f9                	mov    %edi,%ecx
f0101707:	89 c5                	mov    %eax,%ebp
f0101709:	29 fb                	sub    %edi,%ebx
f010170b:	d3 e6                	shl    %cl,%esi
f010170d:	89 d9                	mov    %ebx,%ecx
f010170f:	d3 ed                	shr    %cl,%ebp
f0101711:	89 f9                	mov    %edi,%ecx
f0101713:	d3 e0                	shl    %cl,%eax
f0101715:	09 ee                	or     %ebp,%esi
f0101717:	89 d9                	mov    %ebx,%ecx
f0101719:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010171d:	89 d5                	mov    %edx,%ebp
f010171f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101723:	d3 ed                	shr    %cl,%ebp
f0101725:	89 f9                	mov    %edi,%ecx
f0101727:	d3 e2                	shl    %cl,%edx
f0101729:	89 d9                	mov    %ebx,%ecx
f010172b:	d3 e8                	shr    %cl,%eax
f010172d:	09 c2                	or     %eax,%edx
f010172f:	89 d0                	mov    %edx,%eax
f0101731:	89 ea                	mov    %ebp,%edx
f0101733:	f7 f6                	div    %esi
f0101735:	89 d5                	mov    %edx,%ebp
f0101737:	89 c3                	mov    %eax,%ebx
f0101739:	f7 64 24 0c          	mull   0xc(%esp)
f010173d:	39 d5                	cmp    %edx,%ebp
f010173f:	72 10                	jb     f0101751 <__udivdi3+0xc1>
f0101741:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101745:	89 f9                	mov    %edi,%ecx
f0101747:	d3 e6                	shl    %cl,%esi
f0101749:	39 c6                	cmp    %eax,%esi
f010174b:	73 07                	jae    f0101754 <__udivdi3+0xc4>
f010174d:	39 d5                	cmp    %edx,%ebp
f010174f:	75 03                	jne    f0101754 <__udivdi3+0xc4>
f0101751:	83 eb 01             	sub    $0x1,%ebx
f0101754:	31 ff                	xor    %edi,%edi
f0101756:	89 d8                	mov    %ebx,%eax
f0101758:	89 fa                	mov    %edi,%edx
f010175a:	83 c4 1c             	add    $0x1c,%esp
f010175d:	5b                   	pop    %ebx
f010175e:	5e                   	pop    %esi
f010175f:	5f                   	pop    %edi
f0101760:	5d                   	pop    %ebp
f0101761:	c3                   	ret    
f0101762:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101768:	31 ff                	xor    %edi,%edi
f010176a:	31 db                	xor    %ebx,%ebx
f010176c:	89 d8                	mov    %ebx,%eax
f010176e:	89 fa                	mov    %edi,%edx
f0101770:	83 c4 1c             	add    $0x1c,%esp
f0101773:	5b                   	pop    %ebx
f0101774:	5e                   	pop    %esi
f0101775:	5f                   	pop    %edi
f0101776:	5d                   	pop    %ebp
f0101777:	c3                   	ret    
f0101778:	90                   	nop
f0101779:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101780:	89 d8                	mov    %ebx,%eax
f0101782:	f7 f7                	div    %edi
f0101784:	31 ff                	xor    %edi,%edi
f0101786:	89 c3                	mov    %eax,%ebx
f0101788:	89 d8                	mov    %ebx,%eax
f010178a:	89 fa                	mov    %edi,%edx
f010178c:	83 c4 1c             	add    $0x1c,%esp
f010178f:	5b                   	pop    %ebx
f0101790:	5e                   	pop    %esi
f0101791:	5f                   	pop    %edi
f0101792:	5d                   	pop    %ebp
f0101793:	c3                   	ret    
f0101794:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101798:	39 ce                	cmp    %ecx,%esi
f010179a:	72 0c                	jb     f01017a8 <__udivdi3+0x118>
f010179c:	31 db                	xor    %ebx,%ebx
f010179e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01017a2:	0f 87 34 ff ff ff    	ja     f01016dc <__udivdi3+0x4c>
f01017a8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01017ad:	e9 2a ff ff ff       	jmp    f01016dc <__udivdi3+0x4c>
f01017b2:	66 90                	xchg   %ax,%ax
f01017b4:	66 90                	xchg   %ax,%ax
f01017b6:	66 90                	xchg   %ax,%ax
f01017b8:	66 90                	xchg   %ax,%ax
f01017ba:	66 90                	xchg   %ax,%ax
f01017bc:	66 90                	xchg   %ax,%ax
f01017be:	66 90                	xchg   %ax,%ax

f01017c0 <__umoddi3>:
f01017c0:	55                   	push   %ebp
f01017c1:	57                   	push   %edi
f01017c2:	56                   	push   %esi
f01017c3:	53                   	push   %ebx
f01017c4:	83 ec 1c             	sub    $0x1c,%esp
f01017c7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01017cb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01017cf:	8b 74 24 34          	mov    0x34(%esp),%esi
f01017d3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01017d7:	85 d2                	test   %edx,%edx
f01017d9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01017dd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01017e1:	89 f3                	mov    %esi,%ebx
f01017e3:	89 3c 24             	mov    %edi,(%esp)
f01017e6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01017ea:	75 1c                	jne    f0101808 <__umoddi3+0x48>
f01017ec:	39 f7                	cmp    %esi,%edi
f01017ee:	76 50                	jbe    f0101840 <__umoddi3+0x80>
f01017f0:	89 c8                	mov    %ecx,%eax
f01017f2:	89 f2                	mov    %esi,%edx
f01017f4:	f7 f7                	div    %edi
f01017f6:	89 d0                	mov    %edx,%eax
f01017f8:	31 d2                	xor    %edx,%edx
f01017fa:	83 c4 1c             	add    $0x1c,%esp
f01017fd:	5b                   	pop    %ebx
f01017fe:	5e                   	pop    %esi
f01017ff:	5f                   	pop    %edi
f0101800:	5d                   	pop    %ebp
f0101801:	c3                   	ret    
f0101802:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101808:	39 f2                	cmp    %esi,%edx
f010180a:	89 d0                	mov    %edx,%eax
f010180c:	77 52                	ja     f0101860 <__umoddi3+0xa0>
f010180e:	0f bd ea             	bsr    %edx,%ebp
f0101811:	83 f5 1f             	xor    $0x1f,%ebp
f0101814:	75 5a                	jne    f0101870 <__umoddi3+0xb0>
f0101816:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010181a:	0f 82 e0 00 00 00    	jb     f0101900 <__umoddi3+0x140>
f0101820:	39 0c 24             	cmp    %ecx,(%esp)
f0101823:	0f 86 d7 00 00 00    	jbe    f0101900 <__umoddi3+0x140>
f0101829:	8b 44 24 08          	mov    0x8(%esp),%eax
f010182d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101831:	83 c4 1c             	add    $0x1c,%esp
f0101834:	5b                   	pop    %ebx
f0101835:	5e                   	pop    %esi
f0101836:	5f                   	pop    %edi
f0101837:	5d                   	pop    %ebp
f0101838:	c3                   	ret    
f0101839:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101840:	85 ff                	test   %edi,%edi
f0101842:	89 fd                	mov    %edi,%ebp
f0101844:	75 0b                	jne    f0101851 <__umoddi3+0x91>
f0101846:	b8 01 00 00 00       	mov    $0x1,%eax
f010184b:	31 d2                	xor    %edx,%edx
f010184d:	f7 f7                	div    %edi
f010184f:	89 c5                	mov    %eax,%ebp
f0101851:	89 f0                	mov    %esi,%eax
f0101853:	31 d2                	xor    %edx,%edx
f0101855:	f7 f5                	div    %ebp
f0101857:	89 c8                	mov    %ecx,%eax
f0101859:	f7 f5                	div    %ebp
f010185b:	89 d0                	mov    %edx,%eax
f010185d:	eb 99                	jmp    f01017f8 <__umoddi3+0x38>
f010185f:	90                   	nop
f0101860:	89 c8                	mov    %ecx,%eax
f0101862:	89 f2                	mov    %esi,%edx
f0101864:	83 c4 1c             	add    $0x1c,%esp
f0101867:	5b                   	pop    %ebx
f0101868:	5e                   	pop    %esi
f0101869:	5f                   	pop    %edi
f010186a:	5d                   	pop    %ebp
f010186b:	c3                   	ret    
f010186c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101870:	8b 34 24             	mov    (%esp),%esi
f0101873:	bf 20 00 00 00       	mov    $0x20,%edi
f0101878:	89 e9                	mov    %ebp,%ecx
f010187a:	29 ef                	sub    %ebp,%edi
f010187c:	d3 e0                	shl    %cl,%eax
f010187e:	89 f9                	mov    %edi,%ecx
f0101880:	89 f2                	mov    %esi,%edx
f0101882:	d3 ea                	shr    %cl,%edx
f0101884:	89 e9                	mov    %ebp,%ecx
f0101886:	09 c2                	or     %eax,%edx
f0101888:	89 d8                	mov    %ebx,%eax
f010188a:	89 14 24             	mov    %edx,(%esp)
f010188d:	89 f2                	mov    %esi,%edx
f010188f:	d3 e2                	shl    %cl,%edx
f0101891:	89 f9                	mov    %edi,%ecx
f0101893:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101897:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010189b:	d3 e8                	shr    %cl,%eax
f010189d:	89 e9                	mov    %ebp,%ecx
f010189f:	89 c6                	mov    %eax,%esi
f01018a1:	d3 e3                	shl    %cl,%ebx
f01018a3:	89 f9                	mov    %edi,%ecx
f01018a5:	89 d0                	mov    %edx,%eax
f01018a7:	d3 e8                	shr    %cl,%eax
f01018a9:	89 e9                	mov    %ebp,%ecx
f01018ab:	09 d8                	or     %ebx,%eax
f01018ad:	89 d3                	mov    %edx,%ebx
f01018af:	89 f2                	mov    %esi,%edx
f01018b1:	f7 34 24             	divl   (%esp)
f01018b4:	89 d6                	mov    %edx,%esi
f01018b6:	d3 e3                	shl    %cl,%ebx
f01018b8:	f7 64 24 04          	mull   0x4(%esp)
f01018bc:	39 d6                	cmp    %edx,%esi
f01018be:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01018c2:	89 d1                	mov    %edx,%ecx
f01018c4:	89 c3                	mov    %eax,%ebx
f01018c6:	72 08                	jb     f01018d0 <__umoddi3+0x110>
f01018c8:	75 11                	jne    f01018db <__umoddi3+0x11b>
f01018ca:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01018ce:	73 0b                	jae    f01018db <__umoddi3+0x11b>
f01018d0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01018d4:	1b 14 24             	sbb    (%esp),%edx
f01018d7:	89 d1                	mov    %edx,%ecx
f01018d9:	89 c3                	mov    %eax,%ebx
f01018db:	8b 54 24 08          	mov    0x8(%esp),%edx
f01018df:	29 da                	sub    %ebx,%edx
f01018e1:	19 ce                	sbb    %ecx,%esi
f01018e3:	89 f9                	mov    %edi,%ecx
f01018e5:	89 f0                	mov    %esi,%eax
f01018e7:	d3 e0                	shl    %cl,%eax
f01018e9:	89 e9                	mov    %ebp,%ecx
f01018eb:	d3 ea                	shr    %cl,%edx
f01018ed:	89 e9                	mov    %ebp,%ecx
f01018ef:	d3 ee                	shr    %cl,%esi
f01018f1:	09 d0                	or     %edx,%eax
f01018f3:	89 f2                	mov    %esi,%edx
f01018f5:	83 c4 1c             	add    $0x1c,%esp
f01018f8:	5b                   	pop    %ebx
f01018f9:	5e                   	pop    %esi
f01018fa:	5f                   	pop    %edi
f01018fb:	5d                   	pop    %ebp
f01018fc:	c3                   	ret    
f01018fd:	8d 76 00             	lea    0x0(%esi),%esi
f0101900:	29 f9                	sub    %edi,%ecx
f0101902:	19 d6                	sbb    %edx,%esi
f0101904:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101908:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010190c:	e9 18 ff ff ff       	jmp    f0101829 <__umoddi3+0x69>
