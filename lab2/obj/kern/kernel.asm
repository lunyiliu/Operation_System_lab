
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
f0100015:	b8 00 60 11 00       	mov    $0x116000,%eax
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
f0100034:	bc 00 60 11 f0       	mov    $0xf0116000,%esp

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
f010004b:	68 40 3c 10 f0       	push   $0xf0103c40
f0100050:	e8 9f 2a 00 00       	call   f0102af4 <cprintf>
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
f0100076:	e8 c4 08 00 00       	call   f010093f <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 5c 3c 10 f0       	push   $0xf0103c5c
f0100087:	e8 68 2a 00 00       	call   f0102af4 <cprintf>
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
f010009a:	b8 90 89 11 f0       	mov    $0xf0118990,%eax
f010009f:	2d 00 83 11 f0       	sub    $0xf0118300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 83 11 f0       	push   $0xf0118300
f01000ac:	e8 ee 36 00 00       	call   f010379f <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 8f 04 00 00       	call   f0100545 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 77 3c 10 f0       	push   $0xf0103c77
f01000c3:	e8 2c 2a 00 00       	call   f0102af4 <cprintf>

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
f01000dc:	e8 24 09 00 00       	call   f0100a05 <monitor>
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
f01000ee:	83 3d 80 89 11 f0 00 	cmpl   $0x0,0xf0118980
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 80 89 11 f0    	mov    %esi,0xf0118980

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
f010010b:	68 92 3c 10 f0       	push   $0xf0103c92
f0100110:	e8 df 29 00 00       	call   f0102af4 <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 af 29 00 00       	call   f0102ace <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 ce 4d 10 f0 	movl   $0xf0104dce,(%esp)
f0100126:	e8 c9 29 00 00       	call   f0102af4 <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 cd 08 00 00       	call   f0100a05 <monitor>
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
f010014d:	68 aa 3c 10 f0       	push   $0xf0103caa
f0100152:	e8 9d 29 00 00       	call   f0102af4 <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 6b 29 00 00       	call   f0102ace <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 ce 4d 10 f0 	movl   $0xf0104dce,(%esp)
f010016a:	e8 85 29 00 00       	call   f0102af4 <cprintf>
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
f01001a5:	8b 0d 24 85 11 f0    	mov    0xf0118524,%ecx
f01001ab:	8d 51 01             	lea    0x1(%ecx),%edx
f01001ae:	89 15 24 85 11 f0    	mov    %edx,0xf0118524
f01001b4:	88 81 20 83 11 f0    	mov    %al,-0xfee7ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001ba:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c0:	75 0a                	jne    f01001cc <cons_intr+0x36>
			cons.wpos = 0;
f01001c2:	c7 05 24 85 11 f0 00 	movl   $0x0,0xf0118524
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
f01001f3:	83 0d 00 83 11 f0 40 	orl    $0x40,0xf0118300
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
f010020b:	8b 0d 00 83 11 f0    	mov    0xf0118300,%ecx
f0100211:	89 cb                	mov    %ecx,%ebx
f0100213:	83 e3 40             	and    $0x40,%ebx
f0100216:	83 e0 7f             	and    $0x7f,%eax
f0100219:	85 db                	test   %ebx,%ebx
f010021b:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010021e:	0f b6 d2             	movzbl %dl,%edx
f0100221:	0f b6 82 20 3e 10 f0 	movzbl -0xfefc1e0(%edx),%eax
f0100228:	83 c8 40             	or     $0x40,%eax
f010022b:	0f b6 c0             	movzbl %al,%eax
f010022e:	f7 d0                	not    %eax
f0100230:	21 c8                	and    %ecx,%eax
f0100232:	a3 00 83 11 f0       	mov    %eax,0xf0118300
		return 0;
f0100237:	b8 00 00 00 00       	mov    $0x0,%eax
f010023c:	e9 9e 00 00 00       	jmp    f01002df <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f0100241:	8b 0d 00 83 11 f0    	mov    0xf0118300,%ecx
f0100247:	f6 c1 40             	test   $0x40,%cl
f010024a:	74 0e                	je     f010025a <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010024c:	83 c8 80             	or     $0xffffff80,%eax
f010024f:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100251:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100254:	89 0d 00 83 11 f0    	mov    %ecx,0xf0118300
	}

	shift |= shiftcode[data];
f010025a:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010025d:	0f b6 82 20 3e 10 f0 	movzbl -0xfefc1e0(%edx),%eax
f0100264:	0b 05 00 83 11 f0    	or     0xf0118300,%eax
f010026a:	0f b6 8a 20 3d 10 f0 	movzbl -0xfefc2e0(%edx),%ecx
f0100271:	31 c8                	xor    %ecx,%eax
f0100273:	a3 00 83 11 f0       	mov    %eax,0xf0118300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100278:	89 c1                	mov    %eax,%ecx
f010027a:	83 e1 03             	and    $0x3,%ecx
f010027d:	8b 0c 8d 00 3d 10 f0 	mov    -0xfefc300(,%ecx,4),%ecx
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
f01002bb:	68 c4 3c 10 f0       	push   $0xf0103cc4
f01002c0:	e8 2f 28 00 00       	call   f0102af4 <cprintf>
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
f01003a1:	0f b7 05 28 85 11 f0 	movzwl 0xf0118528,%eax
f01003a8:	66 85 c0             	test   %ax,%ax
f01003ab:	0f 84 e6 00 00 00    	je     f0100497 <cons_putc+0x1b3>
			crt_pos--;
f01003b1:	83 e8 01             	sub    $0x1,%eax
f01003b4:	66 a3 28 85 11 f0    	mov    %ax,0xf0118528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003ba:	0f b7 c0             	movzwl %ax,%eax
f01003bd:	66 81 e7 00 ff       	and    $0xff00,%di
f01003c2:	83 cf 20             	or     $0x20,%edi
f01003c5:	8b 15 2c 85 11 f0    	mov    0xf011852c,%edx
f01003cb:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003cf:	eb 78                	jmp    f0100449 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003d1:	66 83 05 28 85 11 f0 	addw   $0x50,0xf0118528
f01003d8:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003d9:	0f b7 05 28 85 11 f0 	movzwl 0xf0118528,%eax
f01003e0:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003e6:	c1 e8 16             	shr    $0x16,%eax
f01003e9:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003ec:	c1 e0 04             	shl    $0x4,%eax
f01003ef:	66 a3 28 85 11 f0    	mov    %ax,0xf0118528
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
f010042b:	0f b7 05 28 85 11 f0 	movzwl 0xf0118528,%eax
f0100432:	8d 50 01             	lea    0x1(%eax),%edx
f0100435:	66 89 15 28 85 11 f0 	mov    %dx,0xf0118528
f010043c:	0f b7 c0             	movzwl %ax,%eax
f010043f:	8b 15 2c 85 11 f0    	mov    0xf011852c,%edx
f0100445:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100449:	66 81 3d 28 85 11 f0 	cmpw   $0x7cf,0xf0118528
f0100450:	cf 07 
f0100452:	76 43                	jbe    f0100497 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100454:	a1 2c 85 11 f0       	mov    0xf011852c,%eax
f0100459:	83 ec 04             	sub    $0x4,%esp
f010045c:	68 00 0f 00 00       	push   $0xf00
f0100461:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100467:	52                   	push   %edx
f0100468:	50                   	push   %eax
f0100469:	e8 7e 33 00 00       	call   f01037ec <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010046e:	8b 15 2c 85 11 f0    	mov    0xf011852c,%edx
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
f010048f:	66 83 2d 28 85 11 f0 	subw   $0x50,0xf0118528
f0100496:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100497:	8b 0d 30 85 11 f0    	mov    0xf0118530,%ecx
f010049d:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004a2:	89 ca                	mov    %ecx,%edx
f01004a4:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004a5:	0f b7 1d 28 85 11 f0 	movzwl 0xf0118528,%ebx
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
f01004cd:	80 3d 34 85 11 f0 00 	cmpb   $0x0,0xf0118534
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
f010050b:	a1 20 85 11 f0       	mov    0xf0118520,%eax
f0100510:	3b 05 24 85 11 f0    	cmp    0xf0118524,%eax
f0100516:	74 26                	je     f010053e <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100518:	8d 50 01             	lea    0x1(%eax),%edx
f010051b:	89 15 20 85 11 f0    	mov    %edx,0xf0118520
f0100521:	0f b6 88 20 83 11 f0 	movzbl -0xfee7ce0(%eax),%ecx
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
f0100532:	c7 05 20 85 11 f0 00 	movl   $0x0,0xf0118520
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
f010056b:	c7 05 30 85 11 f0 b4 	movl   $0x3b4,0xf0118530
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
f0100583:	c7 05 30 85 11 f0 d4 	movl   $0x3d4,0xf0118530
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
f0100592:	8b 3d 30 85 11 f0    	mov    0xf0118530,%edi
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
f01005b7:	89 35 2c 85 11 f0    	mov    %esi,0xf011852c
	crt_pos = pos;
f01005bd:	0f b6 c0             	movzbl %al,%eax
f01005c0:	09 c8                	or     %ecx,%eax
f01005c2:	66 a3 28 85 11 f0    	mov    %ax,0xf0118528
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
f0100623:	0f 95 05 34 85 11 f0 	setne  0xf0118534
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
f0100638:	68 d0 3c 10 f0       	push   $0xf0103cd0
f010063d:	e8 b2 24 00 00       	call   f0102af4 <cprintf>
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

f0100678 <check_lab2>:
	
};
#define NCOMMANDS (sizeof(commands)/sizeof(commands[0]))

/***** Implementations of basic kernel monitor commands *****/
int check_lab2(){
f0100678:	55                   	push   %ebp
f0100679:	89 e5                	mov    %esp,%ebp
f010067b:	83 ec 08             	sub    $0x8,%esp
mem_init();	
f010067e:	e8 98 0d 00 00       	call   f010141b <mem_init>
return 0;
}
f0100683:	b8 00 00 00 00       	mov    $0x0,%eax
f0100688:	c9                   	leave  
f0100689:	c3                   	ret    

f010068a <mon_help>:
	
	return 0;
}
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010068a:	55                   	push   %ebp
f010068b:	89 e5                	mov    %esp,%ebp
f010068d:	56                   	push   %esi
f010068e:	53                   	push   %ebx
f010068f:	bb e4 42 10 f0       	mov    $0xf01042e4,%ebx
f0100694:	be 2c 43 10 f0       	mov    $0xf010432c,%esi
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100699:	83 ec 04             	sub    $0x4,%esp
f010069c:	ff 33                	pushl  (%ebx)
f010069e:	ff 73 fc             	pushl  -0x4(%ebx)
f01006a1:	68 20 3f 10 f0       	push   $0xf0103f20
f01006a6:	e8 49 24 00 00       	call   f0102af4 <cprintf>
f01006ab:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f01006ae:	83 c4 10             	add    $0x10,%esp
f01006b1:	39 f3                	cmp    %esi,%ebx
f01006b3:	75 e4                	jne    f0100699 <mon_help+0xf>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f01006b5:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ba:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01006bd:	5b                   	pop    %ebx
f01006be:	5e                   	pop    %esi
f01006bf:	5d                   	pop    %ebp
f01006c0:	c3                   	ret    

f01006c1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006c1:	55                   	push   %ebp
f01006c2:	89 e5                	mov    %esp,%ebp
f01006c4:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006c7:	68 29 3f 10 f0       	push   $0xf0103f29
f01006cc:	e8 23 24 00 00       	call   f0102af4 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006d1:	83 c4 08             	add    $0x8,%esp
f01006d4:	68 0c 00 10 00       	push   $0x10000c
f01006d9:	68 88 40 10 f0       	push   $0xf0104088
f01006de:	e8 11 24 00 00       	call   f0102af4 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006e3:	83 c4 0c             	add    $0xc,%esp
f01006e6:	68 0c 00 10 00       	push   $0x10000c
f01006eb:	68 0c 00 10 f0       	push   $0xf010000c
f01006f0:	68 b0 40 10 f0       	push   $0xf01040b0
f01006f5:	e8 fa 23 00 00       	call   f0102af4 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006fa:	83 c4 0c             	add    $0xc,%esp
f01006fd:	68 31 3c 10 00       	push   $0x103c31
f0100702:	68 31 3c 10 f0       	push   $0xf0103c31
f0100707:	68 d4 40 10 f0       	push   $0xf01040d4
f010070c:	e8 e3 23 00 00       	call   f0102af4 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100711:	83 c4 0c             	add    $0xc,%esp
f0100714:	68 00 83 11 00       	push   $0x118300
f0100719:	68 00 83 11 f0       	push   $0xf0118300
f010071e:	68 f8 40 10 f0       	push   $0xf01040f8
f0100723:	e8 cc 23 00 00       	call   f0102af4 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100728:	83 c4 0c             	add    $0xc,%esp
f010072b:	68 90 89 11 00       	push   $0x118990
f0100730:	68 90 89 11 f0       	push   $0xf0118990
f0100735:	68 1c 41 10 f0       	push   $0xf010411c
f010073a:	e8 b5 23 00 00       	call   f0102af4 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010073f:	b8 8f 8d 11 f0       	mov    $0xf0118d8f,%eax
f0100744:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100749:	83 c4 08             	add    $0x8,%esp
f010074c:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100751:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100757:	85 c0                	test   %eax,%eax
f0100759:	0f 48 c2             	cmovs  %edx,%eax
f010075c:	c1 f8 0a             	sar    $0xa,%eax
f010075f:	50                   	push   %eax
f0100760:	68 40 41 10 f0       	push   $0xf0104140
f0100765:	e8 8a 23 00 00       	call   f0102af4 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010076a:	b8 00 00 00 00       	mov    $0x0,%eax
f010076f:	c9                   	leave  
f0100770:	c3                   	ret    

f0100771 <showmappings>:
/***** Implementations of basic kernel monitor commands *****/
int check_lab2(){
mem_init();	
return 0;
}
int showmappings(int argc, char **argv, struct Trapframe *tf){
f0100771:	55                   	push   %ebp
f0100772:	89 e5                	mov    %esp,%ebp
f0100774:	57                   	push   %edi
f0100775:	56                   	push   %esi
f0100776:	53                   	push   %ebx
f0100777:	83 ec 30             	sub    $0x30,%esp
f010077a:	8b 75 0c             	mov    0xc(%ebp),%esi
	uintptr_t va_start=(uintptr_t) strtol(argv[1],0,16);
f010077d:	6a 10                	push   $0x10
f010077f:	6a 00                	push   $0x0
f0100781:	ff 76 04             	pushl  0x4(%esi)
f0100784:	e8 3a 31 00 00       	call   f01038c3 <strtol>
f0100789:	89 c3                	mov    %eax,%ebx
	uintptr_t va_end=(uintptr_t) strtol(argv[2],0,16);
f010078b:	83 c4 0c             	add    $0xc,%esp
f010078e:	6a 10                	push   $0x10
f0100790:	6a 00                	push   $0x0
f0100792:	ff 76 08             	pushl  0x8(%esi)
f0100795:	e8 29 31 00 00       	call   f01038c3 <strtol>
		//cprintf("%x\n",va_start);
	struct PageInfo* page;
	physaddr_t pa;
	pte_t* pte;
	uintptr_t va_current;
	va_start=ROUNDDOWN(va_start,PGSIZE);
f010079a:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	va_end=ROUNDUP(va_end,PGSIZE);
f01007a0:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
	int n= (va_end-va_start)/PGSIZE;
f01007a6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01007ac:	29 da                	sub    %ebx,%edx
f01007ae:	c1 ea 0c             	shr    $0xc,%edx
f01007b1:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	cprintf("mapping           permissions\n");
f01007b4:	c7 04 24 6c 41 10 f0 	movl   $0xf010416c,(%esp)
f01007bb:	e8 34 23 00 00       	call   f0102af4 <cprintf>
	for(int i=0;i<n;i++){
f01007c0:	83 c4 10             	add    $0x10,%esp
f01007c3:	be 00 00 00 00       	mov    $0x0,%esi
		va_current=va_start+i*PGSIZE;
		page=page_lookup(kern_pgdir,(void*)va_current,&pte);
f01007c8:	8d 7d e4             	lea    -0x1c(%ebp),%edi
	uintptr_t va_current;
	va_start=ROUNDDOWN(va_start,PGSIZE);
	va_end=ROUNDUP(va_end,PGSIZE);
	int n= (va_end-va_start)/PGSIZE;
	cprintf("mapping           permissions\n");
	for(int i=0;i<n;i++){
f01007cb:	e9 a9 00 00 00       	jmp    f0100879 <showmappings+0x108>
		va_current=va_start+i*PGSIZE;
		page=page_lookup(kern_pgdir,(void*)va_current,&pte);
f01007d0:	83 ec 04             	sub    $0x4,%esp
f01007d3:	57                   	push   %edi
f01007d4:	53                   	push   %ebx
f01007d5:	ff 35 88 89 11 f0    	pushl  0xf0118988
f01007db:	e8 fe 0a 00 00       	call   f01012de <page_lookup>
		if(page==NULL){
f01007e0:	83 c4 10             	add    $0x10,%esp
f01007e3:	85 c0                	test   %eax,%eax
f01007e5:	75 13                	jne    f01007fa <showmappings+0x89>
			cprintf("%08x->unallocated\n",va_current);
f01007e7:	83 ec 08             	sub    $0x8,%esp
f01007ea:	53                   	push   %ebx
f01007eb:	68 42 3f 10 f0       	push   $0xf0103f42
f01007f0:	e8 ff 22 00 00       	call   f0102af4 <cprintf>
			continue;}
f01007f5:	83 c4 10             	add    $0x10,%esp
f01007f8:	eb 76                	jmp    f0100870 <showmappings+0xff>
		pa=page2pa(page);
		cprintf("%08x->%08x       ",va_current,pa);
f01007fa:	83 ec 04             	sub    $0x4,%esp
f01007fd:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0100803:	c1 f8 03             	sar    $0x3,%eax
f0100806:	c1 e0 0c             	shl    $0xc,%eax
f0100809:	50                   	push   %eax
f010080a:	53                   	push   %ebx
f010080b:	68 55 3f 10 f0       	push   $0xf0103f55
f0100810:	e8 df 22 00 00       	call   f0102af4 <cprintf>
		if(*pte& PTE_P){cprintf("PTE_P ");}
f0100815:	83 c4 10             	add    $0x10,%esp
f0100818:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010081b:	f6 00 01             	testb  $0x1,(%eax)
f010081e:	74 10                	je     f0100830 <showmappings+0xbf>
f0100820:	83 ec 0c             	sub    $0xc,%esp
f0100823:	68 67 3f 10 f0       	push   $0xf0103f67
f0100828:	e8 c7 22 00 00       	call   f0102af4 <cprintf>
f010082d:	83 c4 10             	add    $0x10,%esp
		if(*pte& PTE_U){cprintf("PTE_U ");}
f0100830:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100833:	f6 00 04             	testb  $0x4,(%eax)
f0100836:	74 10                	je     f0100848 <showmappings+0xd7>
f0100838:	83 ec 0c             	sub    $0xc,%esp
f010083b:	68 6e 3f 10 f0       	push   $0xf0103f6e
f0100840:	e8 af 22 00 00       	call   f0102af4 <cprintf>
f0100845:	83 c4 10             	add    $0x10,%esp
		if(*pte& PTE_W){cprintf("PTE_W ");}
f0100848:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010084b:	f6 00 02             	testb  $0x2,(%eax)
f010084e:	74 10                	je     f0100860 <showmappings+0xef>
f0100850:	83 ec 0c             	sub    $0xc,%esp
f0100853:	68 75 3f 10 f0       	push   $0xf0103f75
f0100858:	e8 97 22 00 00       	call   f0102af4 <cprintf>
f010085d:	83 c4 10             	add    $0x10,%esp
		cprintf("\n");
f0100860:	83 ec 0c             	sub    $0xc,%esp
f0100863:	68 ce 4d 10 f0       	push   $0xf0104dce
f0100868:	e8 87 22 00 00       	call   f0102af4 <cprintf>
f010086d:	83 c4 10             	add    $0x10,%esp
	uintptr_t va_current;
	va_start=ROUNDDOWN(va_start,PGSIZE);
	va_end=ROUNDUP(va_end,PGSIZE);
	int n= (va_end-va_start)/PGSIZE;
	cprintf("mapping           permissions\n");
	for(int i=0;i<n;i++){
f0100870:	83 c6 01             	add    $0x1,%esi
f0100873:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100879:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f010087c:	0f 8c 4e ff ff ff    	jl     f01007d0 <showmappings+0x5f>
		if(*pte& PTE_W){cprintf("PTE_W ");}
		cprintf("\n");
	}
	
	return 0;
}
f0100882:	b8 00 00 00 00       	mov    $0x0,%eax
f0100887:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010088a:	5b                   	pop    %ebx
f010088b:	5e                   	pop    %esi
f010088c:	5f                   	pop    %edi
f010088d:	5d                   	pop    %ebp
f010088e:	c3                   	ret    

f010088f <update_page_perm>:
int update_page_perm(int argc, char **argv, struct Trapframe *tf){
f010088f:	55                   	push   %ebp
f0100890:	89 e5                	mov    %esp,%ebp
f0100892:	57                   	push   %edi
f0100893:	56                   	push   %esi
f0100894:	53                   	push   %ebx
f0100895:	83 ec 20             	sub    $0x20,%esp
f0100898:	8b 7d 0c             	mov    0xc(%ebp),%edi
	
	uintptr_t va_start=(uintptr_t) strtol(argv[1],0,16);
f010089b:	6a 10                	push   $0x10
f010089d:	6a 00                	push   $0x0
f010089f:	ff 77 04             	pushl  0x4(%edi)
f01008a2:	e8 1c 30 00 00       	call   f01038c3 <strtol>
f01008a7:	89 c3                	mov    %eax,%ebx
	uintptr_t va_end=(uintptr_t) strtol(argv[2],0,16);
f01008a9:	83 c4 0c             	add    $0xc,%esp
f01008ac:	6a 10                	push   $0x10
f01008ae:	6a 00                	push   $0x0
f01008b0:	ff 77 08             	pushl  0x8(%edi)
f01008b3:	e8 0b 30 00 00       	call   f01038c3 <strtol>
f01008b8:	89 c6                	mov    %eax,%esi
	uint32_t perm=(uint32_t) strtol(argv[3],0,16);
f01008ba:	83 c4 0c             	add    $0xc,%esp
f01008bd:	6a 10                	push   $0x10
f01008bf:	6a 00                	push   $0x0
f01008c1:	ff 77 0c             	pushl  0xc(%edi)
f01008c4:	e8 fa 2f 00 00       	call   f01038c3 <strtol>
f01008c9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	pte_t* pte;
	uintptr_t va_current;
	va_start=ROUNDDOWN(va_start,PGSIZE);
f01008cc:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	va_end=ROUNDUP(va_end,PGSIZE);
f01008d2:	8d be ff 0f 00 00    	lea    0xfff(%esi),%edi
	int n= (va_end-va_start)/PGSIZE;
f01008d8:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f01008de:	29 df                	sub    %ebx,%edi
f01008e0:	c1 ef 0c             	shr    $0xc,%edi
		for(int i=0;i<n;i++){
f01008e3:	83 c4 10             	add    $0x10,%esp
f01008e6:	be 00 00 00 00       	mov    $0x0,%esi
f01008eb:	eb 41                	jmp    f010092e <update_page_perm+0x9f>
		va_current=va_start+i*PGSIZE;
		pte=pgdir_walk(kern_pgdir, (void*)va_current, false);
f01008ed:	83 ec 04             	sub    $0x4,%esp
f01008f0:	6a 00                	push   $0x0
f01008f2:	53                   	push   %ebx
f01008f3:	ff 35 88 89 11 f0    	pushl  0xf0118988
f01008f9:	e8 85 08 00 00       	call   f0101183 <pgdir_walk>
		if(pte==NULL){
f01008fe:	83 c4 10             	add    $0x10,%esp
f0100901:	85 c0                	test   %eax,%eax
f0100903:	75 13                	jne    f0100918 <update_page_perm+0x89>
			cprintf("update failed! page mapped at va %08x is unallocated\n",va_current);
f0100905:	83 ec 08             	sub    $0x8,%esp
f0100908:	53                   	push   %ebx
f0100909:	68 8c 41 10 f0       	push   $0xf010418c
f010090e:	e8 e1 21 00 00       	call   f0102af4 <cprintf>
f0100913:	83 c4 10             	add    $0x10,%esp
f0100916:	eb 0d                	jmp    f0100925 <update_page_perm+0x96>
			}
			else{
				pte[0]=(pte[0]&(~0xFFF))|perm;
f0100918:	8b 10                	mov    (%eax),%edx
f010091a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100920:	0b 55 e4             	or     -0x1c(%ebp),%edx
f0100923:	89 10                	mov    %edx,(%eax)
	pte_t* pte;
	uintptr_t va_current;
	va_start=ROUNDDOWN(va_start,PGSIZE);
	va_end=ROUNDUP(va_end,PGSIZE);
	int n= (va_end-va_start)/PGSIZE;
		for(int i=0;i<n;i++){
f0100925:	83 c6 01             	add    $0x1,%esi
f0100928:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010092e:	39 fe                	cmp    %edi,%esi
f0100930:	7c bb                	jl     f01008ed <update_page_perm+0x5e>
				pte[0]=(pte[0]&(~0xFFF))|perm;
			}
	}
	
	return 0;
}
f0100932:	b8 00 00 00 00       	mov    $0x0,%eax
f0100937:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010093a:	5b                   	pop    %ebx
f010093b:	5e                   	pop    %esi
f010093c:	5f                   	pop    %edi
f010093d:	5d                   	pop    %ebp
f010093e:	c3                   	ret    

f010093f <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010093f:	55                   	push   %ebp
f0100940:	89 e5                	mov    %esp,%ebp
f0100942:	57                   	push   %edi
f0100943:	56                   	push   %esi
f0100944:	53                   	push   %ebx
f0100945:	83 ec 38             	sub    $0x38,%esp
	cprintf("Stack backtrace:\n");
f0100948:	68 7c 3f 10 f0       	push   $0xf0103f7c
f010094d:	e8 a2 21 00 00       	call   f0102af4 <cprintf>
f0100952:	83 c4 10             	add    $0x10,%esp
		uint32_t arg4=*(int*)(ebp+20);
		uint32_t arg5=*(int*)(ebp+24);
		cprintf("ebp %x  eip %x  args %08x %08x %08x %08x %08x\n",ebp,eip,arg1,arg2,arg3,arg4,arg5);
		struct Eipdebuginfo info_={"<unknown>",0,"<unknown>",9,0,0};
		struct Eipdebuginfo* info= &info_;
		debuginfo_eip(eip,info);
f0100955:	8d 75 d0             	lea    -0x30(%ebp),%esi
f0100958:	eb 05                	jmp    f010095f <mon_backtrace+0x20>
{
	cprintf("Stack backtrace:\n");
	uint32_t ebp=0xffffffff;
	//cprintf("%x\n",read_ebp());
	while(ebp!=0){
	if(ebp==0xffffffff){
f010095a:	83 fb ff             	cmp    $0xffffffff,%ebx
f010095d:	75 04                	jne    f0100963 <mon_backtrace+0x24>

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010095f:	89 eb                	mov    %ebp,%ebx
f0100961:	eb 02                	jmp    f0100965 <mon_backtrace+0x26>
		ebp=read_ebp();
	}
		else{
		ebp=*(int*)ebp;
f0100963:	8b 1b                	mov    (%ebx),%ebx
		}
		uint32_t eip=*(int*)(ebp+4);
f0100965:	8b 7b 04             	mov    0x4(%ebx),%edi
		uint32_t arg1=*(int*)(ebp+8);
		uint32_t arg2=*(int*)(ebp+12);
		uint32_t arg3=*(int*)(ebp+16);
		uint32_t arg4=*(int*)(ebp+20);
		uint32_t arg5=*(int*)(ebp+24);
		cprintf("ebp %x  eip %x  args %08x %08x %08x %08x %08x\n",ebp,eip,arg1,arg2,arg3,arg4,arg5);
f0100968:	ff 73 18             	pushl  0x18(%ebx)
f010096b:	ff 73 14             	pushl  0x14(%ebx)
f010096e:	ff 73 10             	pushl  0x10(%ebx)
f0100971:	ff 73 0c             	pushl  0xc(%ebx)
f0100974:	ff 73 08             	pushl  0x8(%ebx)
f0100977:	57                   	push   %edi
f0100978:	53                   	push   %ebx
f0100979:	68 c4 41 10 f0       	push   $0xf01041c4
f010097e:	e8 71 21 00 00       	call   f0102af4 <cprintf>
		struct Eipdebuginfo info_={"<unknown>",0,"<unknown>",9,0,0};
f0100983:	c7 45 d0 8e 3f 10 f0 	movl   $0xf0103f8e,-0x30(%ebp)
f010098a:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f0100991:	c7 45 d8 8e 3f 10 f0 	movl   $0xf0103f8e,-0x28(%ebp)
f0100998:	c7 45 dc 09 00 00 00 	movl   $0x9,-0x24(%ebp)
f010099f:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01009a6:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		struct Eipdebuginfo* info= &info_;
		debuginfo_eip(eip,info);
f01009ad:	83 c4 18             	add    $0x18,%esp
f01009b0:	56                   	push   %esi
f01009b1:	57                   	push   %edi
f01009b2:	e8 47 22 00 00       	call   f0102bfe <debuginfo_eip>
		//*(p)='\0';
		cprintf("       %s:%d: ",info->eip_file,info->eip_line );
f01009b7:	83 c4 0c             	add    $0xc,%esp
f01009ba:	ff 75 d4             	pushl  -0x2c(%ebp)
f01009bd:	ff 75 d0             	pushl  -0x30(%ebp)
f01009c0:	68 98 3f 10 f0       	push   $0xf0103f98
f01009c5:	e8 2a 21 00 00       	call   f0102af4 <cprintf>
		cprintf("%.*s",info->eip_fn_namelen,info->eip_fn_name);
f01009ca:	83 c4 0c             	add    $0xc,%esp
f01009cd:	ff 75 d8             	pushl  -0x28(%ebp)
f01009d0:	ff 75 dc             	pushl  -0x24(%ebp)
f01009d3:	68 a7 3f 10 f0       	push   $0xf0103fa7
f01009d8:	e8 17 21 00 00       	call   f0102af4 <cprintf>
		cprintf("+%d\n",info->eip_fn_narg);
f01009dd:	83 c4 08             	add    $0x8,%esp
f01009e0:	ff 75 e4             	pushl  -0x1c(%ebp)
f01009e3:	68 ac 3f 10 f0       	push   $0xf0103fac
f01009e8:	e8 07 21 00 00       	call   f0102af4 <cprintf>
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	cprintf("Stack backtrace:\n");
	uint32_t ebp=0xffffffff;
	//cprintf("%x\n",read_ebp());
	while(ebp!=0){
f01009ed:	83 c4 10             	add    $0x10,%esp
f01009f0:	85 db                	test   %ebx,%ebx
f01009f2:	0f 85 62 ff ff ff    	jne    f010095a <mon_backtrace+0x1b>
		cprintf("       %s:%d: ",info->eip_file,info->eip_line );
		cprintf("%.*s",info->eip_fn_namelen,info->eip_fn_name);
		cprintf("+%d\n",info->eip_fn_narg);
	}
	return 0;
}
f01009f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01009fd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a00:	5b                   	pop    %ebx
f0100a01:	5e                   	pop    %esi
f0100a02:	5f                   	pop    %edi
f0100a03:	5d                   	pop    %ebp
f0100a04:	c3                   	ret    

f0100a05 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100a05:	55                   	push   %ebp
f0100a06:	89 e5                	mov    %esp,%ebp
f0100a08:	57                   	push   %edi
f0100a09:	56                   	push   %esi
f0100a0a:	53                   	push   %ebx
f0100a0b:	81 ec ec 01 00 00    	sub    $0x1ec,%esp
f0100a11:	8d 95 58 fe ff ff    	lea    -0x1a8(%ebp),%edx
f0100a17:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
	char* cmd_history[MAX_CMD_SIZE];
	for(int i=0;i<MAX_CMD_SIZE;i++){
		cmd_history[i]=(char*)(i*100+KERNBASE);
f0100a1c:	89 02                	mov    %eax,(%edx)
f0100a1e:	83 c0 64             	add    $0x64,%eax
f0100a21:	83 c2 04             	add    $0x4,%edx

void
monitor(struct Trapframe *tf)
{
	char* cmd_history[MAX_CMD_SIZE];
	for(int i=0;i<MAX_CMD_SIZE;i++){
f0100a24:	3d 10 27 00 f0       	cmp    $0xf0002710,%eax
f0100a29:	75 f1                	jne    f0100a1c <monitor+0x17>
	}
	int current_cmd=0;
	char *buf;
	//char buf_copy[MAX_CMD_SIZE];
	//char* buf_p=buf_copy;
	cprintf("Welcome to the JOS kernel monitor!\n");
f0100a2b:	83 ec 0c             	sub    $0xc,%esp
f0100a2e:	68 f4 41 10 f0       	push   $0xf01041f4
f0100a33:	e8 bc 20 00 00       	call   f0102af4 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100a38:	c7 04 24 18 42 10 f0 	movl   $0xf0104218,(%esp)
f0100a3f:	e8 b0 20 00 00       	call   f0102af4 <cprintf>
    cprintf("x=%d y=%d", 3);
f0100a44:	83 c4 08             	add    $0x8,%esp
f0100a47:	6a 03                	push   $0x3
f0100a49:	68 b1 3f 10 f0       	push   $0xf0103fb1
f0100a4e:	e8 a1 20 00 00       	call   f0102af4 <cprintf>
cprintf("\n");
f0100a53:	c7 04 24 ce 4d 10 f0 	movl   $0xf0104dce,(%esp)
f0100a5a:	e8 95 20 00 00       	call   f0102af4 <cprintf>
};
#define NCOMMANDS (sizeof(commands)/sizeof(commands[0]))

/***** Implementations of basic kernel monitor commands *****/
int check_lab2(){
mem_init();	
f0100a5f:	e8 b7 09 00 00       	call   f010141b <mem_init>
f0100a64:	83 c4 10             	add    $0x10,%esp
{
	char* cmd_history[MAX_CMD_SIZE];
	for(int i=0;i<MAX_CMD_SIZE;i++){
		cmd_history[i]=(char*)(i*100+KERNBASE);
	}
	int current_cmd=0;
f0100a67:	c7 85 14 fe ff ff 00 	movl   $0x0,-0x1ec(%ebp)
f0100a6e:	00 00 00 
	cprintf("Type 'help' for a list of commands.\n");
    cprintf("x=%d y=%d", 3);
cprintf("\n");
check_lab2();
	while (1) {
		buf = readline("K> ",cmd_history,current_cmd);
f0100a71:	83 ec 04             	sub    $0x4,%esp
f0100a74:	8b b5 14 fe ff ff    	mov    -0x1ec(%ebp),%esi
f0100a7a:	56                   	push   %esi
f0100a7b:	8d 85 58 fe ff ff    	lea    -0x1a8(%ebp),%eax
f0100a81:	50                   	push   %eax
f0100a82:	68 bb 3f 10 f0       	push   $0xf0103fbb
f0100a87:	e8 d8 28 00 00       	call   f0103364 <readline>
f0100a8c:	89 c3                	mov    %eax,%ebx
		//cprintf("current_cmd%x",cmd_history[current_cmd]);
		strcpy(cmd_history[current_cmd],buf);
f0100a8e:	83 c4 08             	add    $0x8,%esp
f0100a91:	50                   	push   %eax
f0100a92:	ff b4 b5 58 fe ff ff 	pushl  -0x1a8(%ebp,%esi,4)
f0100a99:	e8 bc 2b 00 00       	call   f010365a <strcpy>
		//cmd_history[current_cmd]=buf;
		current_cmd++;
f0100a9e:	89 f0                	mov    %esi,%eax
f0100aa0:	83 c0 01             	add    $0x1,%eax
f0100aa3:	89 85 14 fe ff ff    	mov    %eax,-0x1ec(%ebp)
		//cprintf("command[0],%x\n",cmd_history[0]);
		//cprintf("%s",buf_copy);
		if (buf != NULL)
f0100aa9:	83 c4 10             	add    $0x10,%esp
f0100aac:	85 db                	test   %ebx,%ebx
f0100aae:	74 c1                	je     f0100a71 <monitor+0x6c>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100ab0:	c7 85 18 fe ff ff 00 	movl   $0x0,-0x1e8(%ebp)
f0100ab7:	00 00 00 
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100aba:	be 00 00 00 00       	mov    $0x0,%esi
f0100abf:	eb 0a                	jmp    f0100acb <monitor+0xc6>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100ac1:	c6 03 00             	movb   $0x0,(%ebx)
f0100ac4:	89 f7                	mov    %esi,%edi
f0100ac6:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100ac9:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100acb:	0f b6 03             	movzbl (%ebx),%eax
f0100ace:	84 c0                	test   %al,%al
f0100ad0:	74 69                	je     f0100b3b <monitor+0x136>
f0100ad2:	83 ec 08             	sub    $0x8,%esp
f0100ad5:	0f be c0             	movsbl %al,%eax
f0100ad8:	50                   	push   %eax
f0100ad9:	68 bf 3f 10 f0       	push   $0xf0103fbf
f0100ade:	e8 7f 2c 00 00       	call   f0103762 <strchr>
f0100ae3:	83 c4 10             	add    $0x10,%esp
f0100ae6:	85 c0                	test   %eax,%eax
f0100ae8:	75 d7                	jne    f0100ac1 <monitor+0xbc>
			*buf++ = 0;
		if (*buf == 0)
f0100aea:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100aed:	74 4c                	je     f0100b3b <monitor+0x136>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100aef:	83 fe 0f             	cmp    $0xf,%esi
f0100af2:	75 17                	jne    f0100b0b <monitor+0x106>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100af4:	83 ec 08             	sub    $0x8,%esp
f0100af7:	6a 10                	push   $0x10
f0100af9:	68 c4 3f 10 f0       	push   $0xf0103fc4
f0100afe:	e8 f1 1f 00 00       	call   f0102af4 <cprintf>
f0100b03:	83 c4 10             	add    $0x10,%esp
f0100b06:	e9 66 ff ff ff       	jmp    f0100a71 <monitor+0x6c>
			return 0;
		}
		argv[argc++] = buf;
f0100b0b:	8d 7e 01             	lea    0x1(%esi),%edi
f0100b0e:	89 9c b5 18 fe ff ff 	mov    %ebx,-0x1e8(%ebp,%esi,4)
f0100b15:	eb 03                	jmp    f0100b1a <monitor+0x115>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100b17:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100b1a:	0f b6 03             	movzbl (%ebx),%eax
f0100b1d:	84 c0                	test   %al,%al
f0100b1f:	74 a8                	je     f0100ac9 <monitor+0xc4>
f0100b21:	83 ec 08             	sub    $0x8,%esp
f0100b24:	0f be c0             	movsbl %al,%eax
f0100b27:	50                   	push   %eax
f0100b28:	68 bf 3f 10 f0       	push   $0xf0103fbf
f0100b2d:	e8 30 2c 00 00       	call   f0103762 <strchr>
f0100b32:	83 c4 10             	add    $0x10,%esp
f0100b35:	85 c0                	test   %eax,%eax
f0100b37:	74 de                	je     f0100b17 <monitor+0x112>
f0100b39:	eb 8e                	jmp    f0100ac9 <monitor+0xc4>
			buf++;
	}
	argv[argc] = 0;
f0100b3b:	c7 84 b5 18 fe ff ff 	movl   $0x0,-0x1e8(%ebp,%esi,4)
f0100b42:	00 00 00 00 

	// Lookup and invoke the command
	if (argc == 0)
f0100b46:	85 f6                	test   %esi,%esi
f0100b48:	0f 84 23 ff ff ff    	je     f0100a71 <monitor+0x6c>
f0100b4e:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100b53:	83 ec 08             	sub    $0x8,%esp
f0100b56:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b59:	ff 34 85 e0 42 10 f0 	pushl  -0xfefbd20(,%eax,4)
f0100b60:	ff b5 18 fe ff ff    	pushl  -0x1e8(%ebp)
f0100b66:	e8 99 2b 00 00       	call   f0103704 <strcmp>
f0100b6b:	83 c4 10             	add    $0x10,%esp
f0100b6e:	85 c0                	test   %eax,%eax
f0100b70:	75 25                	jne    f0100b97 <monitor+0x192>
			return commands[i].func(argc, argv, tf);
f0100b72:	83 ec 04             	sub    $0x4,%esp
f0100b75:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b78:	ff 75 08             	pushl  0x8(%ebp)
f0100b7b:	8d 8d 18 fe ff ff    	lea    -0x1e8(%ebp),%ecx
f0100b81:	51                   	push   %ecx
f0100b82:	56                   	push   %esi
f0100b83:	ff 14 85 e8 42 10 f0 	call   *-0xfefbd18(,%eax,4)
		//cmd_history[current_cmd]=buf;
		current_cmd++;
		//cprintf("command[0],%x\n",cmd_history[0]);
		//cprintf("%s",buf_copy);
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100b8a:	83 c4 10             	add    $0x10,%esp
f0100b8d:	85 c0                	test   %eax,%eax
f0100b8f:	0f 89 dc fe ff ff    	jns    f0100a71 <monitor+0x6c>
f0100b95:	eb 23                	jmp    f0100bba <monitor+0x1b5>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100b97:	83 c3 01             	add    $0x1,%ebx
f0100b9a:	83 fb 06             	cmp    $0x6,%ebx
f0100b9d:	75 b4                	jne    f0100b53 <monitor+0x14e>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100b9f:	83 ec 08             	sub    $0x8,%esp
f0100ba2:	ff b5 18 fe ff ff    	pushl  -0x1e8(%ebp)
f0100ba8:	68 e1 3f 10 f0       	push   $0xf0103fe1
f0100bad:	e8 42 1f 00 00       	call   f0102af4 <cprintf>
f0100bb2:	83 c4 10             	add    $0x10,%esp
f0100bb5:	e9 b7 fe ff ff       	jmp    f0100a71 <monitor+0x6c>
		//cprintf("%s",buf_copy);
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100bba:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100bbd:	5b                   	pop    %ebx
f0100bbe:	5e                   	pop    %esi
f0100bbf:	5f                   	pop    %edi
f0100bc0:	5d                   	pop    %ebp
f0100bc1:	c3                   	ret    

f0100bc2 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100bc2:	55                   	push   %ebp
f0100bc3:	89 e5                	mov    %esp,%ebp
f0100bc5:	56                   	push   %esi
f0100bc6:	53                   	push   %ebx
f0100bc7:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100bc9:	83 ec 0c             	sub    $0xc,%esp
f0100bcc:	50                   	push   %eax
f0100bcd:	e8 bb 1e 00 00       	call   f0102a8d <mc146818_read>
f0100bd2:	89 c6                	mov    %eax,%esi
f0100bd4:	83 c3 01             	add    $0x1,%ebx
f0100bd7:	89 1c 24             	mov    %ebx,(%esp)
f0100bda:	e8 ae 1e 00 00       	call   f0102a8d <mc146818_read>
f0100bdf:	c1 e0 08             	shl    $0x8,%eax
f0100be2:	09 f0                	or     %esi,%eax
}
f0100be4:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100be7:	5b                   	pop    %ebx
f0100be8:	5e                   	pop    %esi
f0100be9:	5d                   	pop    %ebp
f0100bea:	c3                   	ret    

f0100beb <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100beb:	89 d1                	mov    %edx,%ecx
f0100bed:	c1 e9 16             	shr    $0x16,%ecx
f0100bf0:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100bf3:	a8 01                	test   $0x1,%al
f0100bf5:	74 52                	je     f0100c49 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100bf7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bfc:	89 c1                	mov    %eax,%ecx
f0100bfe:	c1 e9 0c             	shr    $0xc,%ecx
f0100c01:	3b 0d 84 89 11 f0    	cmp    0xf0118984,%ecx
f0100c07:	72 1b                	jb     f0100c24 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100c09:	55                   	push   %ebp
f0100c0a:	89 e5                	mov    %esp,%ebp
f0100c0c:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c0f:	50                   	push   %eax
f0100c10:	68 28 43 10 f0       	push   $0xf0104328
f0100c15:	68 e1 02 00 00       	push   $0x2e1
f0100c1a:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0100c1f:	e8 c2 f4 ff ff       	call   f01000e6 <_panic>
	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	//cprintf("%x,page table in check\n",p);
	if (!(p[PTX(va)] & PTE_P))
f0100c24:	c1 ea 0c             	shr    $0xc,%edx
f0100c27:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100c2d:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100c34:	89 c2                	mov    %eax,%edx
f0100c36:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100c39:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c3e:	85 d2                	test   %edx,%edx
f0100c40:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100c45:	0f 44 c2             	cmove  %edx,%eax
f0100c48:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100c49:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	//cprintf("%x,page table in check\n",p);
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100c4e:	c3                   	ret    

f0100c4f <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100c4f:	55                   	push   %ebp
f0100c50:	89 e5                	mov    %esp,%ebp
f0100c52:	83 ec 08             	sub    $0x8,%esp
f0100c55:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100c57:	83 3d 38 85 11 f0 00 	cmpl   $0x0,0xf0118538
f0100c5e:	75 0f                	jne    f0100c6f <boot_alloc+0x20>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100c60:	b8 8f 99 11 f0       	mov    $0xf011998f,%eax
f0100c65:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c6a:	a3 38 85 11 f0       	mov    %eax,0xf0118538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result=nextfree;
f0100c6f:	a1 38 85 11 f0       	mov    0xf0118538,%eax
	if(n>0){
f0100c74:	85 d2                	test   %edx,%edx
f0100c76:	74 13                	je     f0100c8b <boot_alloc+0x3c>
		nextfree= ROUNDUP(nextfree+n, PGSIZE);
f0100c78:	8d 94 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%edx
f0100c7f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100c85:	89 15 38 85 11 f0    	mov    %edx,0xf0118538
	}
	if(PADDR(nextfree)>=(npages*PGSIZE)){
f0100c8b:	8b 15 38 85 11 f0    	mov    0xf0118538,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100c91:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0100c97:	77 12                	ja     f0100cab <boot_alloc+0x5c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100c99:	52                   	push   %edx
f0100c9a:	68 4c 43 10 f0       	push   $0xf010434c
f0100c9f:	6a 6d                	push   $0x6d
f0100ca1:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0100ca6:	e8 3b f4 ff ff       	call   f01000e6 <_panic>
f0100cab:	8b 0d 84 89 11 f0    	mov    0xf0118984,%ecx
f0100cb1:	c1 e1 0c             	shl    $0xc,%ecx
f0100cb4:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0100cba:	39 d1                	cmp    %edx,%ecx
f0100cbc:	77 14                	ja     f0100cd2 <boot_alloc+0x83>
		//cprintf("nextfree is %x,npages*PGSIZE is %x",nextfree,(char*)(npages*PGSIZE));
		panic("out of memory!");
f0100cbe:	83 ec 04             	sub    $0x4,%esp
f0100cc1:	68 e0 4a 10 f0       	push   $0xf0104ae0
f0100cc6:	6a 6f                	push   $0x6f
f0100cc8:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0100ccd:	e8 14 f4 ff ff       	call   f01000e6 <_panic>
	}
	return result;
}
f0100cd2:	c9                   	leave  
f0100cd3:	c3                   	ret    

f0100cd4 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100cd4:	55                   	push   %ebp
f0100cd5:	89 e5                	mov    %esp,%ebp
f0100cd7:	57                   	push   %edi
f0100cd8:	56                   	push   %esi
f0100cd9:	53                   	push   %ebx
f0100cda:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100cdd:	84 c0                	test   %al,%al
f0100cdf:	0f 85 81 02 00 00    	jne    f0100f66 <check_page_free_list+0x292>
f0100ce5:	e9 8e 02 00 00       	jmp    f0100f78 <check_page_free_list+0x2a4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100cea:	83 ec 04             	sub    $0x4,%esp
f0100ced:	68 70 43 10 f0       	push   $0xf0104370
f0100cf2:	68 22 02 00 00       	push   $0x222
f0100cf7:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0100cfc:	e8 e5 f3 ff ff       	call   f01000e6 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100d01:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100d04:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100d07:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100d0a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100d0d:	89 c2                	mov    %eax,%edx
f0100d0f:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f0100d15:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100d1b:	0f 95 c2             	setne  %dl
f0100d1e:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100d21:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100d25:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100d27:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d2b:	8b 00                	mov    (%eax),%eax
f0100d2d:	85 c0                	test   %eax,%eax
f0100d2f:	75 dc                	jne    f0100d0d <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100d31:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d34:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100d3a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d3d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100d40:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100d42:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100d45:	a3 3c 85 11 f0       	mov    %eax,0xf011853c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100d4a:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d4f:	8b 1d 3c 85 11 f0    	mov    0xf011853c,%ebx
f0100d55:	eb 53                	jmp    f0100daa <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d57:	89 d8                	mov    %ebx,%eax
f0100d59:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0100d5f:	c1 f8 03             	sar    $0x3,%eax
f0100d62:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100d65:	89 c2                	mov    %eax,%edx
f0100d67:	c1 ea 16             	shr    $0x16,%edx
f0100d6a:	39 f2                	cmp    %esi,%edx
f0100d6c:	73 3a                	jae    f0100da8 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d6e:	89 c2                	mov    %eax,%edx
f0100d70:	c1 ea 0c             	shr    $0xc,%edx
f0100d73:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f0100d79:	72 12                	jb     f0100d8d <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d7b:	50                   	push   %eax
f0100d7c:	68 28 43 10 f0       	push   $0xf0104328
f0100d81:	6a 54                	push   $0x54
f0100d83:	68 ef 4a 10 f0       	push   $0xf0104aef
f0100d88:	e8 59 f3 ff ff       	call   f01000e6 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100d8d:	83 ec 04             	sub    $0x4,%esp
f0100d90:	68 80 00 00 00       	push   $0x80
f0100d95:	68 97 00 00 00       	push   $0x97
f0100d9a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d9f:	50                   	push   %eax
f0100da0:	e8 fa 29 00 00       	call   f010379f <memset>
f0100da5:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100da8:	8b 1b                	mov    (%ebx),%ebx
f0100daa:	85 db                	test   %ebx,%ebx
f0100dac:	75 a9                	jne    f0100d57 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100dae:	b8 00 00 00 00       	mov    $0x0,%eax
f0100db3:	e8 97 fe ff ff       	call   f0100c4f <boot_alloc>
f0100db8:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100dbb:	8b 15 3c 85 11 f0    	mov    0xf011853c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100dc1:	8b 0d 8c 89 11 f0    	mov    0xf011898c,%ecx
		assert(pp < pages + npages);
f0100dc7:	a1 84 89 11 f0       	mov    0xf0118984,%eax
f0100dcc:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100dcf:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100dd2:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100dd5:	be 00 00 00 00       	mov    $0x0,%esi
f0100dda:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ddd:	e9 30 01 00 00       	jmp    f0100f12 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100de2:	39 ca                	cmp    %ecx,%edx
f0100de4:	73 19                	jae    f0100dff <check_page_free_list+0x12b>
f0100de6:	68 fd 4a 10 f0       	push   $0xf0104afd
f0100deb:	68 09 4b 10 f0       	push   $0xf0104b09
f0100df0:	68 3c 02 00 00       	push   $0x23c
f0100df5:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0100dfa:	e8 e7 f2 ff ff       	call   f01000e6 <_panic>
		assert(pp < pages + npages);
f0100dff:	39 fa                	cmp    %edi,%edx
f0100e01:	72 19                	jb     f0100e1c <check_page_free_list+0x148>
f0100e03:	68 1e 4b 10 f0       	push   $0xf0104b1e
f0100e08:	68 09 4b 10 f0       	push   $0xf0104b09
f0100e0d:	68 3d 02 00 00       	push   $0x23d
f0100e12:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0100e17:	e8 ca f2 ff ff       	call   f01000e6 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100e1c:	89 d0                	mov    %edx,%eax
f0100e1e:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100e21:	a8 07                	test   $0x7,%al
f0100e23:	74 19                	je     f0100e3e <check_page_free_list+0x16a>
f0100e25:	68 94 43 10 f0       	push   $0xf0104394
f0100e2a:	68 09 4b 10 f0       	push   $0xf0104b09
f0100e2f:	68 3e 02 00 00       	push   $0x23e
f0100e34:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0100e39:	e8 a8 f2 ff ff       	call   f01000e6 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e3e:	c1 f8 03             	sar    $0x3,%eax
f0100e41:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100e44:	85 c0                	test   %eax,%eax
f0100e46:	75 19                	jne    f0100e61 <check_page_free_list+0x18d>
f0100e48:	68 32 4b 10 f0       	push   $0xf0104b32
f0100e4d:	68 09 4b 10 f0       	push   $0xf0104b09
f0100e52:	68 41 02 00 00       	push   $0x241
f0100e57:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0100e5c:	e8 85 f2 ff ff       	call   f01000e6 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100e61:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100e66:	75 19                	jne    f0100e81 <check_page_free_list+0x1ad>
f0100e68:	68 43 4b 10 f0       	push   $0xf0104b43
f0100e6d:	68 09 4b 10 f0       	push   $0xf0104b09
f0100e72:	68 42 02 00 00       	push   $0x242
f0100e77:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0100e7c:	e8 65 f2 ff ff       	call   f01000e6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100e81:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100e86:	75 19                	jne    f0100ea1 <check_page_free_list+0x1cd>
f0100e88:	68 c8 43 10 f0       	push   $0xf01043c8
f0100e8d:	68 09 4b 10 f0       	push   $0xf0104b09
f0100e92:	68 43 02 00 00       	push   $0x243
f0100e97:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0100e9c:	e8 45 f2 ff ff       	call   f01000e6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100ea1:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100ea6:	75 19                	jne    f0100ec1 <check_page_free_list+0x1ed>
f0100ea8:	68 5c 4b 10 f0       	push   $0xf0104b5c
f0100ead:	68 09 4b 10 f0       	push   $0xf0104b09
f0100eb2:	68 44 02 00 00       	push   $0x244
f0100eb7:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0100ebc:	e8 25 f2 ff ff       	call   f01000e6 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100ec1:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100ec6:	76 3f                	jbe    f0100f07 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ec8:	89 c3                	mov    %eax,%ebx
f0100eca:	c1 eb 0c             	shr    $0xc,%ebx
f0100ecd:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100ed0:	77 12                	ja     f0100ee4 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ed2:	50                   	push   %eax
f0100ed3:	68 28 43 10 f0       	push   $0xf0104328
f0100ed8:	6a 54                	push   $0x54
f0100eda:	68 ef 4a 10 f0       	push   $0xf0104aef
f0100edf:	e8 02 f2 ff ff       	call   f01000e6 <_panic>
f0100ee4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ee9:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100eec:	76 1e                	jbe    f0100f0c <check_page_free_list+0x238>
f0100eee:	68 ec 43 10 f0       	push   $0xf01043ec
f0100ef3:	68 09 4b 10 f0       	push   $0xf0104b09
f0100ef8:	68 45 02 00 00       	push   $0x245
f0100efd:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0100f02:	e8 df f1 ff ff       	call   f01000e6 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100f07:	83 c6 01             	add    $0x1,%esi
f0100f0a:	eb 04                	jmp    f0100f10 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100f0c:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f10:	8b 12                	mov    (%edx),%edx
f0100f12:	85 d2                	test   %edx,%edx
f0100f14:	0f 85 c8 fe ff ff    	jne    f0100de2 <check_page_free_list+0x10e>
f0100f1a:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100f1d:	85 f6                	test   %esi,%esi
f0100f1f:	7f 19                	jg     f0100f3a <check_page_free_list+0x266>
f0100f21:	68 76 4b 10 f0       	push   $0xf0104b76
f0100f26:	68 09 4b 10 f0       	push   $0xf0104b09
f0100f2b:	68 4d 02 00 00       	push   $0x24d
f0100f30:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0100f35:	e8 ac f1 ff ff       	call   f01000e6 <_panic>
	assert(nfree_extmem > 0);
f0100f3a:	85 db                	test   %ebx,%ebx
f0100f3c:	7f 19                	jg     f0100f57 <check_page_free_list+0x283>
f0100f3e:	68 88 4b 10 f0       	push   $0xf0104b88
f0100f43:	68 09 4b 10 f0       	push   $0xf0104b09
f0100f48:	68 4e 02 00 00       	push   $0x24e
f0100f4d:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0100f52:	e8 8f f1 ff ff       	call   f01000e6 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100f57:	83 ec 0c             	sub    $0xc,%esp
f0100f5a:	68 34 44 10 f0       	push   $0xf0104434
f0100f5f:	e8 90 1b 00 00       	call   f0102af4 <cprintf>
}
f0100f64:	eb 29                	jmp    f0100f8f <check_page_free_list+0x2bb>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100f66:	a1 3c 85 11 f0       	mov    0xf011853c,%eax
f0100f6b:	85 c0                	test   %eax,%eax
f0100f6d:	0f 85 8e fd ff ff    	jne    f0100d01 <check_page_free_list+0x2d>
f0100f73:	e9 72 fd ff ff       	jmp    f0100cea <check_page_free_list+0x16>
f0100f78:	83 3d 3c 85 11 f0 00 	cmpl   $0x0,0xf011853c
f0100f7f:	0f 84 65 fd ff ff    	je     f0100cea <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100f85:	be 00 04 00 00       	mov    $0x400,%esi
f0100f8a:	e9 c0 fd ff ff       	jmp    f0100d4f <check_page_free_list+0x7b>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100f8f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f92:	5b                   	pop    %ebx
f0100f93:	5e                   	pop    %esi
f0100f94:	5f                   	pop    %edi
f0100f95:	5d                   	pop    %ebp
f0100f96:	c3                   	ret    

f0100f97 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100f97:	55                   	push   %ebp
f0100f98:	89 e5                	mov    %esp,%ebp
f0100f9a:	56                   	push   %esi
f0100f9b:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;
f0100f9c:	a1 8c 89 11 f0       	mov    0xf011898c,%eax
f0100fa1:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	for (i = 1; i < npages_basemem; i++) {
f0100fa7:	8b 35 40 85 11 f0    	mov    0xf0118540,%esi
f0100fad:	8b 1d 3c 85 11 f0    	mov    0xf011853c,%ebx
f0100fb3:	ba 00 00 00 00       	mov    $0x0,%edx
f0100fb8:	b8 01 00 00 00       	mov    $0x1,%eax
f0100fbd:	eb 27                	jmp    f0100fe6 <page_init+0x4f>
		pages[i].pp_ref = 0;
f0100fbf:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100fc6:	89 d1                	mov    %edx,%ecx
f0100fc8:	03 0d 8c 89 11 f0    	add    0xf011898c,%ecx
f0100fce:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100fd4:	89 19                	mov    %ebx,(%ecx)
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;
	for (i = 1; i < npages_basemem; i++) {
f0100fd6:	83 c0 01             	add    $0x1,%eax
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100fd9:	89 d3                	mov    %edx,%ebx
f0100fdb:	03 1d 8c 89 11 f0    	add    0xf011898c,%ebx
f0100fe1:	ba 01 00 00 00       	mov    $0x1,%edx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;
	for (i = 1; i < npages_basemem; i++) {
f0100fe6:	39 f0                	cmp    %esi,%eax
f0100fe8:	72 d5                	jb     f0100fbf <page_init+0x28>
f0100fea:	84 d2                	test   %dl,%dl
f0100fec:	74 06                	je     f0100ff4 <page_init+0x5d>
f0100fee:	89 1d 3c 85 11 f0    	mov    %ebx,0xf011853c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
		for (i = IOPHYSMEM/PGSIZE; i < EXTPHYSMEM/PGSIZE; i++) {
		pages[i].pp_ref = 1;
f0100ff4:	8b 15 8c 89 11 f0    	mov    0xf011898c,%edx
f0100ffa:	8d 82 04 05 00 00    	lea    0x504(%edx),%eax
f0101000:	81 c2 04 08 00 00    	add    $0x804,%edx
f0101006:	66 c7 00 01 00       	movw   $0x1,(%eax)
f010100b:	83 c0 08             	add    $0x8,%eax
	for (i = 1; i < npages_basemem; i++) {
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
		for (i = IOPHYSMEM/PGSIZE; i < EXTPHYSMEM/PGSIZE; i++) {
f010100e:	39 d0                	cmp    %edx,%eax
f0101010:	75 f4                	jne    f0101006 <page_init+0x6f>
		pages[i].pp_ref = 1;
	}
	for(i=PADDR(boot_alloc(0))/PGSIZE;i<npages;i++){
f0101012:	b8 00 00 00 00       	mov    $0x0,%eax
f0101017:	e8 33 fc ff ff       	call   f0100c4f <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010101c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101021:	77 15                	ja     f0101038 <page_init+0xa1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101023:	50                   	push   %eax
f0101024:	68 4c 43 10 f0       	push   $0xf010434c
f0101029:	68 1a 01 00 00       	push   $0x11a
f010102e:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101033:	e8 ae f0 ff ff       	call   f01000e6 <_panic>
f0101038:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010103e:	c1 ea 0c             	shr    $0xc,%edx
f0101041:	8b 1d 3c 85 11 f0    	mov    0xf011853c,%ebx
f0101047:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
f010104e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101053:	eb 23                	jmp    f0101078 <page_init+0xe1>
		pages[i].pp_ref = 0;
f0101055:	89 c1                	mov    %eax,%ecx
f0101057:	03 0d 8c 89 11 f0    	add    0xf011898c,%ecx
f010105d:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0101063:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0101065:	89 c3                	mov    %eax,%ebx
f0101067:	03 1d 8c 89 11 f0    	add    0xf011898c,%ebx
		page_free_list = &pages[i];
	}
		for (i = IOPHYSMEM/PGSIZE; i < EXTPHYSMEM/PGSIZE; i++) {
		pages[i].pp_ref = 1;
	}
	for(i=PADDR(boot_alloc(0))/PGSIZE;i<npages;i++){
f010106d:	83 c2 01             	add    $0x1,%edx
f0101070:	83 c0 08             	add    $0x8,%eax
f0101073:	b9 01 00 00 00       	mov    $0x1,%ecx
f0101078:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f010107e:	72 d5                	jb     f0101055 <page_init+0xbe>
f0101080:	84 c9                	test   %cl,%cl
f0101082:	74 06                	je     f010108a <page_init+0xf3>
f0101084:	89 1d 3c 85 11 f0    	mov    %ebx,0xf011853c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f010108a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010108d:	5b                   	pop    %ebx
f010108e:	5e                   	pop    %esi
f010108f:	5d                   	pop    %ebp
f0101090:	c3                   	ret    

f0101091 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{	//cprintf("page_free_list is %x\n",page_free_list);
f0101091:	55                   	push   %ebp
f0101092:	89 e5                	mov    %esp,%ebp
f0101094:	53                   	push   %ebx
f0101095:	83 ec 04             	sub    $0x4,%esp
		//cprintf("    pfl is %x\n",page_free_list);
    if(page_free_list==NULL){return NULL;}
f0101098:	8b 1d 3c 85 11 f0    	mov    0xf011853c,%ebx
f010109e:	85 db                	test   %ebx,%ebx
f01010a0:	74 78                	je     f010111a <page_alloc+0x89>
	struct PageInfo * re=page_free_list;
	page_free_list=page_free_list->pp_link;
f01010a2:	8b 03                	mov    (%ebx),%eax
f01010a4:	a3 3c 85 11 f0       	mov    %eax,0xf011853c
	assert(re->pp_ref==0);
f01010a9:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01010ae:	74 19                	je     f01010c9 <page_alloc+0x38>
f01010b0:	68 99 4b 10 f0       	push   $0xf0104b99
f01010b5:	68 09 4b 10 f0       	push   $0xf0104b09
f01010ba:	68 34 01 00 00       	push   $0x134
f01010bf:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01010c4:	e8 1d f0 ff ff       	call   f01000e6 <_panic>
	re->pp_link=NULL;
f01010c9:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if(alloc_flags&ALLOC_ZERO){
f01010cf:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f01010d3:	74 45                	je     f010111a <page_alloc+0x89>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01010d5:	89 d8                	mov    %ebx,%eax
f01010d7:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f01010dd:	c1 f8 03             	sar    $0x3,%eax
f01010e0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010e3:	89 c2                	mov    %eax,%edx
f01010e5:	c1 ea 0c             	shr    $0xc,%edx
f01010e8:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f01010ee:	72 12                	jb     f0101102 <page_alloc+0x71>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010f0:	50                   	push   %eax
f01010f1:	68 28 43 10 f0       	push   $0xf0104328
f01010f6:	6a 54                	push   $0x54
f01010f8:	68 ef 4a 10 f0       	push   $0xf0104aef
f01010fd:	e8 e4 ef ff ff       	call   f01000e6 <_panic>
		memset(page2kva(re),0,PGSIZE);
f0101102:	83 ec 04             	sub    $0x4,%esp
f0101105:	68 00 10 00 00       	push   $0x1000
f010110a:	6a 00                	push   $0x0
f010110c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101111:	50                   	push   %eax
f0101112:	e8 88 26 00 00       	call   f010379f <memset>
f0101117:	83 c4 10             	add    $0x10,%esp
	}
	// Fill this function in
	return re;
}
f010111a:	89 d8                	mov    %ebx,%eax
f010111c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010111f:	c9                   	leave  
f0101120:	c3                   	ret    

f0101121 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0101121:	55                   	push   %ebp
f0101122:	89 e5                	mov    %esp,%ebp
f0101124:	83 ec 08             	sub    $0x8,%esp
f0101127:	8b 45 08             	mov    0x8(%ebp),%eax
	if (pp->pp_ref!=0||pp->pp_link !=NULL){panic("pp->pp_ref is nonzero or pp->pp_link is not NULL");}
f010112a:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010112f:	75 05                	jne    f0101136 <page_free+0x15>
f0101131:	83 38 00             	cmpl   $0x0,(%eax)
f0101134:	74 17                	je     f010114d <page_free+0x2c>
f0101136:	83 ec 04             	sub    $0x4,%esp
f0101139:	68 58 44 10 f0       	push   $0xf0104458
f010113e:	68 44 01 00 00       	push   $0x144
f0101143:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101148:	e8 99 ef ff ff       	call   f01000e6 <_panic>
		pp->pp_link = page_free_list;
f010114d:	8b 15 3c 85 11 f0    	mov    0xf011853c,%edx
f0101153:	89 10                	mov    %edx,(%eax)
		page_free_list = pp;
f0101155:	a3 3c 85 11 f0       	mov    %eax,0xf011853c
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
}
f010115a:	c9                   	leave  
f010115b:	c3                   	ret    

f010115c <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f010115c:	55                   	push   %ebp
f010115d:	89 e5                	mov    %esp,%ebp
f010115f:	83 ec 08             	sub    $0x8,%esp
f0101162:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101165:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101169:	83 e8 01             	sub    $0x1,%eax
f010116c:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101170:	66 85 c0             	test   %ax,%ax
f0101173:	75 0c                	jne    f0101181 <page_decref+0x25>
		page_free(pp);
f0101175:	83 ec 0c             	sub    $0xc,%esp
f0101178:	52                   	push   %edx
f0101179:	e8 a3 ff ff ff       	call   f0101121 <page_free>
f010117e:	83 c4 10             	add    $0x10,%esp
}
f0101181:	c9                   	leave  
f0101182:	c3                   	ret    

f0101183 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101183:	55                   	push   %ebp
f0101184:	89 e5                	mov    %esp,%ebp
f0101186:	56                   	push   %esi
f0101187:	53                   	push   %ebx
f0101188:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t * page_table=NULL;
	physaddr_t page_table_pa;
	page_table_pa=pgdir[PDX(va)];
f010118b:	89 de                	mov    %ebx,%esi
f010118d:	c1 ee 16             	shr    $0x16,%esi
f0101190:	c1 e6 02             	shl    $0x2,%esi
f0101193:	03 75 08             	add    0x8(%ebp),%esi
f0101196:	8b 06                	mov    (%esi),%eax
	if((int)page_table_pa!=0){
f0101198:	85 c0                	test   %eax,%eax
f010119a:	74 2e                	je     f01011ca <pgdir_walk+0x47>
	    page_table=(pte_t *)KADDR(PTE_ADDR(page_table_pa));
f010119c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01011a1:	89 c2                	mov    %eax,%edx
f01011a3:	c1 ea 0c             	shr    $0xc,%edx
f01011a6:	39 15 84 89 11 f0    	cmp    %edx,0xf0118984
f01011ac:	77 15                	ja     f01011c3 <pgdir_walk+0x40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01011ae:	50                   	push   %eax
f01011af:	68 28 43 10 f0       	push   $0xf0104328
f01011b4:	68 74 01 00 00       	push   $0x174
f01011b9:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01011be:	e8 23 ef ff ff       	call   f01000e6 <_panic>
	return (void *)(pa + KERNBASE);
f01011c3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01011c8:	eb 5d                	jmp    f0101227 <pgdir_walk+0xa4>
	}
	else{
		if(create==false){
f01011ca:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01011ce:	74 64                	je     f0101234 <pgdir_walk+0xb1>
			return NULL;
		}
		//allocate a new physical page for page table storage
		
		struct PageInfo * new_page=page_alloc(ALLOC_ZERO);
f01011d0:	83 ec 0c             	sub    $0xc,%esp
f01011d3:	6a 01                	push   $0x1
f01011d5:	e8 b7 fe ff ff       	call   f0101091 <page_alloc>
		if(new_page==NULL){return NULL;}
f01011da:	83 c4 10             	add    $0x10,%esp
f01011dd:	85 c0                	test   %eax,%eax
f01011df:	74 5a                	je     f010123b <pgdir_walk+0xb8>
		new_page->pp_ref++;
f01011e1:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01011e6:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f01011ec:	89 c2                	mov    %eax,%edx
f01011ee:	c1 fa 03             	sar    $0x3,%edx
f01011f1:	c1 e2 0c             	shl    $0xc,%edx
		page_table_pa=page2pa(new_page);
		page_table=(pte_t *)KADDR(PTE_ADDR(page_table_pa));
f01011f4:	89 d0                	mov    %edx,%eax
f01011f6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01011fb:	89 c1                	mov    %eax,%ecx
f01011fd:	c1 e9 0c             	shr    $0xc,%ecx
f0101200:	3b 0d 84 89 11 f0    	cmp    0xf0118984,%ecx
f0101206:	72 15                	jb     f010121d <pgdir_walk+0x9a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101208:	50                   	push   %eax
f0101209:	68 28 43 10 f0       	push   $0xf0104328
f010120e:	68 80 01 00 00       	push   $0x180
f0101213:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101218:	e8 c9 ee ff ff       	call   f01000e6 <_panic>
	return (void *)(pa + KERNBASE);
f010121d:	2d 00 00 00 10       	sub    $0x10000000,%eax
		pgdir[PDX(va)]=(pde_t)page_table_pa|PTE_P;
f0101222:	83 ca 01             	or     $0x1,%edx
f0101225:	89 16                	mov    %edx,(%esi)
	}
	return page_table+PTX(va);
f0101227:	c1 eb 0a             	shr    $0xa,%ebx
f010122a:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0101230:	01 d8                	add    %ebx,%eax
f0101232:	eb 0c                	jmp    f0101240 <pgdir_walk+0xbd>
	if((int)page_table_pa!=0){
	    page_table=(pte_t *)KADDR(PTE_ADDR(page_table_pa));
	}
	else{
		if(create==false){
			return NULL;
f0101234:	b8 00 00 00 00       	mov    $0x0,%eax
f0101239:	eb 05                	jmp    f0101240 <pgdir_walk+0xbd>
		}
		//allocate a new physical page for page table storage
		
		struct PageInfo * new_page=page_alloc(ALLOC_ZERO);
		if(new_page==NULL){return NULL;}
f010123b:	b8 00 00 00 00       	mov    $0x0,%eax
		page_table=(pte_t *)KADDR(PTE_ADDR(page_table_pa));
		pgdir[PDX(va)]=(pde_t)page_table_pa|PTE_P;
	}
	return page_table+PTX(va);
	// Fill this function in
}
f0101240:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101243:	5b                   	pop    %ebx
f0101244:	5e                   	pop    %esi
f0101245:	5d                   	pop    %ebp
f0101246:	c3                   	ret    

f0101247 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101247:	55                   	push   %ebp
f0101248:	89 e5                	mov    %esp,%ebp
f010124a:	57                   	push   %edi
f010124b:	56                   	push   %esi
f010124c:	53                   	push   %ebx
f010124d:	83 ec 1c             	sub    $0x1c,%esp
f0101250:	89 c7                	mov    %eax,%edi
	int PG_nums=size/PGSIZE;
f0101252:	c1 e9 0c             	shr    $0xc,%ecx
f0101255:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	pte_t* pte_p;
	for(int i =0;i<PG_nums;i++){
f0101258:	89 d3                	mov    %edx,%ebx
f010125a:	be 00 00 00 00       	mov    $0x0,%esi
		uintptr_t va_offset=va+i*PGSIZE;
		pte_p=pgdir_walk(pgdir,(void*)va_offset,true);
		*pte_p=(pa+i*PGSIZE)|perm|PTE_P;
f010125f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101262:	29 d0                	sub    %edx,%eax
f0101264:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101267:	8b 45 0c             	mov    0xc(%ebp),%eax
f010126a:	83 c8 01             	or     $0x1,%eax
f010126d:	89 45 dc             	mov    %eax,-0x24(%ebp)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int PG_nums=size/PGSIZE;
	pte_t* pte_p;
	for(int i =0;i<PG_nums;i++){
f0101270:	eb 5f                	jmp    f01012d1 <boot_map_region+0x8a>
		uintptr_t va_offset=va+i*PGSIZE;
		pte_p=pgdir_walk(pgdir,(void*)va_offset,true);
f0101272:	83 ec 04             	sub    $0x4,%esp
f0101275:	6a 01                	push   $0x1
f0101277:	53                   	push   %ebx
f0101278:	57                   	push   %edi
f0101279:	e8 05 ff ff ff       	call   f0101183 <pgdir_walk>
		*pte_p=(pa+i*PGSIZE)|perm|PTE_P;
f010127e:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101281:	8d 14 19             	lea    (%ecx,%ebx,1),%edx
f0101284:	0b 55 dc             	or     -0x24(%ebp),%edx
f0101287:	89 10                	mov    %edx,(%eax)
		pgdir[PDX(va_offset)]=(PADDR(pte_p)-PTX(va_offset))|perm;
f0101289:	89 da                	mov    %ebx,%edx
f010128b:	c1 ea 16             	shr    $0x16,%edx
f010128e:	8d 0c 97             	lea    (%edi,%edx,4),%ecx
f0101291:	8d 93 00 10 00 00    	lea    0x1000(%ebx),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101297:	83 c4 10             	add    $0x10,%esp
f010129a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010129f:	77 15                	ja     f01012b6 <boot_map_region+0x6f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01012a1:	50                   	push   %eax
f01012a2:	68 4c 43 10 f0       	push   $0xf010434c
f01012a7:	68 9b 01 00 00       	push   $0x19b
f01012ac:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01012b1:	e8 30 ee ff ff       	call   f01000e6 <_panic>
f01012b6:	c1 eb 0c             	shr    $0xc,%ebx
f01012b9:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f01012bf:	29 d8                	sub    %ebx,%eax
f01012c1:	8d 80 00 00 00 10    	lea    0x10000000(%eax),%eax
f01012c7:	0b 45 0c             	or     0xc(%ebp),%eax
f01012ca:	89 01                	mov    %eax,(%ecx)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int PG_nums=size/PGSIZE;
	pte_t* pte_p;
	for(int i =0;i<PG_nums;i++){
f01012cc:	83 c6 01             	add    $0x1,%esi
f01012cf:	89 d3                	mov    %edx,%ebx
f01012d1:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f01012d4:	7c 9c                	jl     f0101272 <boot_map_region+0x2b>
		uintptr_t va_offset=va+i*PGSIZE;
		pte_p=pgdir_walk(pgdir,(void*)va_offset,true);
		*pte_p=(pa+i*PGSIZE)|perm|PTE_P;
		pgdir[PDX(va_offset)]=(PADDR(pte_p)-PTX(va_offset))|perm;
	}
}
f01012d6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012d9:	5b                   	pop    %ebx
f01012da:	5e                   	pop    %esi
f01012db:	5f                   	pop    %edi
f01012dc:	5d                   	pop    %ebp
f01012dd:	c3                   	ret    

f01012de <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01012de:	55                   	push   %ebp
f01012df:	89 e5                	mov    %esp,%ebp
f01012e1:	53                   	push   %ebx
f01012e2:	83 ec 08             	sub    $0x8,%esp
f01012e5:	8b 5d 10             	mov    0x10(%ebp),%ebx
		
	pte_t* page_table_entry=pgdir_walk(pgdir,va,true);
f01012e8:	6a 01                	push   $0x1
f01012ea:	ff 75 0c             	pushl  0xc(%ebp)
f01012ed:	ff 75 08             	pushl  0x8(%ebp)
f01012f0:	e8 8e fe ff ff       	call   f0101183 <pgdir_walk>

		if(page_table_entry==NULL){return NULL;}
f01012f5:	83 c4 10             	add    $0x10,%esp
f01012f8:	85 c0                	test   %eax,%eax
f01012fa:	74 54                	je     f0101350 <page_lookup+0x72>
		if(pte_store!=0){
f01012fc:	85 db                	test   %ebx,%ebx
f01012fe:	74 02                	je     f0101302 <page_lookup+0x24>
		*pte_store=page_table_entry;}
f0101300:	89 03                	mov    %eax,(%ebx)
		physaddr_t pa=*page_table_entry;
f0101302:	8b 00                	mov    (%eax),%eax
		//cprintf("%x\n",pa);
		if ((int)pa==0){return NULL;}
f0101304:	85 c0                	test   %eax,%eax
f0101306:	74 4f                	je     f0101357 <page_lookup+0x79>
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages){
f0101308:	89 c2                	mov    %eax,%edx
f010130a:	c1 ea 0c             	shr    $0xc,%edx
f010130d:	8b 0d 84 89 11 f0    	mov    0xf0118984,%ecx
f0101313:	39 ca                	cmp    %ecx,%edx
f0101315:	72 2f                	jb     f0101346 <page_lookup+0x68>
		cprintf("pa:%x,PGNUM(pa):%d,npages:%d",pa,PGNUM(pa),npages);
f0101317:	51                   	push   %ecx
f0101318:	52                   	push   %edx
f0101319:	50                   	push   %eax
f010131a:	68 a7 4b 10 f0       	push   $0xf0104ba7
f010131f:	e8 d0 17 00 00       	call   f0102af4 <cprintf>
		mon_backtrace(0,0,0);
f0101324:	83 c4 0c             	add    $0xc,%esp
f0101327:	6a 00                	push   $0x0
f0101329:	6a 00                	push   $0x0
f010132b:	6a 00                	push   $0x0
f010132d:	e8 0d f6 ff ff       	call   f010093f <mon_backtrace>
		panic("pa2page called with invalid pa");}
f0101332:	83 c4 0c             	add    $0xc,%esp
f0101335:	68 8c 44 10 f0       	push   $0xf010448c
f010133a:	6a 4d                	push   $0x4d
f010133c:	68 ef 4a 10 f0       	push   $0xf0104aef
f0101341:	e8 a0 ed ff ff       	call   f01000e6 <_panic>
	return &pages[PGNUM(pa)];
f0101346:	a1 8c 89 11 f0       	mov    0xf011898c,%eax
f010134b:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		return pa2page(pa);
f010134e:	eb 0c                	jmp    f010135c <page_lookup+0x7e>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
		
	pte_t* page_table_entry=pgdir_walk(pgdir,va,true);

		if(page_table_entry==NULL){return NULL;}
f0101350:	b8 00 00 00 00       	mov    $0x0,%eax
f0101355:	eb 05                	jmp    f010135c <page_lookup+0x7e>
		if(pte_store!=0){
		*pte_store=page_table_entry;}
		physaddr_t pa=*page_table_entry;
		//cprintf("%x\n",pa);
		if ((int)pa==0){return NULL;}
f0101357:	b8 00 00 00 00       	mov    $0x0,%eax
		return pa2page(pa);
	
	// Fill this function in
	return NULL;
}
f010135c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010135f:	c9                   	leave  
f0101360:	c3                   	ret    

f0101361 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101361:	55                   	push   %ebp
f0101362:	89 e5                	mov    %esp,%ebp
f0101364:	53                   	push   %ebx
f0101365:	83 ec 18             	sub    $0x18,%esp
f0101368:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t* page_table_entry;
	struct PageInfo* pp= page_lookup(pgdir,va,&page_table_entry);
f010136b:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010136e:	50                   	push   %eax
f010136f:	53                   	push   %ebx
f0101370:	ff 75 08             	pushl  0x8(%ebp)
f0101373:	e8 66 ff ff ff       	call   f01012de <page_lookup>
	if (pp==NULL){return ;}
f0101378:	83 c4 10             	add    $0x10,%esp
f010137b:	85 c0                	test   %eax,%eax
f010137d:	74 18                	je     f0101397 <page_remove+0x36>
	//((pte_t*)(pgdir[PDX(va)]))[PTX(va)]=0;
	*page_table_entry=0;
f010137f:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101382:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
	page_decref(pp);
f0101388:	83 ec 0c             	sub    $0xc,%esp
f010138b:	50                   	push   %eax
f010138c:	e8 cb fd ff ff       	call   f010115c <page_decref>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101391:	0f 01 3b             	invlpg (%ebx)
f0101394:	83 c4 10             	add    $0x10,%esp
	tlb_invalidate(pgdir,va);
	// Fill this function in
}
f0101397:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010139a:	c9                   	leave  
f010139b:	c3                   	ret    

f010139c <page_insert>:
// and page2pa.
//
// If the duplicate page is inserted, first the page will be freed to free list, so it must be handled
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010139c:	55                   	push   %ebp
f010139d:	89 e5                	mov    %esp,%ebp
f010139f:	57                   	push   %edi
f01013a0:	56                   	push   %esi
f01013a1:	53                   	push   %ebx
f01013a2:	83 ec 10             	sub    $0x10,%esp
f01013a5:	8b 75 08             	mov    0x8(%ebp),%esi
f01013a8:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t* page_table_entry=pgdir_walk(pgdir,va,true);
f01013ab:	6a 01                	push   $0x1
f01013ad:	53                   	push   %ebx
f01013ae:	56                   	push   %esi
f01013af:	e8 cf fd ff ff       	call   f0101183 <pgdir_walk>
	if(page_table_entry==NULL){return -E_NO_MEM;}
f01013b4:	83 c4 10             	add    $0x10,%esp
f01013b7:	85 c0                	test   %eax,%eax
f01013b9:	74 53                	je     f010140e <page_insert+0x72>
f01013bb:	89 c7                	mov    %eax,%edi
	pp->pp_ref++;
f01013bd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013c0:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	if(page_lookup(pgdir,va,0)!=NULL){
f01013c5:	83 ec 04             	sub    $0x4,%esp
f01013c8:	6a 00                	push   $0x0
f01013ca:	53                   	push   %ebx
f01013cb:	56                   	push   %esi
f01013cc:	e8 0d ff ff ff       	call   f01012de <page_lookup>
f01013d1:	83 c4 10             	add    $0x10,%esp
f01013d4:	85 c0                	test   %eax,%eax
f01013d6:	74 0d                	je     f01013e5 <page_insert+0x49>
		page_remove(pgdir,va);}
f01013d8:	83 ec 08             	sub    $0x8,%esp
f01013db:	53                   	push   %ebx
f01013dc:	56                   	push   %esi
f01013dd:	e8 7f ff ff ff       	call   f0101361 <page_remove>
f01013e2:	83 c4 10             	add    $0x10,%esp
	//cprintf("pp2_pplink is %x\n",pp->pp_link);
	// The address of pte returned is kernel address, however the address stored in pgdir is pa..
   	pgdir[PDX(va)]=pgdir[PDX(va)]|perm;
f01013e5:	c1 eb 16             	shr    $0x16,%ebx
f01013e8:	8b 45 14             	mov    0x14(%ebp),%eax
f01013eb:	09 04 9e             	or     %eax,(%esi,%ebx,4)
	
	//cprintf("%x is pgdir[PDX(va)] in page_insert, %x is the pte,%x is the PTX(va)\n",pgdir[PDX(va)],page_table_entry,PTX(va));
	*page_table_entry=page2pa(pp)|perm|PTE_P;
f01013ee:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013f1:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f01013f7:	c1 f8 03             	sar    $0x3,%eax
f01013fa:	c1 e0 0c             	shl    $0xc,%eax
f01013fd:	8b 55 14             	mov    0x14(%ebp),%edx
f0101400:	83 ca 01             	or     $0x1,%edx
f0101403:	09 d0                	or     %edx,%eax
f0101405:	89 07                	mov    %eax,(%edi)

	// Fill this function in
	return 0;
f0101407:	b8 00 00 00 00       	mov    $0x0,%eax
f010140c:	eb 05                	jmp    f0101413 <page_insert+0x77>
// If the duplicate page is inserted, first the page will be freed to free list, so it must be handled
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	pte_t* page_table_entry=pgdir_walk(pgdir,va,true);
	if(page_table_entry==NULL){return -E_NO_MEM;}
f010140e:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	//cprintf("%x is pgdir[PDX(va)] in page_insert, %x is the pte,%x is the PTX(va)\n",pgdir[PDX(va)],page_table_entry,PTX(va));
	*page_table_entry=page2pa(pp)|perm|PTE_P;

	// Fill this function in
	return 0;
}
f0101413:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101416:	5b                   	pop    %ebx
f0101417:	5e                   	pop    %esi
f0101418:	5f                   	pop    %edi
f0101419:	5d                   	pop    %ebp
f010141a:	c3                   	ret    

f010141b <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010141b:	55                   	push   %ebp
f010141c:	89 e5                	mov    %esp,%ebp
f010141e:	57                   	push   %edi
f010141f:	56                   	push   %esi
f0101420:	53                   	push   %ebx
f0101421:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0101424:	b8 15 00 00 00       	mov    $0x15,%eax
f0101429:	e8 94 f7 ff ff       	call   f0100bc2 <nvram_read>
f010142e:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101430:	b8 17 00 00 00       	mov    $0x17,%eax
f0101435:	e8 88 f7 ff ff       	call   f0100bc2 <nvram_read>
f010143a:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f010143c:	b8 34 00 00 00       	mov    $0x34,%eax
f0101441:	e8 7c f7 ff ff       	call   f0100bc2 <nvram_read>
f0101446:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0101449:	85 c0                	test   %eax,%eax
f010144b:	74 07                	je     f0101454 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f010144d:	05 00 40 00 00       	add    $0x4000,%eax
f0101452:	eb 0b                	jmp    f010145f <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0101454:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f010145a:	85 f6                	test   %esi,%esi
f010145c:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f010145f:	89 c2                	mov    %eax,%edx
f0101461:	c1 ea 02             	shr    $0x2,%edx
f0101464:	89 15 84 89 11 f0    	mov    %edx,0xf0118984
	npages_basemem = basemem / (PGSIZE / 1024);
f010146a:	89 da                	mov    %ebx,%edx
f010146c:	c1 ea 02             	shr    $0x2,%edx
f010146f:	89 15 40 85 11 f0    	mov    %edx,0xf0118540

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101475:	89 c2                	mov    %eax,%edx
f0101477:	29 da                	sub    %ebx,%edx
f0101479:	52                   	push   %edx
f010147a:	53                   	push   %ebx
f010147b:	50                   	push   %eax
f010147c:	68 ac 44 10 f0       	push   $0xf01044ac
f0101481:	e8 6e 16 00 00       	call   f0102af4 <cprintf>
	// Remove this line when you're ready to test this function.
	

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101486:	b8 00 10 00 00       	mov    $0x1000,%eax
f010148b:	e8 bf f7 ff ff       	call   f0100c4f <boot_alloc>
f0101490:	a3 88 89 11 f0       	mov    %eax,0xf0118988
	memset(kern_pgdir, 0, PGSIZE);
f0101495:	83 c4 0c             	add    $0xc,%esp
f0101498:	68 00 10 00 00       	push   $0x1000
f010149d:	6a 00                	push   $0x0
f010149f:	50                   	push   %eax
f01014a0:	e8 fa 22 00 00       	call   f010379f <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01014a5:	a1 88 89 11 f0       	mov    0xf0118988,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01014aa:	83 c4 10             	add    $0x10,%esp
f01014ad:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01014b2:	77 15                	ja     f01014c9 <mem_init+0xae>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01014b4:	50                   	push   %eax
f01014b5:	68 4c 43 10 f0       	push   $0xf010434c
f01014ba:	68 95 00 00 00       	push   $0x95
f01014bf:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01014c4:	e8 1d ec ff ff       	call   f01000e6 <_panic>
f01014c9:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01014cf:	83 ca 05             	or     $0x5,%edx
f01014d2:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages=(struct PageInfo *)boot_alloc(npages*sizeof(struct PageInfo));
f01014d8:	a1 84 89 11 f0       	mov    0xf0118984,%eax
f01014dd:	c1 e0 03             	shl    $0x3,%eax
f01014e0:	e8 6a f7 ff ff       	call   f0100c4f <boot_alloc>
f01014e5:	a3 8c 89 11 f0       	mov    %eax,0xf011898c
	memset(pages,0,npages*sizeof(struct PageInfo));
f01014ea:	83 ec 04             	sub    $0x4,%esp
f01014ed:	8b 0d 84 89 11 f0    	mov    0xf0118984,%ecx
f01014f3:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01014fa:	52                   	push   %edx
f01014fb:	6a 00                	push   $0x0
f01014fd:	50                   	push   %eax
f01014fe:	e8 9c 22 00 00       	call   f010379f <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101503:	e8 8f fa ff ff       	call   f0100f97 <page_init>

	check_page_free_list(1);
f0101508:	b8 01 00 00 00       	mov    $0x1,%eax
f010150d:	e8 c2 f7 ff ff       	call   f0100cd4 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101512:	83 c4 10             	add    $0x10,%esp
f0101515:	83 3d 8c 89 11 f0 00 	cmpl   $0x0,0xf011898c
f010151c:	75 17                	jne    f0101535 <mem_init+0x11a>
		panic("'pages' is a null pointer!");
f010151e:	83 ec 04             	sub    $0x4,%esp
f0101521:	68 c4 4b 10 f0       	push   $0xf0104bc4
f0101526:	68 61 02 00 00       	push   $0x261
f010152b:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101530:	e8 b1 eb ff ff       	call   f01000e6 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101535:	a1 3c 85 11 f0       	mov    0xf011853c,%eax
f010153a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010153f:	eb 05                	jmp    f0101546 <mem_init+0x12b>
		++nfree;
f0101541:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101544:	8b 00                	mov    (%eax),%eax
f0101546:	85 c0                	test   %eax,%eax
f0101548:	75 f7                	jne    f0101541 <mem_init+0x126>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010154a:	83 ec 0c             	sub    $0xc,%esp
f010154d:	6a 00                	push   $0x0
f010154f:	e8 3d fb ff ff       	call   f0101091 <page_alloc>
f0101554:	89 c7                	mov    %eax,%edi
f0101556:	83 c4 10             	add    $0x10,%esp
f0101559:	85 c0                	test   %eax,%eax
f010155b:	75 19                	jne    f0101576 <mem_init+0x15b>
f010155d:	68 df 4b 10 f0       	push   $0xf0104bdf
f0101562:	68 09 4b 10 f0       	push   $0xf0104b09
f0101567:	68 69 02 00 00       	push   $0x269
f010156c:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101571:	e8 70 eb ff ff       	call   f01000e6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101576:	83 ec 0c             	sub    $0xc,%esp
f0101579:	6a 00                	push   $0x0
f010157b:	e8 11 fb ff ff       	call   f0101091 <page_alloc>
f0101580:	89 c6                	mov    %eax,%esi
f0101582:	83 c4 10             	add    $0x10,%esp
f0101585:	85 c0                	test   %eax,%eax
f0101587:	75 19                	jne    f01015a2 <mem_init+0x187>
f0101589:	68 f5 4b 10 f0       	push   $0xf0104bf5
f010158e:	68 09 4b 10 f0       	push   $0xf0104b09
f0101593:	68 6a 02 00 00       	push   $0x26a
f0101598:	68 d4 4a 10 f0       	push   $0xf0104ad4
f010159d:	e8 44 eb ff ff       	call   f01000e6 <_panic>
	assert((pp2 = page_alloc(0)));
f01015a2:	83 ec 0c             	sub    $0xc,%esp
f01015a5:	6a 00                	push   $0x0
f01015a7:	e8 e5 fa ff ff       	call   f0101091 <page_alloc>
f01015ac:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015af:	83 c4 10             	add    $0x10,%esp
f01015b2:	85 c0                	test   %eax,%eax
f01015b4:	75 19                	jne    f01015cf <mem_init+0x1b4>
f01015b6:	68 0b 4c 10 f0       	push   $0xf0104c0b
f01015bb:	68 09 4b 10 f0       	push   $0xf0104b09
f01015c0:	68 6b 02 00 00       	push   $0x26b
f01015c5:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01015ca:	e8 17 eb ff ff       	call   f01000e6 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015cf:	39 f7                	cmp    %esi,%edi
f01015d1:	75 19                	jne    f01015ec <mem_init+0x1d1>
f01015d3:	68 21 4c 10 f0       	push   $0xf0104c21
f01015d8:	68 09 4b 10 f0       	push   $0xf0104b09
f01015dd:	68 6e 02 00 00       	push   $0x26e
f01015e2:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01015e7:	e8 fa ea ff ff       	call   f01000e6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015ec:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015ef:	39 c6                	cmp    %eax,%esi
f01015f1:	74 04                	je     f01015f7 <mem_init+0x1dc>
f01015f3:	39 c7                	cmp    %eax,%edi
f01015f5:	75 19                	jne    f0101610 <mem_init+0x1f5>
f01015f7:	68 e8 44 10 f0       	push   $0xf01044e8
f01015fc:	68 09 4b 10 f0       	push   $0xf0104b09
f0101601:	68 6f 02 00 00       	push   $0x26f
f0101606:	68 d4 4a 10 f0       	push   $0xf0104ad4
f010160b:	e8 d6 ea ff ff       	call   f01000e6 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101610:	8b 0d 8c 89 11 f0    	mov    0xf011898c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101616:	8b 15 84 89 11 f0    	mov    0xf0118984,%edx
f010161c:	c1 e2 0c             	shl    $0xc,%edx
f010161f:	89 f8                	mov    %edi,%eax
f0101621:	29 c8                	sub    %ecx,%eax
f0101623:	c1 f8 03             	sar    $0x3,%eax
f0101626:	c1 e0 0c             	shl    $0xc,%eax
f0101629:	39 d0                	cmp    %edx,%eax
f010162b:	72 19                	jb     f0101646 <mem_init+0x22b>
f010162d:	68 33 4c 10 f0       	push   $0xf0104c33
f0101632:	68 09 4b 10 f0       	push   $0xf0104b09
f0101637:	68 70 02 00 00       	push   $0x270
f010163c:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101641:	e8 a0 ea ff ff       	call   f01000e6 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101646:	89 f0                	mov    %esi,%eax
f0101648:	29 c8                	sub    %ecx,%eax
f010164a:	c1 f8 03             	sar    $0x3,%eax
f010164d:	c1 e0 0c             	shl    $0xc,%eax
f0101650:	39 c2                	cmp    %eax,%edx
f0101652:	77 19                	ja     f010166d <mem_init+0x252>
f0101654:	68 50 4c 10 f0       	push   $0xf0104c50
f0101659:	68 09 4b 10 f0       	push   $0xf0104b09
f010165e:	68 71 02 00 00       	push   $0x271
f0101663:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101668:	e8 79 ea ff ff       	call   f01000e6 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010166d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101670:	29 c8                	sub    %ecx,%eax
f0101672:	c1 f8 03             	sar    $0x3,%eax
f0101675:	c1 e0 0c             	shl    $0xc,%eax
f0101678:	39 c2                	cmp    %eax,%edx
f010167a:	77 19                	ja     f0101695 <mem_init+0x27a>
f010167c:	68 6d 4c 10 f0       	push   $0xf0104c6d
f0101681:	68 09 4b 10 f0       	push   $0xf0104b09
f0101686:	68 72 02 00 00       	push   $0x272
f010168b:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101690:	e8 51 ea ff ff       	call   f01000e6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101695:	a1 3c 85 11 f0       	mov    0xf011853c,%eax
f010169a:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010169d:	c7 05 3c 85 11 f0 00 	movl   $0x0,0xf011853c
f01016a4:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01016a7:	83 ec 0c             	sub    $0xc,%esp
f01016aa:	6a 00                	push   $0x0
f01016ac:	e8 e0 f9 ff ff       	call   f0101091 <page_alloc>
f01016b1:	83 c4 10             	add    $0x10,%esp
f01016b4:	85 c0                	test   %eax,%eax
f01016b6:	74 19                	je     f01016d1 <mem_init+0x2b6>
f01016b8:	68 8a 4c 10 f0       	push   $0xf0104c8a
f01016bd:	68 09 4b 10 f0       	push   $0xf0104b09
f01016c2:	68 79 02 00 00       	push   $0x279
f01016c7:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01016cc:	e8 15 ea ff ff       	call   f01000e6 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01016d1:	83 ec 0c             	sub    $0xc,%esp
f01016d4:	57                   	push   %edi
f01016d5:	e8 47 fa ff ff       	call   f0101121 <page_free>
	page_free(pp1);
f01016da:	89 34 24             	mov    %esi,(%esp)
f01016dd:	e8 3f fa ff ff       	call   f0101121 <page_free>
	page_free(pp2);
f01016e2:	83 c4 04             	add    $0x4,%esp
f01016e5:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016e8:	e8 34 fa ff ff       	call   f0101121 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01016ed:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016f4:	e8 98 f9 ff ff       	call   f0101091 <page_alloc>
f01016f9:	89 c6                	mov    %eax,%esi
f01016fb:	83 c4 10             	add    $0x10,%esp
f01016fe:	85 c0                	test   %eax,%eax
f0101700:	75 19                	jne    f010171b <mem_init+0x300>
f0101702:	68 df 4b 10 f0       	push   $0xf0104bdf
f0101707:	68 09 4b 10 f0       	push   $0xf0104b09
f010170c:	68 80 02 00 00       	push   $0x280
f0101711:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101716:	e8 cb e9 ff ff       	call   f01000e6 <_panic>
	assert((pp1 = page_alloc(0)));
f010171b:	83 ec 0c             	sub    $0xc,%esp
f010171e:	6a 00                	push   $0x0
f0101720:	e8 6c f9 ff ff       	call   f0101091 <page_alloc>
f0101725:	89 c7                	mov    %eax,%edi
f0101727:	83 c4 10             	add    $0x10,%esp
f010172a:	85 c0                	test   %eax,%eax
f010172c:	75 19                	jne    f0101747 <mem_init+0x32c>
f010172e:	68 f5 4b 10 f0       	push   $0xf0104bf5
f0101733:	68 09 4b 10 f0       	push   $0xf0104b09
f0101738:	68 81 02 00 00       	push   $0x281
f010173d:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101742:	e8 9f e9 ff ff       	call   f01000e6 <_panic>
	assert((pp2 = page_alloc(0)));
f0101747:	83 ec 0c             	sub    $0xc,%esp
f010174a:	6a 00                	push   $0x0
f010174c:	e8 40 f9 ff ff       	call   f0101091 <page_alloc>
f0101751:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101754:	83 c4 10             	add    $0x10,%esp
f0101757:	85 c0                	test   %eax,%eax
f0101759:	75 19                	jne    f0101774 <mem_init+0x359>
f010175b:	68 0b 4c 10 f0       	push   $0xf0104c0b
f0101760:	68 09 4b 10 f0       	push   $0xf0104b09
f0101765:	68 82 02 00 00       	push   $0x282
f010176a:	68 d4 4a 10 f0       	push   $0xf0104ad4
f010176f:	e8 72 e9 ff ff       	call   f01000e6 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101774:	39 fe                	cmp    %edi,%esi
f0101776:	75 19                	jne    f0101791 <mem_init+0x376>
f0101778:	68 21 4c 10 f0       	push   $0xf0104c21
f010177d:	68 09 4b 10 f0       	push   $0xf0104b09
f0101782:	68 84 02 00 00       	push   $0x284
f0101787:	68 d4 4a 10 f0       	push   $0xf0104ad4
f010178c:	e8 55 e9 ff ff       	call   f01000e6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101791:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101794:	39 c7                	cmp    %eax,%edi
f0101796:	74 04                	je     f010179c <mem_init+0x381>
f0101798:	39 c6                	cmp    %eax,%esi
f010179a:	75 19                	jne    f01017b5 <mem_init+0x39a>
f010179c:	68 e8 44 10 f0       	push   $0xf01044e8
f01017a1:	68 09 4b 10 f0       	push   $0xf0104b09
f01017a6:	68 85 02 00 00       	push   $0x285
f01017ab:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01017b0:	e8 31 e9 ff ff       	call   f01000e6 <_panic>
	assert(!page_alloc(0));
f01017b5:	83 ec 0c             	sub    $0xc,%esp
f01017b8:	6a 00                	push   $0x0
f01017ba:	e8 d2 f8 ff ff       	call   f0101091 <page_alloc>
f01017bf:	83 c4 10             	add    $0x10,%esp
f01017c2:	85 c0                	test   %eax,%eax
f01017c4:	74 19                	je     f01017df <mem_init+0x3c4>
f01017c6:	68 8a 4c 10 f0       	push   $0xf0104c8a
f01017cb:	68 09 4b 10 f0       	push   $0xf0104b09
f01017d0:	68 86 02 00 00       	push   $0x286
f01017d5:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01017da:	e8 07 e9 ff ff       	call   f01000e6 <_panic>
f01017df:	89 f0                	mov    %esi,%eax
f01017e1:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f01017e7:	c1 f8 03             	sar    $0x3,%eax
f01017ea:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01017ed:	89 c2                	mov    %eax,%edx
f01017ef:	c1 ea 0c             	shr    $0xc,%edx
f01017f2:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f01017f8:	72 12                	jb     f010180c <mem_init+0x3f1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01017fa:	50                   	push   %eax
f01017fb:	68 28 43 10 f0       	push   $0xf0104328
f0101800:	6a 54                	push   $0x54
f0101802:	68 ef 4a 10 f0       	push   $0xf0104aef
f0101807:	e8 da e8 ff ff       	call   f01000e6 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010180c:	83 ec 04             	sub    $0x4,%esp
f010180f:	68 00 10 00 00       	push   $0x1000
f0101814:	6a 01                	push   $0x1
f0101816:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010181b:	50                   	push   %eax
f010181c:	e8 7e 1f 00 00       	call   f010379f <memset>
	page_free(pp0);
f0101821:	89 34 24             	mov    %esi,(%esp)
f0101824:	e8 f8 f8 ff ff       	call   f0101121 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101829:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101830:	e8 5c f8 ff ff       	call   f0101091 <page_alloc>
f0101835:	83 c4 10             	add    $0x10,%esp
f0101838:	85 c0                	test   %eax,%eax
f010183a:	75 19                	jne    f0101855 <mem_init+0x43a>
f010183c:	68 99 4c 10 f0       	push   $0xf0104c99
f0101841:	68 09 4b 10 f0       	push   $0xf0104b09
f0101846:	68 8b 02 00 00       	push   $0x28b
f010184b:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101850:	e8 91 e8 ff ff       	call   f01000e6 <_panic>
	assert(pp && pp0 == pp);
f0101855:	39 c6                	cmp    %eax,%esi
f0101857:	74 19                	je     f0101872 <mem_init+0x457>
f0101859:	68 b7 4c 10 f0       	push   $0xf0104cb7
f010185e:	68 09 4b 10 f0       	push   $0xf0104b09
f0101863:	68 8c 02 00 00       	push   $0x28c
f0101868:	68 d4 4a 10 f0       	push   $0xf0104ad4
f010186d:	e8 74 e8 ff ff       	call   f01000e6 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101872:	89 f0                	mov    %esi,%eax
f0101874:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f010187a:	c1 f8 03             	sar    $0x3,%eax
f010187d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101880:	89 c2                	mov    %eax,%edx
f0101882:	c1 ea 0c             	shr    $0xc,%edx
f0101885:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f010188b:	72 12                	jb     f010189f <mem_init+0x484>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010188d:	50                   	push   %eax
f010188e:	68 28 43 10 f0       	push   $0xf0104328
f0101893:	6a 54                	push   $0x54
f0101895:	68 ef 4a 10 f0       	push   $0xf0104aef
f010189a:	e8 47 e8 ff ff       	call   f01000e6 <_panic>
f010189f:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01018a5:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01018ab:	80 38 00             	cmpb   $0x0,(%eax)
f01018ae:	74 19                	je     f01018c9 <mem_init+0x4ae>
f01018b0:	68 c7 4c 10 f0       	push   $0xf0104cc7
f01018b5:	68 09 4b 10 f0       	push   $0xf0104b09
f01018ba:	68 8f 02 00 00       	push   $0x28f
f01018bf:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01018c4:	e8 1d e8 ff ff       	call   f01000e6 <_panic>
f01018c9:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01018cc:	39 d0                	cmp    %edx,%eax
f01018ce:	75 db                	jne    f01018ab <mem_init+0x490>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01018d0:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01018d3:	a3 3c 85 11 f0       	mov    %eax,0xf011853c

	// free the pages we took
	page_free(pp0);
f01018d8:	83 ec 0c             	sub    $0xc,%esp
f01018db:	56                   	push   %esi
f01018dc:	e8 40 f8 ff ff       	call   f0101121 <page_free>
	page_free(pp1);
f01018e1:	89 3c 24             	mov    %edi,(%esp)
f01018e4:	e8 38 f8 ff ff       	call   f0101121 <page_free>
	page_free(pp2);
f01018e9:	83 c4 04             	add    $0x4,%esp
f01018ec:	ff 75 d4             	pushl  -0x2c(%ebp)
f01018ef:	e8 2d f8 ff ff       	call   f0101121 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01018f4:	a1 3c 85 11 f0       	mov    0xf011853c,%eax
f01018f9:	83 c4 10             	add    $0x10,%esp
f01018fc:	eb 05                	jmp    f0101903 <mem_init+0x4e8>
		--nfree;
f01018fe:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101901:	8b 00                	mov    (%eax),%eax
f0101903:	85 c0                	test   %eax,%eax
f0101905:	75 f7                	jne    f01018fe <mem_init+0x4e3>
		--nfree;
	assert(nfree == 0);
f0101907:	85 db                	test   %ebx,%ebx
f0101909:	74 19                	je     f0101924 <mem_init+0x509>
f010190b:	68 d1 4c 10 f0       	push   $0xf0104cd1
f0101910:	68 09 4b 10 f0       	push   $0xf0104b09
f0101915:	68 9c 02 00 00       	push   $0x29c
f010191a:	68 d4 4a 10 f0       	push   $0xf0104ad4
f010191f:	e8 c2 e7 ff ff       	call   f01000e6 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101924:	83 ec 0c             	sub    $0xc,%esp
f0101927:	68 08 45 10 f0       	push   $0xf0104508
f010192c:	e8 c3 11 00 00       	call   f0102af4 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101931:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101938:	e8 54 f7 ff ff       	call   f0101091 <page_alloc>
f010193d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101940:	83 c4 10             	add    $0x10,%esp
f0101943:	85 c0                	test   %eax,%eax
f0101945:	75 19                	jne    f0101960 <mem_init+0x545>
f0101947:	68 df 4b 10 f0       	push   $0xf0104bdf
f010194c:	68 09 4b 10 f0       	push   $0xf0104b09
f0101951:	68 f6 02 00 00       	push   $0x2f6
f0101956:	68 d4 4a 10 f0       	push   $0xf0104ad4
f010195b:	e8 86 e7 ff ff       	call   f01000e6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101960:	83 ec 0c             	sub    $0xc,%esp
f0101963:	6a 00                	push   $0x0
f0101965:	e8 27 f7 ff ff       	call   f0101091 <page_alloc>
f010196a:	89 c3                	mov    %eax,%ebx
f010196c:	83 c4 10             	add    $0x10,%esp
f010196f:	85 c0                	test   %eax,%eax
f0101971:	75 19                	jne    f010198c <mem_init+0x571>
f0101973:	68 f5 4b 10 f0       	push   $0xf0104bf5
f0101978:	68 09 4b 10 f0       	push   $0xf0104b09
f010197d:	68 f7 02 00 00       	push   $0x2f7
f0101982:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101987:	e8 5a e7 ff ff       	call   f01000e6 <_panic>
	assert((pp2 = page_alloc(0)));
f010198c:	83 ec 0c             	sub    $0xc,%esp
f010198f:	6a 00                	push   $0x0
f0101991:	e8 fb f6 ff ff       	call   f0101091 <page_alloc>
f0101996:	89 c6                	mov    %eax,%esi
f0101998:	83 c4 10             	add    $0x10,%esp
f010199b:	85 c0                	test   %eax,%eax
f010199d:	75 19                	jne    f01019b8 <mem_init+0x59d>
f010199f:	68 0b 4c 10 f0       	push   $0xf0104c0b
f01019a4:	68 09 4b 10 f0       	push   $0xf0104b09
f01019a9:	68 f8 02 00 00       	push   $0x2f8
f01019ae:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01019b3:	e8 2e e7 ff ff       	call   f01000e6 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01019b8:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01019bb:	75 19                	jne    f01019d6 <mem_init+0x5bb>
f01019bd:	68 21 4c 10 f0       	push   $0xf0104c21
f01019c2:	68 09 4b 10 f0       	push   $0xf0104b09
f01019c7:	68 fb 02 00 00       	push   $0x2fb
f01019cc:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01019d1:	e8 10 e7 ff ff       	call   f01000e6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01019d6:	39 c3                	cmp    %eax,%ebx
f01019d8:	74 05                	je     f01019df <mem_init+0x5c4>
f01019da:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01019dd:	75 19                	jne    f01019f8 <mem_init+0x5dd>
f01019df:	68 e8 44 10 f0       	push   $0xf01044e8
f01019e4:	68 09 4b 10 f0       	push   $0xf0104b09
f01019e9:	68 fc 02 00 00       	push   $0x2fc
f01019ee:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01019f3:	e8 ee e6 ff ff       	call   f01000e6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01019f8:	a1 3c 85 11 f0       	mov    0xf011853c,%eax
f01019fd:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101a00:	c7 05 3c 85 11 f0 00 	movl   $0x0,0xf011853c
f0101a07:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101a0a:	83 ec 0c             	sub    $0xc,%esp
f0101a0d:	6a 00                	push   $0x0
f0101a0f:	e8 7d f6 ff ff       	call   f0101091 <page_alloc>
f0101a14:	83 c4 10             	add    $0x10,%esp
f0101a17:	85 c0                	test   %eax,%eax
f0101a19:	74 19                	je     f0101a34 <mem_init+0x619>
f0101a1b:	68 8a 4c 10 f0       	push   $0xf0104c8a
f0101a20:	68 09 4b 10 f0       	push   $0xf0104b09
f0101a25:	68 03 03 00 00       	push   $0x303
f0101a2a:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101a2f:	e8 b2 e6 ff ff       	call   f01000e6 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101a34:	83 ec 04             	sub    $0x4,%esp
f0101a37:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101a3a:	50                   	push   %eax
f0101a3b:	6a 00                	push   $0x0
f0101a3d:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0101a43:	e8 96 f8 ff ff       	call   f01012de <page_lookup>
f0101a48:	83 c4 10             	add    $0x10,%esp
f0101a4b:	85 c0                	test   %eax,%eax
f0101a4d:	74 19                	je     f0101a68 <mem_init+0x64d>
f0101a4f:	68 28 45 10 f0       	push   $0xf0104528
f0101a54:	68 09 4b 10 f0       	push   $0xf0104b09
f0101a59:	68 06 03 00 00       	push   $0x306
f0101a5e:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101a63:	e8 7e e6 ff ff       	call   f01000e6 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a68:	6a 02                	push   $0x2
f0101a6a:	6a 00                	push   $0x0
f0101a6c:	53                   	push   %ebx
f0101a6d:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0101a73:	e8 24 f9 ff ff       	call   f010139c <page_insert>
f0101a78:	83 c4 10             	add    $0x10,%esp
f0101a7b:	85 c0                	test   %eax,%eax
f0101a7d:	78 19                	js     f0101a98 <mem_init+0x67d>
f0101a7f:	68 60 45 10 f0       	push   $0xf0104560
f0101a84:	68 09 4b 10 f0       	push   $0xf0104b09
f0101a89:	68 09 03 00 00       	push   $0x309
f0101a8e:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101a93:	e8 4e e6 ff ff       	call   f01000e6 <_panic>
	
	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a98:	83 ec 0c             	sub    $0xc,%esp
f0101a9b:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101a9e:	e8 7e f6 ff ff       	call   f0101121 <page_free>
	//cprintf("pp0->pp_link is %x\n",pp0->pp_link);		
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101aa3:	6a 02                	push   $0x2
f0101aa5:	6a 00                	push   $0x0
f0101aa7:	53                   	push   %ebx
f0101aa8:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0101aae:	e8 e9 f8 ff ff       	call   f010139c <page_insert>
f0101ab3:	83 c4 20             	add    $0x20,%esp
f0101ab6:	85 c0                	test   %eax,%eax
f0101ab8:	74 19                	je     f0101ad3 <mem_init+0x6b8>
f0101aba:	68 90 45 10 f0       	push   $0xf0104590
f0101abf:	68 09 4b 10 f0       	push   $0xf0104b09
f0101ac4:	68 0e 03 00 00       	push   $0x30e
f0101ac9:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101ace:	e8 13 e6 ff ff       	call   f01000e6 <_panic>
	//cprintf("%x,%x\n",PTE_ADDR(kern_pgdir[0]),page2pa(pp0));
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101ad3:	8b 3d 88 89 11 f0    	mov    0xf0118988,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101ad9:	a1 8c 89 11 f0       	mov    0xf011898c,%eax
f0101ade:	89 c1                	mov    %eax,%ecx
f0101ae0:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101ae3:	8b 17                	mov    (%edi),%edx
f0101ae5:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101aeb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101aee:	29 c8                	sub    %ecx,%eax
f0101af0:	c1 f8 03             	sar    $0x3,%eax
f0101af3:	c1 e0 0c             	shl    $0xc,%eax
f0101af6:	39 c2                	cmp    %eax,%edx
f0101af8:	74 19                	je     f0101b13 <mem_init+0x6f8>
f0101afa:	68 c0 45 10 f0       	push   $0xf01045c0
f0101aff:	68 09 4b 10 f0       	push   $0xf0104b09
f0101b04:	68 10 03 00 00       	push   $0x310
f0101b09:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101b0e:	e8 d3 e5 ff ff       	call   f01000e6 <_panic>
	
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101b13:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b18:	89 f8                	mov    %edi,%eax
f0101b1a:	e8 cc f0 ff ff       	call   f0100beb <check_va2pa>
f0101b1f:	89 da                	mov    %ebx,%edx
f0101b21:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101b24:	c1 fa 03             	sar    $0x3,%edx
f0101b27:	c1 e2 0c             	shl    $0xc,%edx
f0101b2a:	39 d0                	cmp    %edx,%eax
f0101b2c:	74 19                	je     f0101b47 <mem_init+0x72c>
f0101b2e:	68 e8 45 10 f0       	push   $0xf01045e8
f0101b33:	68 09 4b 10 f0       	push   $0xf0104b09
f0101b38:	68 12 03 00 00       	push   $0x312
f0101b3d:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101b42:	e8 9f e5 ff ff       	call   f01000e6 <_panic>
	assert(pp1->pp_ref == 1);
f0101b47:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b4c:	74 19                	je     f0101b67 <mem_init+0x74c>
f0101b4e:	68 dc 4c 10 f0       	push   $0xf0104cdc
f0101b53:	68 09 4b 10 f0       	push   $0xf0104b09
f0101b58:	68 13 03 00 00       	push   $0x313
f0101b5d:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101b62:	e8 7f e5 ff ff       	call   f01000e6 <_panic>
	assert(pp0->pp_ref == 1);
f0101b67:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b6a:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b6f:	74 19                	je     f0101b8a <mem_init+0x76f>
f0101b71:	68 ed 4c 10 f0       	push   $0xf0104ced
f0101b76:	68 09 4b 10 f0       	push   $0xf0104b09
f0101b7b:	68 14 03 00 00       	push   $0x314
f0101b80:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101b85:	e8 5c e5 ff ff       	call   f01000e6 <_panic>
	
	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b8a:	6a 02                	push   $0x2
f0101b8c:	68 00 10 00 00       	push   $0x1000
f0101b91:	56                   	push   %esi
f0101b92:	57                   	push   %edi
f0101b93:	e8 04 f8 ff ff       	call   f010139c <page_insert>
f0101b98:	83 c4 10             	add    $0x10,%esp
f0101b9b:	85 c0                	test   %eax,%eax
f0101b9d:	74 19                	je     f0101bb8 <mem_init+0x79d>
f0101b9f:	68 18 46 10 f0       	push   $0xf0104618
f0101ba4:	68 09 4b 10 f0       	push   $0xf0104b09
f0101ba9:	68 17 03 00 00       	push   $0x317
f0101bae:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101bb3:	e8 2e e5 ff ff       	call   f01000e6 <_panic>
	
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bb8:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bbd:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0101bc2:	e8 24 f0 ff ff       	call   f0100beb <check_va2pa>
f0101bc7:	89 f2                	mov    %esi,%edx
f0101bc9:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f0101bcf:	c1 fa 03             	sar    $0x3,%edx
f0101bd2:	c1 e2 0c             	shl    $0xc,%edx
f0101bd5:	39 d0                	cmp    %edx,%eax
f0101bd7:	74 19                	je     f0101bf2 <mem_init+0x7d7>
f0101bd9:	68 54 46 10 f0       	push   $0xf0104654
f0101bde:	68 09 4b 10 f0       	push   $0xf0104b09
f0101be3:	68 19 03 00 00       	push   $0x319
f0101be8:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101bed:	e8 f4 e4 ff ff       	call   f01000e6 <_panic>
	assert(pp2->pp_ref == 1);
f0101bf2:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101bf7:	74 19                	je     f0101c12 <mem_init+0x7f7>
f0101bf9:	68 fe 4c 10 f0       	push   $0xf0104cfe
f0101bfe:	68 09 4b 10 f0       	push   $0xf0104b09
f0101c03:	68 1a 03 00 00       	push   $0x31a
f0101c08:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101c0d:	e8 d4 e4 ff ff       	call   f01000e6 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101c12:	83 ec 0c             	sub    $0xc,%esp
f0101c15:	6a 00                	push   $0x0
f0101c17:	e8 75 f4 ff ff       	call   f0101091 <page_alloc>
f0101c1c:	83 c4 10             	add    $0x10,%esp
f0101c1f:	85 c0                	test   %eax,%eax
f0101c21:	74 19                	je     f0101c3c <mem_init+0x821>
f0101c23:	68 8a 4c 10 f0       	push   $0xf0104c8a
f0101c28:	68 09 4b 10 f0       	push   $0xf0104b09
f0101c2d:	68 1d 03 00 00       	push   $0x31d
f0101c32:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101c37:	e8 aa e4 ff ff       	call   f01000e6 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	//cprintf("pfl is %x\n",page_free_list);
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c3c:	6a 02                	push   $0x2
f0101c3e:	68 00 10 00 00       	push   $0x1000
f0101c43:	56                   	push   %esi
f0101c44:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0101c4a:	e8 4d f7 ff ff       	call   f010139c <page_insert>
f0101c4f:	83 c4 10             	add    $0x10,%esp
f0101c52:	85 c0                	test   %eax,%eax
f0101c54:	74 19                	je     f0101c6f <mem_init+0x854>
f0101c56:	68 18 46 10 f0       	push   $0xf0104618
f0101c5b:	68 09 4b 10 f0       	push   $0xf0104b09
f0101c60:	68 21 03 00 00       	push   $0x321
f0101c65:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101c6a:	e8 77 e4 ff ff       	call   f01000e6 <_panic>
    
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c6f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c74:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0101c79:	e8 6d ef ff ff       	call   f0100beb <check_va2pa>
f0101c7e:	89 f2                	mov    %esi,%edx
f0101c80:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f0101c86:	c1 fa 03             	sar    $0x3,%edx
f0101c89:	c1 e2 0c             	shl    $0xc,%edx
f0101c8c:	39 d0                	cmp    %edx,%eax
f0101c8e:	74 19                	je     f0101ca9 <mem_init+0x88e>
f0101c90:	68 54 46 10 f0       	push   $0xf0104654
f0101c95:	68 09 4b 10 f0       	push   $0xf0104b09
f0101c9a:	68 23 03 00 00       	push   $0x323
f0101c9f:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101ca4:	e8 3d e4 ff ff       	call   f01000e6 <_panic>
	assert(pp2->pp_ref == 1);
f0101ca9:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101cae:	74 19                	je     f0101cc9 <mem_init+0x8ae>
f0101cb0:	68 fe 4c 10 f0       	push   $0xf0104cfe
f0101cb5:	68 09 4b 10 f0       	push   $0xf0104b09
f0101cba:	68 24 03 00 00       	push   $0x324
f0101cbf:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101cc4:	e8 1d e4 ff ff       	call   f01000e6 <_panic>
	
	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101cc9:	83 ec 0c             	sub    $0xc,%esp
f0101ccc:	6a 00                	push   $0x0
f0101cce:	e8 be f3 ff ff       	call   f0101091 <page_alloc>
f0101cd3:	83 c4 10             	add    $0x10,%esp
f0101cd6:	85 c0                	test   %eax,%eax
f0101cd8:	74 19                	je     f0101cf3 <mem_init+0x8d8>
f0101cda:	68 8a 4c 10 f0       	push   $0xf0104c8a
f0101cdf:	68 09 4b 10 f0       	push   $0xf0104b09
f0101ce4:	68 28 03 00 00       	push   $0x328
f0101ce9:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101cee:	e8 f3 e3 ff ff       	call   f01000e6 <_panic>
//cprintf("pfl is %x\n",page_free_list);
	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101cf3:	8b 15 88 89 11 f0    	mov    0xf0118988,%edx
f0101cf9:	8b 02                	mov    (%edx),%eax
f0101cfb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101d00:	89 c1                	mov    %eax,%ecx
f0101d02:	c1 e9 0c             	shr    $0xc,%ecx
f0101d05:	3b 0d 84 89 11 f0    	cmp    0xf0118984,%ecx
f0101d0b:	72 15                	jb     f0101d22 <mem_init+0x907>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d0d:	50                   	push   %eax
f0101d0e:	68 28 43 10 f0       	push   $0xf0104328
f0101d13:	68 2b 03 00 00       	push   $0x32b
f0101d18:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101d1d:	e8 c4 e3 ff ff       	call   f01000e6 <_panic>
f0101d22:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d27:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	//cprintf("%x,%x\n",pgdir_walk(kern_pgdir, (void*)PGSIZE, 0),ptep);
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d2a:	83 ec 04             	sub    $0x4,%esp
f0101d2d:	6a 00                	push   $0x0
f0101d2f:	68 00 10 00 00       	push   $0x1000
f0101d34:	52                   	push   %edx
f0101d35:	e8 49 f4 ff ff       	call   f0101183 <pgdir_walk>
f0101d3a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101d3d:	8d 51 04             	lea    0x4(%ecx),%edx
f0101d40:	83 c4 10             	add    $0x10,%esp
f0101d43:	39 d0                	cmp    %edx,%eax
f0101d45:	74 19                	je     f0101d60 <mem_init+0x945>
f0101d47:	68 84 46 10 f0       	push   $0xf0104684
f0101d4c:	68 09 4b 10 f0       	push   $0xf0104b09
f0101d51:	68 2d 03 00 00       	push   $0x32d
f0101d56:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101d5b:	e8 86 e3 ff ff       	call   f01000e6 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101d60:	6a 06                	push   $0x6
f0101d62:	68 00 10 00 00       	push   $0x1000
f0101d67:	56                   	push   %esi
f0101d68:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0101d6e:	e8 29 f6 ff ff       	call   f010139c <page_insert>
f0101d73:	83 c4 10             	add    $0x10,%esp
f0101d76:	85 c0                	test   %eax,%eax
f0101d78:	74 19                	je     f0101d93 <mem_init+0x978>
f0101d7a:	68 c4 46 10 f0       	push   $0xf01046c4
f0101d7f:	68 09 4b 10 f0       	push   $0xf0104b09
f0101d84:	68 30 03 00 00       	push   $0x330
f0101d89:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101d8e:	e8 53 e3 ff ff       	call   f01000e6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d93:	8b 3d 88 89 11 f0    	mov    0xf0118988,%edi
f0101d99:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d9e:	89 f8                	mov    %edi,%eax
f0101da0:	e8 46 ee ff ff       	call   f0100beb <check_va2pa>
f0101da5:	89 f2                	mov    %esi,%edx
f0101da7:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f0101dad:	c1 fa 03             	sar    $0x3,%edx
f0101db0:	c1 e2 0c             	shl    $0xc,%edx
f0101db3:	39 d0                	cmp    %edx,%eax
f0101db5:	74 19                	je     f0101dd0 <mem_init+0x9b5>
f0101db7:	68 54 46 10 f0       	push   $0xf0104654
f0101dbc:	68 09 4b 10 f0       	push   $0xf0104b09
f0101dc1:	68 31 03 00 00       	push   $0x331
f0101dc6:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101dcb:	e8 16 e3 ff ff       	call   f01000e6 <_panic>
	assert(pp2->pp_ref == 1);
f0101dd0:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101dd5:	74 19                	je     f0101df0 <mem_init+0x9d5>
f0101dd7:	68 fe 4c 10 f0       	push   $0xf0104cfe
f0101ddc:	68 09 4b 10 f0       	push   $0xf0104b09
f0101de1:	68 32 03 00 00       	push   $0x332
f0101de6:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101deb:	e8 f6 e2 ff ff       	call   f01000e6 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101df0:	83 ec 04             	sub    $0x4,%esp
f0101df3:	6a 00                	push   $0x0
f0101df5:	68 00 10 00 00       	push   $0x1000
f0101dfa:	57                   	push   %edi
f0101dfb:	e8 83 f3 ff ff       	call   f0101183 <pgdir_walk>
f0101e00:	83 c4 10             	add    $0x10,%esp
f0101e03:	f6 00 04             	testb  $0x4,(%eax)
f0101e06:	75 19                	jne    f0101e21 <mem_init+0xa06>
f0101e08:	68 04 47 10 f0       	push   $0xf0104704
f0101e0d:	68 09 4b 10 f0       	push   $0xf0104b09
f0101e12:	68 33 03 00 00       	push   $0x333
f0101e17:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101e1c:	e8 c5 e2 ff ff       	call   f01000e6 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101e21:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0101e26:	f6 00 04             	testb  $0x4,(%eax)
f0101e29:	75 19                	jne    f0101e44 <mem_init+0xa29>
f0101e2b:	68 0f 4d 10 f0       	push   $0xf0104d0f
f0101e30:	68 09 4b 10 f0       	push   $0xf0104b09
f0101e35:	68 34 03 00 00       	push   $0x334
f0101e3a:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101e3f:	e8 a2 e2 ff ff       	call   f01000e6 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e44:	6a 02                	push   $0x2
f0101e46:	68 00 10 00 00       	push   $0x1000
f0101e4b:	56                   	push   %esi
f0101e4c:	50                   	push   %eax
f0101e4d:	e8 4a f5 ff ff       	call   f010139c <page_insert>
f0101e52:	83 c4 10             	add    $0x10,%esp
f0101e55:	85 c0                	test   %eax,%eax
f0101e57:	74 19                	je     f0101e72 <mem_init+0xa57>
f0101e59:	68 18 46 10 f0       	push   $0xf0104618
f0101e5e:	68 09 4b 10 f0       	push   $0xf0104b09
f0101e63:	68 37 03 00 00       	push   $0x337
f0101e68:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101e6d:	e8 74 e2 ff ff       	call   f01000e6 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101e72:	83 ec 04             	sub    $0x4,%esp
f0101e75:	6a 00                	push   $0x0
f0101e77:	68 00 10 00 00       	push   $0x1000
f0101e7c:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0101e82:	e8 fc f2 ff ff       	call   f0101183 <pgdir_walk>
f0101e87:	83 c4 10             	add    $0x10,%esp
f0101e8a:	f6 00 02             	testb  $0x2,(%eax)
f0101e8d:	75 19                	jne    f0101ea8 <mem_init+0xa8d>
f0101e8f:	68 38 47 10 f0       	push   $0xf0104738
f0101e94:	68 09 4b 10 f0       	push   $0xf0104b09
f0101e99:	68 38 03 00 00       	push   $0x338
f0101e9e:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101ea3:	e8 3e e2 ff ff       	call   f01000e6 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ea8:	83 ec 04             	sub    $0x4,%esp
f0101eab:	6a 00                	push   $0x0
f0101ead:	68 00 10 00 00       	push   $0x1000
f0101eb2:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0101eb8:	e8 c6 f2 ff ff       	call   f0101183 <pgdir_walk>
f0101ebd:	83 c4 10             	add    $0x10,%esp
f0101ec0:	f6 00 04             	testb  $0x4,(%eax)
f0101ec3:	74 19                	je     f0101ede <mem_init+0xac3>
f0101ec5:	68 6c 47 10 f0       	push   $0xf010476c
f0101eca:	68 09 4b 10 f0       	push   $0xf0104b09
f0101ecf:	68 39 03 00 00       	push   $0x339
f0101ed4:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101ed9:	e8 08 e2 ff ff       	call   f01000e6 <_panic>
	
	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101ede:	6a 02                	push   $0x2
f0101ee0:	68 00 00 40 00       	push   $0x400000
f0101ee5:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101ee8:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0101eee:	e8 a9 f4 ff ff       	call   f010139c <page_insert>
f0101ef3:	83 c4 10             	add    $0x10,%esp
f0101ef6:	85 c0                	test   %eax,%eax
f0101ef8:	78 19                	js     f0101f13 <mem_init+0xaf8>
f0101efa:	68 a4 47 10 f0       	push   $0xf01047a4
f0101eff:	68 09 4b 10 f0       	push   $0xf0104b09
f0101f04:	68 3c 03 00 00       	push   $0x33c
f0101f09:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101f0e:	e8 d3 e1 ff ff       	call   f01000e6 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101f13:	6a 02                	push   $0x2
f0101f15:	68 00 10 00 00       	push   $0x1000
f0101f1a:	53                   	push   %ebx
f0101f1b:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0101f21:	e8 76 f4 ff ff       	call   f010139c <page_insert>
f0101f26:	83 c4 10             	add    $0x10,%esp
f0101f29:	85 c0                	test   %eax,%eax
f0101f2b:	74 19                	je     f0101f46 <mem_init+0xb2b>
f0101f2d:	68 dc 47 10 f0       	push   $0xf01047dc
f0101f32:	68 09 4b 10 f0       	push   $0xf0104b09
f0101f37:	68 3f 03 00 00       	push   $0x33f
f0101f3c:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101f41:	e8 a0 e1 ff ff       	call   f01000e6 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f46:	83 ec 04             	sub    $0x4,%esp
f0101f49:	6a 00                	push   $0x0
f0101f4b:	68 00 10 00 00       	push   $0x1000
f0101f50:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0101f56:	e8 28 f2 ff ff       	call   f0101183 <pgdir_walk>
f0101f5b:	83 c4 10             	add    $0x10,%esp
f0101f5e:	f6 00 04             	testb  $0x4,(%eax)
f0101f61:	74 19                	je     f0101f7c <mem_init+0xb61>
f0101f63:	68 6c 47 10 f0       	push   $0xf010476c
f0101f68:	68 09 4b 10 f0       	push   $0xf0104b09
f0101f6d:	68 40 03 00 00       	push   $0x340
f0101f72:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101f77:	e8 6a e1 ff ff       	call   f01000e6 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101f7c:	8b 3d 88 89 11 f0    	mov    0xf0118988,%edi
f0101f82:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f87:	89 f8                	mov    %edi,%eax
f0101f89:	e8 5d ec ff ff       	call   f0100beb <check_va2pa>
f0101f8e:	89 c1                	mov    %eax,%ecx
f0101f90:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f93:	89 d8                	mov    %ebx,%eax
f0101f95:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0101f9b:	c1 f8 03             	sar    $0x3,%eax
f0101f9e:	c1 e0 0c             	shl    $0xc,%eax
f0101fa1:	39 c1                	cmp    %eax,%ecx
f0101fa3:	74 19                	je     f0101fbe <mem_init+0xba3>
f0101fa5:	68 18 48 10 f0       	push   $0xf0104818
f0101faa:	68 09 4b 10 f0       	push   $0xf0104b09
f0101faf:	68 43 03 00 00       	push   $0x343
f0101fb4:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101fb9:	e8 28 e1 ff ff       	call   f01000e6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101fbe:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fc3:	89 f8                	mov    %edi,%eax
f0101fc5:	e8 21 ec ff ff       	call   f0100beb <check_va2pa>
f0101fca:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101fcd:	74 19                	je     f0101fe8 <mem_init+0xbcd>
f0101fcf:	68 44 48 10 f0       	push   $0xf0104844
f0101fd4:	68 09 4b 10 f0       	push   $0xf0104b09
f0101fd9:	68 44 03 00 00       	push   $0x344
f0101fde:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101fe3:	e8 fe e0 ff ff       	call   f01000e6 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101fe8:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101fed:	74 19                	je     f0102008 <mem_init+0xbed>
f0101fef:	68 25 4d 10 f0       	push   $0xf0104d25
f0101ff4:	68 09 4b 10 f0       	push   $0xf0104b09
f0101ff9:	68 46 03 00 00       	push   $0x346
f0101ffe:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0102003:	e8 de e0 ff ff       	call   f01000e6 <_panic>
	assert(pp2->pp_ref == 0);
f0102008:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010200d:	74 19                	je     f0102028 <mem_init+0xc0d>
f010200f:	68 36 4d 10 f0       	push   $0xf0104d36
f0102014:	68 09 4b 10 f0       	push   $0xf0104b09
f0102019:	68 47 03 00 00       	push   $0x347
f010201e:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0102023:	e8 be e0 ff ff       	call   f01000e6 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102028:	83 ec 0c             	sub    $0xc,%esp
f010202b:	6a 00                	push   $0x0
f010202d:	e8 5f f0 ff ff       	call   f0101091 <page_alloc>
f0102032:	83 c4 10             	add    $0x10,%esp
f0102035:	85 c0                	test   %eax,%eax
f0102037:	74 04                	je     f010203d <mem_init+0xc22>
f0102039:	39 c6                	cmp    %eax,%esi
f010203b:	74 19                	je     f0102056 <mem_init+0xc3b>
f010203d:	68 74 48 10 f0       	push   $0xf0104874
f0102042:	68 09 4b 10 f0       	push   $0xf0104b09
f0102047:	68 4a 03 00 00       	push   $0x34a
f010204c:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0102051:	e8 90 e0 ff ff       	call   f01000e6 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102056:	83 ec 08             	sub    $0x8,%esp
f0102059:	6a 00                	push   $0x0
f010205b:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0102061:	e8 fb f2 ff ff       	call   f0101361 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102066:	8b 3d 88 89 11 f0    	mov    0xf0118988,%edi
f010206c:	ba 00 00 00 00       	mov    $0x0,%edx
f0102071:	89 f8                	mov    %edi,%eax
f0102073:	e8 73 eb ff ff       	call   f0100beb <check_va2pa>
f0102078:	83 c4 10             	add    $0x10,%esp
f010207b:	83 f8 ff             	cmp    $0xffffffff,%eax
f010207e:	74 19                	je     f0102099 <mem_init+0xc7e>
f0102080:	68 98 48 10 f0       	push   $0xf0104898
f0102085:	68 09 4b 10 f0       	push   $0xf0104b09
f010208a:	68 4e 03 00 00       	push   $0x34e
f010208f:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0102094:	e8 4d e0 ff ff       	call   f01000e6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102099:	ba 00 10 00 00       	mov    $0x1000,%edx
f010209e:	89 f8                	mov    %edi,%eax
f01020a0:	e8 46 eb ff ff       	call   f0100beb <check_va2pa>
f01020a5:	89 da                	mov    %ebx,%edx
f01020a7:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f01020ad:	c1 fa 03             	sar    $0x3,%edx
f01020b0:	c1 e2 0c             	shl    $0xc,%edx
f01020b3:	39 d0                	cmp    %edx,%eax
f01020b5:	74 19                	je     f01020d0 <mem_init+0xcb5>
f01020b7:	68 44 48 10 f0       	push   $0xf0104844
f01020bc:	68 09 4b 10 f0       	push   $0xf0104b09
f01020c1:	68 4f 03 00 00       	push   $0x34f
f01020c6:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01020cb:	e8 16 e0 ff ff       	call   f01000e6 <_panic>
	assert(pp1->pp_ref == 1);
f01020d0:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01020d5:	74 19                	je     f01020f0 <mem_init+0xcd5>
f01020d7:	68 dc 4c 10 f0       	push   $0xf0104cdc
f01020dc:	68 09 4b 10 f0       	push   $0xf0104b09
f01020e1:	68 50 03 00 00       	push   $0x350
f01020e6:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01020eb:	e8 f6 df ff ff       	call   f01000e6 <_panic>
	assert(pp2->pp_ref == 0);
f01020f0:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01020f5:	74 19                	je     f0102110 <mem_init+0xcf5>
f01020f7:	68 36 4d 10 f0       	push   $0xf0104d36
f01020fc:	68 09 4b 10 f0       	push   $0xf0104b09
f0102101:	68 51 03 00 00       	push   $0x351
f0102106:	68 d4 4a 10 f0       	push   $0xf0104ad4
f010210b:	e8 d6 df ff ff       	call   f01000e6 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102110:	6a 00                	push   $0x0
f0102112:	68 00 10 00 00       	push   $0x1000
f0102117:	53                   	push   %ebx
f0102118:	57                   	push   %edi
f0102119:	e8 7e f2 ff ff       	call   f010139c <page_insert>
f010211e:	83 c4 10             	add    $0x10,%esp
f0102121:	85 c0                	test   %eax,%eax
f0102123:	74 19                	je     f010213e <mem_init+0xd23>
f0102125:	68 bc 48 10 f0       	push   $0xf01048bc
f010212a:	68 09 4b 10 f0       	push   $0xf0104b09
f010212f:	68 54 03 00 00       	push   $0x354
f0102134:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0102139:	e8 a8 df ff ff       	call   f01000e6 <_panic>
	assert(pp1->pp_ref);
f010213e:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102143:	75 19                	jne    f010215e <mem_init+0xd43>
f0102145:	68 47 4d 10 f0       	push   $0xf0104d47
f010214a:	68 09 4b 10 f0       	push   $0xf0104b09
f010214f:	68 55 03 00 00       	push   $0x355
f0102154:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0102159:	e8 88 df ff ff       	call   f01000e6 <_panic>
	assert(pp1->pp_link == NULL);
f010215e:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102161:	74 19                	je     f010217c <mem_init+0xd61>
f0102163:	68 53 4d 10 f0       	push   $0xf0104d53
f0102168:	68 09 4b 10 f0       	push   $0xf0104b09
f010216d:	68 56 03 00 00       	push   $0x356
f0102172:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0102177:	e8 6a df ff ff       	call   f01000e6 <_panic>

	// unmapping pp1 at PGSIZE should free it
		cprintf("at this step,\n");
f010217c:	83 ec 0c             	sub    $0xc,%esp
f010217f:	68 68 4d 10 f0       	push   $0xf0104d68
f0102184:	e8 6b 09 00 00       	call   f0102af4 <cprintf>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102189:	83 c4 08             	add    $0x8,%esp
f010218c:	68 00 10 00 00       	push   $0x1000
f0102191:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0102197:	e8 c5 f1 ff ff       	call   f0101361 <page_remove>

	//cprintf("%x\n",check_va2pa(kern_pgdir, PGSIZE));
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010219c:	8b 3d 88 89 11 f0    	mov    0xf0118988,%edi
f01021a2:	ba 00 00 00 00       	mov    $0x0,%edx
f01021a7:	89 f8                	mov    %edi,%eax
f01021a9:	e8 3d ea ff ff       	call   f0100beb <check_va2pa>
f01021ae:	83 c4 10             	add    $0x10,%esp
f01021b1:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021b4:	74 19                	je     f01021cf <mem_init+0xdb4>
f01021b6:	68 98 48 10 f0       	push   $0xf0104898
f01021bb:	68 09 4b 10 f0       	push   $0xf0104b09
f01021c0:	68 5d 03 00 00       	push   $0x35d
f01021c5:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01021ca:	e8 17 df ff ff       	call   f01000e6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01021cf:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021d4:	89 f8                	mov    %edi,%eax
f01021d6:	e8 10 ea ff ff       	call   f0100beb <check_va2pa>
f01021db:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021de:	74 19                	je     f01021f9 <mem_init+0xdde>
f01021e0:	68 f4 48 10 f0       	push   $0xf01048f4
f01021e5:	68 09 4b 10 f0       	push   $0xf0104b09
f01021ea:	68 5e 03 00 00       	push   $0x35e
f01021ef:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01021f4:	e8 ed de ff ff       	call   f01000e6 <_panic>
	assert(pp1->pp_ref == 0);
f01021f9:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01021fe:	74 19                	je     f0102219 <mem_init+0xdfe>
f0102200:	68 77 4d 10 f0       	push   $0xf0104d77
f0102205:	68 09 4b 10 f0       	push   $0xf0104b09
f010220a:	68 5f 03 00 00       	push   $0x35f
f010220f:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0102214:	e8 cd de ff ff       	call   f01000e6 <_panic>
	assert(pp2->pp_ref == 0);
f0102219:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010221e:	74 19                	je     f0102239 <mem_init+0xe1e>
f0102220:	68 36 4d 10 f0       	push   $0xf0104d36
f0102225:	68 09 4b 10 f0       	push   $0xf0104b09
f010222a:	68 60 03 00 00       	push   $0x360
f010222f:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0102234:	e8 ad de ff ff       	call   f01000e6 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102239:	83 ec 0c             	sub    $0xc,%esp
f010223c:	6a 00                	push   $0x0
f010223e:	e8 4e ee ff ff       	call   f0101091 <page_alloc>
f0102243:	83 c4 10             	add    $0x10,%esp
f0102246:	39 c3                	cmp    %eax,%ebx
f0102248:	75 04                	jne    f010224e <mem_init+0xe33>
f010224a:	85 c0                	test   %eax,%eax
f010224c:	75 19                	jne    f0102267 <mem_init+0xe4c>
f010224e:	68 1c 49 10 f0       	push   $0xf010491c
f0102253:	68 09 4b 10 f0       	push   $0xf0104b09
f0102258:	68 63 03 00 00       	push   $0x363
f010225d:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0102262:	e8 7f de ff ff       	call   f01000e6 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102267:	83 ec 0c             	sub    $0xc,%esp
f010226a:	6a 00                	push   $0x0
f010226c:	e8 20 ee ff ff       	call   f0101091 <page_alloc>
f0102271:	83 c4 10             	add    $0x10,%esp
f0102274:	85 c0                	test   %eax,%eax
f0102276:	74 19                	je     f0102291 <mem_init+0xe76>
f0102278:	68 8a 4c 10 f0       	push   $0xf0104c8a
f010227d:	68 09 4b 10 f0       	push   $0xf0104b09
f0102282:	68 66 03 00 00       	push   $0x366
f0102287:	68 d4 4a 10 f0       	push   $0xf0104ad4
f010228c:	e8 55 de ff ff       	call   f01000e6 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102291:	8b 0d 88 89 11 f0    	mov    0xf0118988,%ecx
f0102297:	8b 11                	mov    (%ecx),%edx
f0102299:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010229f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022a2:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f01022a8:	c1 f8 03             	sar    $0x3,%eax
f01022ab:	c1 e0 0c             	shl    $0xc,%eax
f01022ae:	39 c2                	cmp    %eax,%edx
f01022b0:	74 19                	je     f01022cb <mem_init+0xeb0>
f01022b2:	68 c0 45 10 f0       	push   $0xf01045c0
f01022b7:	68 09 4b 10 f0       	push   $0xf0104b09
f01022bc:	68 69 03 00 00       	push   $0x369
f01022c1:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01022c6:	e8 1b de ff ff       	call   f01000e6 <_panic>
	kern_pgdir[0] = 0;
f01022cb:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01022d1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022d4:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01022d9:	74 19                	je     f01022f4 <mem_init+0xed9>
f01022db:	68 ed 4c 10 f0       	push   $0xf0104ced
f01022e0:	68 09 4b 10 f0       	push   $0xf0104b09
f01022e5:	68 6b 03 00 00       	push   $0x36b
f01022ea:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01022ef:	e8 f2 dd ff ff       	call   f01000e6 <_panic>
	pp0->pp_ref = 0;
f01022f4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022f7:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01022fd:	83 ec 0c             	sub    $0xc,%esp
f0102300:	50                   	push   %eax
f0102301:	e8 1b ee ff ff       	call   f0101121 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102306:	83 c4 0c             	add    $0xc,%esp
f0102309:	6a 01                	push   $0x1
f010230b:	68 00 10 40 00       	push   $0x401000
f0102310:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0102316:	e8 68 ee ff ff       	call   f0101183 <pgdir_walk>
f010231b:	89 c7                	mov    %eax,%edi
f010231d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102320:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102325:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102328:	8b 40 04             	mov    0x4(%eax),%eax
f010232b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102330:	8b 0d 84 89 11 f0    	mov    0xf0118984,%ecx
f0102336:	89 c2                	mov    %eax,%edx
f0102338:	c1 ea 0c             	shr    $0xc,%edx
f010233b:	83 c4 10             	add    $0x10,%esp
f010233e:	39 ca                	cmp    %ecx,%edx
f0102340:	72 15                	jb     f0102357 <mem_init+0xf3c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102342:	50                   	push   %eax
f0102343:	68 28 43 10 f0       	push   $0xf0104328
f0102348:	68 72 03 00 00       	push   $0x372
f010234d:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0102352:	e8 8f dd ff ff       	call   f01000e6 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102357:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f010235c:	39 c7                	cmp    %eax,%edi
f010235e:	74 19                	je     f0102379 <mem_init+0xf5e>
f0102360:	68 88 4d 10 f0       	push   $0xf0104d88
f0102365:	68 09 4b 10 f0       	push   $0xf0104b09
f010236a:	68 73 03 00 00       	push   $0x373
f010236f:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0102374:	e8 6d dd ff ff       	call   f01000e6 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102379:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010237c:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0102383:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102386:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010238c:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0102392:	c1 f8 03             	sar    $0x3,%eax
f0102395:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102398:	89 c2                	mov    %eax,%edx
f010239a:	c1 ea 0c             	shr    $0xc,%edx
f010239d:	39 d1                	cmp    %edx,%ecx
f010239f:	77 12                	ja     f01023b3 <mem_init+0xf98>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01023a1:	50                   	push   %eax
f01023a2:	68 28 43 10 f0       	push   $0xf0104328
f01023a7:	6a 54                	push   $0x54
f01023a9:	68 ef 4a 10 f0       	push   $0xf0104aef
f01023ae:	e8 33 dd ff ff       	call   f01000e6 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01023b3:	83 ec 04             	sub    $0x4,%esp
f01023b6:	68 00 10 00 00       	push   $0x1000
f01023bb:	68 ff 00 00 00       	push   $0xff
f01023c0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01023c5:	50                   	push   %eax
f01023c6:	e8 d4 13 00 00       	call   f010379f <memset>
	page_free(pp0);
f01023cb:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01023ce:	89 3c 24             	mov    %edi,(%esp)
f01023d1:	e8 4b ed ff ff       	call   f0101121 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01023d6:	83 c4 0c             	add    $0xc,%esp
f01023d9:	6a 01                	push   $0x1
f01023db:	6a 00                	push   $0x0
f01023dd:	ff 35 88 89 11 f0    	pushl  0xf0118988
f01023e3:	e8 9b ed ff ff       	call   f0101183 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01023e8:	89 fa                	mov    %edi,%edx
f01023ea:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f01023f0:	c1 fa 03             	sar    $0x3,%edx
f01023f3:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01023f6:	89 d0                	mov    %edx,%eax
f01023f8:	c1 e8 0c             	shr    $0xc,%eax
f01023fb:	83 c4 10             	add    $0x10,%esp
f01023fe:	3b 05 84 89 11 f0    	cmp    0xf0118984,%eax
f0102404:	72 12                	jb     f0102418 <mem_init+0xffd>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102406:	52                   	push   %edx
f0102407:	68 28 43 10 f0       	push   $0xf0104328
f010240c:	6a 54                	push   $0x54
f010240e:	68 ef 4a 10 f0       	push   $0xf0104aef
f0102413:	e8 ce dc ff ff       	call   f01000e6 <_panic>
	return (void *)(pa + KERNBASE);
f0102418:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010241e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102421:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102427:	f6 00 01             	testb  $0x1,(%eax)
f010242a:	74 19                	je     f0102445 <mem_init+0x102a>
f010242c:	68 a0 4d 10 f0       	push   $0xf0104da0
f0102431:	68 09 4b 10 f0       	push   $0xf0104b09
f0102436:	68 7d 03 00 00       	push   $0x37d
f010243b:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0102440:	e8 a1 dc ff ff       	call   f01000e6 <_panic>
f0102445:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102448:	39 d0                	cmp    %edx,%eax
f010244a:	75 db                	jne    f0102427 <mem_init+0x100c>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010244c:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102451:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102457:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010245a:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102460:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102463:	89 0d 3c 85 11 f0    	mov    %ecx,0xf011853c

	// free the pages we took
	page_free(pp0);
f0102469:	83 ec 0c             	sub    $0xc,%esp
f010246c:	50                   	push   %eax
f010246d:	e8 af ec ff ff       	call   f0101121 <page_free>
	page_free(pp1);
f0102472:	89 1c 24             	mov    %ebx,(%esp)
f0102475:	e8 a7 ec ff ff       	call   f0101121 <page_free>
	page_free(pp2);
f010247a:	89 34 24             	mov    %esi,(%esp)
f010247d:	e8 9f ec ff ff       	call   f0101121 <page_free>

	cprintf("check_page() succeeded!\n");
f0102482:	c7 04 24 b7 4d 10 f0 	movl   $0xf0104db7,(%esp)
f0102489:	e8 66 06 00 00       	call   f0102af4 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	//page_insert(kern_pgdir,page_alloc(0),(void*)UPAGES,PTE_U | PTE_P);
	int size=ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010248e:	a1 84 89 11 f0       	mov    0xf0118984,%eax
f0102493:	8d 0c c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%ecx
f010249a:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	boot_map_region(kern_pgdir,UPAGES,size,PADDR(pages),PTE_U | PTE_P);
f01024a0:	a1 8c 89 11 f0       	mov    0xf011898c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01024a5:	83 c4 10             	add    $0x10,%esp
f01024a8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01024ad:	77 15                	ja     f01024c4 <mem_init+0x10a9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01024af:	50                   	push   %eax
f01024b0:	68 4c 43 10 f0       	push   $0xf010434c
f01024b5:	68 b8 00 00 00       	push   $0xb8
f01024ba:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01024bf:	e8 22 dc ff ff       	call   f01000e6 <_panic>
f01024c4:	83 ec 08             	sub    $0x8,%esp
f01024c7:	6a 05                	push   $0x5
f01024c9:	05 00 00 00 10       	add    $0x10000000,%eax
f01024ce:	50                   	push   %eax
f01024cf:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01024d4:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f01024d9:	e8 69 ed ff ff       	call   f0101247 <boot_map_region>
	kern_pgdir[PDX(UPAGES)]=kern_pgdir[PDX(UPAGES)]|PTE_P;
f01024de:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f01024e3:	83 88 f0 0e 00 00 01 	orl    $0x1,0xef0(%eax)
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01024ea:	83 c4 10             	add    $0x10,%esp
f01024ed:	ba 00 e0 10 f0       	mov    $0xf010e000,%edx
f01024f2:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01024f8:	77 15                	ja     f010250f <mem_init+0x10f4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01024fa:	52                   	push   %edx
f01024fb:	68 4c 43 10 f0       	push   $0xf010434c
f0102500:	68 c5 00 00 00       	push   $0xc5
f0102505:	68 d4 4a 10 f0       	push   $0xf0104ad4
f010250a:	e8 d7 db ff ff       	call   f01000e6 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_SYSCALL);
f010250f:	83 ec 08             	sub    $0x8,%esp
f0102512:	68 07 0e 00 00       	push   $0xe07
f0102517:	68 00 e0 10 00       	push   $0x10e000
f010251c:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102521:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102526:	e8 1c ed ff ff       	call   f0101247 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KERNBASE,(2^32) - KERNBASE,0,PTE_SYSCALL);
f010252b:	83 c4 08             	add    $0x8,%esp
f010252e:	68 07 0e 00 00       	push   $0xe07
f0102533:	6a 00                	push   $0x0
f0102535:	b9 22 00 00 10       	mov    $0x10000022,%ecx
f010253a:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010253f:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102544:	e8 fe ec ff ff       	call   f0101247 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102549:	8b 35 88 89 11 f0    	mov    0xf0118988,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010254f:	a1 84 89 11 f0       	mov    0xf0118984,%eax
f0102554:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102557:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010255e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102563:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102566:	8b 3d 8c 89 11 f0    	mov    0xf011898c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010256c:	89 7d d0             	mov    %edi,-0x30(%ebp)
f010256f:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102572:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102577:	eb 55                	jmp    f01025ce <mem_init+0x11b3>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102579:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f010257f:	89 f0                	mov    %esi,%eax
f0102581:	e8 65 e6 ff ff       	call   f0100beb <check_va2pa>
f0102586:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f010258d:	77 15                	ja     f01025a4 <mem_init+0x1189>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010258f:	57                   	push   %edi
f0102590:	68 4c 43 10 f0       	push   $0xf010434c
f0102595:	68 b4 02 00 00       	push   $0x2b4
f010259a:	68 d4 4a 10 f0       	push   $0xf0104ad4
f010259f:	e8 42 db ff ff       	call   f01000e6 <_panic>
f01025a4:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f01025ab:	39 c2                	cmp    %eax,%edx
f01025ad:	74 19                	je     f01025c8 <mem_init+0x11ad>
f01025af:	68 40 49 10 f0       	push   $0xf0104940
f01025b4:	68 09 4b 10 f0       	push   $0xf0104b09
f01025b9:	68 b4 02 00 00       	push   $0x2b4
f01025be:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01025c3:	e8 1e db ff ff       	call   f01000e6 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01025c8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01025ce:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01025d1:	77 a6                	ja     f0102579 <mem_init+0x115e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01025d3:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01025d6:	c1 e7 0c             	shl    $0xc,%edi
f01025d9:	bb 00 00 00 00       	mov    $0x0,%ebx
f01025de:	eb 30                	jmp    f0102610 <mem_init+0x11f5>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01025e0:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f01025e6:	89 f0                	mov    %esi,%eax
f01025e8:	e8 fe e5 ff ff       	call   f0100beb <check_va2pa>
f01025ed:	39 c3                	cmp    %eax,%ebx
f01025ef:	74 19                	je     f010260a <mem_init+0x11ef>
f01025f1:	68 74 49 10 f0       	push   $0xf0104974
f01025f6:	68 09 4b 10 f0       	push   $0xf0104b09
f01025fb:	68 b9 02 00 00       	push   $0x2b9
f0102600:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0102605:	e8 dc da ff ff       	call   f01000e6 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010260a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102610:	39 fb                	cmp    %edi,%ebx
f0102612:	72 cc                	jb     f01025e0 <mem_init+0x11c5>
f0102614:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102619:	89 da                	mov    %ebx,%edx
f010261b:	89 f0                	mov    %esi,%eax
f010261d:	e8 c9 e5 ff ff       	call   f0100beb <check_va2pa>
f0102622:	8d 93 00 60 11 10    	lea    0x10116000(%ebx),%edx
f0102628:	39 c2                	cmp    %eax,%edx
f010262a:	74 19                	je     f0102645 <mem_init+0x122a>
f010262c:	68 9c 49 10 f0       	push   $0xf010499c
f0102631:	68 09 4b 10 f0       	push   $0xf0104b09
f0102636:	68 bd 02 00 00       	push   $0x2bd
f010263b:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0102640:	e8 a1 da ff ff       	call   f01000e6 <_panic>
f0102645:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010264b:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102651:	75 c6                	jne    f0102619 <mem_init+0x11fe>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102653:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102658:	89 f0                	mov    %esi,%eax
f010265a:	e8 8c e5 ff ff       	call   f0100beb <check_va2pa>
f010265f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102662:	74 51                	je     f01026b5 <mem_init+0x129a>
f0102664:	68 e4 49 10 f0       	push   $0xf01049e4
f0102669:	68 09 4b 10 f0       	push   $0xf0104b09
f010266e:	68 be 02 00 00       	push   $0x2be
f0102673:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0102678:	e8 69 da ff ff       	call   f01000e6 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010267d:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102682:	72 36                	jb     f01026ba <mem_init+0x129f>
f0102684:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102689:	76 07                	jbe    f0102692 <mem_init+0x1277>
f010268b:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102690:	75 28                	jne    f01026ba <mem_init+0x129f>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102692:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102696:	0f 85 83 00 00 00    	jne    f010271f <mem_init+0x1304>
f010269c:	68 d0 4d 10 f0       	push   $0xf0104dd0
f01026a1:	68 09 4b 10 f0       	push   $0xf0104b09
f01026a6:	68 c6 02 00 00       	push   $0x2c6
f01026ab:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01026b0:	e8 31 da ff ff       	call   f01000e6 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01026b5:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01026ba:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01026bf:	76 3f                	jbe    f0102700 <mem_init+0x12e5>
				assert(pgdir[i] & PTE_P);
f01026c1:	8b 14 86             	mov    (%esi,%eax,4),%edx
f01026c4:	f6 c2 01             	test   $0x1,%dl
f01026c7:	75 19                	jne    f01026e2 <mem_init+0x12c7>
f01026c9:	68 d0 4d 10 f0       	push   $0xf0104dd0
f01026ce:	68 09 4b 10 f0       	push   $0xf0104b09
f01026d3:	68 ca 02 00 00       	push   $0x2ca
f01026d8:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01026dd:	e8 04 da ff ff       	call   f01000e6 <_panic>
				assert(pgdir[i] & PTE_W);
f01026e2:	f6 c2 02             	test   $0x2,%dl
f01026e5:	75 38                	jne    f010271f <mem_init+0x1304>
f01026e7:	68 e1 4d 10 f0       	push   $0xf0104de1
f01026ec:	68 09 4b 10 f0       	push   $0xf0104b09
f01026f1:	68 cb 02 00 00       	push   $0x2cb
f01026f6:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01026fb:	e8 e6 d9 ff ff       	call   f01000e6 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102700:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102704:	74 19                	je     f010271f <mem_init+0x1304>
f0102706:	68 f2 4d 10 f0       	push   $0xf0104df2
f010270b:	68 09 4b 10 f0       	push   $0xf0104b09
f0102710:	68 cd 02 00 00       	push   $0x2cd
f0102715:	68 d4 4a 10 f0       	push   $0xf0104ad4
f010271a:	e8 c7 d9 ff ff       	call   f01000e6 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f010271f:	83 c0 01             	add    $0x1,%eax
f0102722:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102727:	0f 86 50 ff ff ff    	jbe    f010267d <mem_init+0x1262>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f010272d:	83 ec 0c             	sub    $0xc,%esp
f0102730:	68 14 4a 10 f0       	push   $0xf0104a14
f0102735:	e8 ba 03 00 00       	call   f0102af4 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010273a:	a1 88 89 11 f0       	mov    0xf0118988,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010273f:	83 c4 10             	add    $0x10,%esp
f0102742:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102747:	77 15                	ja     f010275e <mem_init+0x1343>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102749:	50                   	push   %eax
f010274a:	68 4c 43 10 f0       	push   $0xf010434c
f010274f:	68 d9 00 00 00       	push   $0xd9
f0102754:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0102759:	e8 88 d9 ff ff       	call   f01000e6 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010275e:	05 00 00 00 10       	add    $0x10000000,%eax
f0102763:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102766:	b8 00 00 00 00       	mov    $0x0,%eax
f010276b:	e8 64 e5 ff ff       	call   f0100cd4 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102770:	0f 20 c0             	mov    %cr0,%eax
f0102773:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102776:	0d 23 00 05 80       	or     $0x80050023,%eax
f010277b:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010277e:	83 ec 0c             	sub    $0xc,%esp
f0102781:	6a 00                	push   $0x0
f0102783:	e8 09 e9 ff ff       	call   f0101091 <page_alloc>
f0102788:	89 c3                	mov    %eax,%ebx
f010278a:	83 c4 10             	add    $0x10,%esp
f010278d:	85 c0                	test   %eax,%eax
f010278f:	75 19                	jne    f01027aa <mem_init+0x138f>
f0102791:	68 df 4b 10 f0       	push   $0xf0104bdf
f0102796:	68 09 4b 10 f0       	push   $0xf0104b09
f010279b:	68 98 03 00 00       	push   $0x398
f01027a0:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01027a5:	e8 3c d9 ff ff       	call   f01000e6 <_panic>
	assert((pp1 = page_alloc(0)));
f01027aa:	83 ec 0c             	sub    $0xc,%esp
f01027ad:	6a 00                	push   $0x0
f01027af:	e8 dd e8 ff ff       	call   f0101091 <page_alloc>
f01027b4:	89 c7                	mov    %eax,%edi
f01027b6:	83 c4 10             	add    $0x10,%esp
f01027b9:	85 c0                	test   %eax,%eax
f01027bb:	75 19                	jne    f01027d6 <mem_init+0x13bb>
f01027bd:	68 f5 4b 10 f0       	push   $0xf0104bf5
f01027c2:	68 09 4b 10 f0       	push   $0xf0104b09
f01027c7:	68 99 03 00 00       	push   $0x399
f01027cc:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01027d1:	e8 10 d9 ff ff       	call   f01000e6 <_panic>
	assert((pp2 = page_alloc(0)));
f01027d6:	83 ec 0c             	sub    $0xc,%esp
f01027d9:	6a 00                	push   $0x0
f01027db:	e8 b1 e8 ff ff       	call   f0101091 <page_alloc>
f01027e0:	89 c6                	mov    %eax,%esi
f01027e2:	83 c4 10             	add    $0x10,%esp
f01027e5:	85 c0                	test   %eax,%eax
f01027e7:	75 19                	jne    f0102802 <mem_init+0x13e7>
f01027e9:	68 0b 4c 10 f0       	push   $0xf0104c0b
f01027ee:	68 09 4b 10 f0       	push   $0xf0104b09
f01027f3:	68 9a 03 00 00       	push   $0x39a
f01027f8:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01027fd:	e8 e4 d8 ff ff       	call   f01000e6 <_panic>
	page_free(pp0);
f0102802:	83 ec 0c             	sub    $0xc,%esp
f0102805:	53                   	push   %ebx
f0102806:	e8 16 e9 ff ff       	call   f0101121 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010280b:	89 f8                	mov    %edi,%eax
f010280d:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0102813:	c1 f8 03             	sar    $0x3,%eax
f0102816:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102819:	89 c2                	mov    %eax,%edx
f010281b:	c1 ea 0c             	shr    $0xc,%edx
f010281e:	83 c4 10             	add    $0x10,%esp
f0102821:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f0102827:	72 12                	jb     f010283b <mem_init+0x1420>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102829:	50                   	push   %eax
f010282a:	68 28 43 10 f0       	push   $0xf0104328
f010282f:	6a 54                	push   $0x54
f0102831:	68 ef 4a 10 f0       	push   $0xf0104aef
f0102836:	e8 ab d8 ff ff       	call   f01000e6 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f010283b:	83 ec 04             	sub    $0x4,%esp
f010283e:	68 00 10 00 00       	push   $0x1000
f0102843:	6a 01                	push   $0x1
f0102845:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010284a:	50                   	push   %eax
f010284b:	e8 4f 0f 00 00       	call   f010379f <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102850:	89 f0                	mov    %esi,%eax
f0102852:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0102858:	c1 f8 03             	sar    $0x3,%eax
f010285b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010285e:	89 c2                	mov    %eax,%edx
f0102860:	c1 ea 0c             	shr    $0xc,%edx
f0102863:	83 c4 10             	add    $0x10,%esp
f0102866:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f010286c:	72 12                	jb     f0102880 <mem_init+0x1465>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010286e:	50                   	push   %eax
f010286f:	68 28 43 10 f0       	push   $0xf0104328
f0102874:	6a 54                	push   $0x54
f0102876:	68 ef 4a 10 f0       	push   $0xf0104aef
f010287b:	e8 66 d8 ff ff       	call   f01000e6 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102880:	83 ec 04             	sub    $0x4,%esp
f0102883:	68 00 10 00 00       	push   $0x1000
f0102888:	6a 02                	push   $0x2
f010288a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010288f:	50                   	push   %eax
f0102890:	e8 0a 0f 00 00       	call   f010379f <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102895:	6a 02                	push   $0x2
f0102897:	68 00 10 00 00       	push   $0x1000
f010289c:	57                   	push   %edi
f010289d:	ff 35 88 89 11 f0    	pushl  0xf0118988
f01028a3:	e8 f4 ea ff ff       	call   f010139c <page_insert>
	assert(pp1->pp_ref == 1);
f01028a8:	83 c4 20             	add    $0x20,%esp
f01028ab:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01028b0:	74 19                	je     f01028cb <mem_init+0x14b0>
f01028b2:	68 dc 4c 10 f0       	push   $0xf0104cdc
f01028b7:	68 09 4b 10 f0       	push   $0xf0104b09
f01028bc:	68 9f 03 00 00       	push   $0x39f
f01028c1:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01028c6:	e8 1b d8 ff ff       	call   f01000e6 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01028cb:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01028d2:	01 01 01 
f01028d5:	74 19                	je     f01028f0 <mem_init+0x14d5>
f01028d7:	68 34 4a 10 f0       	push   $0xf0104a34
f01028dc:	68 09 4b 10 f0       	push   $0xf0104b09
f01028e1:	68 a0 03 00 00       	push   $0x3a0
f01028e6:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01028eb:	e8 f6 d7 ff ff       	call   f01000e6 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f01028f0:	6a 02                	push   $0x2
f01028f2:	68 00 10 00 00       	push   $0x1000
f01028f7:	56                   	push   %esi
f01028f8:	ff 35 88 89 11 f0    	pushl  0xf0118988
f01028fe:	e8 99 ea ff ff       	call   f010139c <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102903:	83 c4 10             	add    $0x10,%esp
f0102906:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010290d:	02 02 02 
f0102910:	74 19                	je     f010292b <mem_init+0x1510>
f0102912:	68 58 4a 10 f0       	push   $0xf0104a58
f0102917:	68 09 4b 10 f0       	push   $0xf0104b09
f010291c:	68 a2 03 00 00       	push   $0x3a2
f0102921:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0102926:	e8 bb d7 ff ff       	call   f01000e6 <_panic>
	assert(pp2->pp_ref == 1);
f010292b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102930:	74 19                	je     f010294b <mem_init+0x1530>
f0102932:	68 fe 4c 10 f0       	push   $0xf0104cfe
f0102937:	68 09 4b 10 f0       	push   $0xf0104b09
f010293c:	68 a3 03 00 00       	push   $0x3a3
f0102941:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0102946:	e8 9b d7 ff ff       	call   f01000e6 <_panic>
	assert(pp1->pp_ref == 0);
f010294b:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102950:	74 19                	je     f010296b <mem_init+0x1550>
f0102952:	68 77 4d 10 f0       	push   $0xf0104d77
f0102957:	68 09 4b 10 f0       	push   $0xf0104b09
f010295c:	68 a4 03 00 00       	push   $0x3a4
f0102961:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0102966:	e8 7b d7 ff ff       	call   f01000e6 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f010296b:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102972:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102975:	89 f0                	mov    %esi,%eax
f0102977:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f010297d:	c1 f8 03             	sar    $0x3,%eax
f0102980:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102983:	89 c2                	mov    %eax,%edx
f0102985:	c1 ea 0c             	shr    $0xc,%edx
f0102988:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f010298e:	72 12                	jb     f01029a2 <mem_init+0x1587>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102990:	50                   	push   %eax
f0102991:	68 28 43 10 f0       	push   $0xf0104328
f0102996:	6a 54                	push   $0x54
f0102998:	68 ef 4a 10 f0       	push   $0xf0104aef
f010299d:	e8 44 d7 ff ff       	call   f01000e6 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01029a2:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01029a9:	03 03 03 
f01029ac:	74 19                	je     f01029c7 <mem_init+0x15ac>
f01029ae:	68 7c 4a 10 f0       	push   $0xf0104a7c
f01029b3:	68 09 4b 10 f0       	push   $0xf0104b09
f01029b8:	68 a6 03 00 00       	push   $0x3a6
f01029bd:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01029c2:	e8 1f d7 ff ff       	call   f01000e6 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01029c7:	83 ec 08             	sub    $0x8,%esp
f01029ca:	68 00 10 00 00       	push   $0x1000
f01029cf:	ff 35 88 89 11 f0    	pushl  0xf0118988
f01029d5:	e8 87 e9 ff ff       	call   f0101361 <page_remove>
	assert(pp2->pp_ref == 0);
f01029da:	83 c4 10             	add    $0x10,%esp
f01029dd:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01029e2:	74 19                	je     f01029fd <mem_init+0x15e2>
f01029e4:	68 36 4d 10 f0       	push   $0xf0104d36
f01029e9:	68 09 4b 10 f0       	push   $0xf0104b09
f01029ee:	68 a8 03 00 00       	push   $0x3a8
f01029f3:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01029f8:	e8 e9 d6 ff ff       	call   f01000e6 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01029fd:	8b 0d 88 89 11 f0    	mov    0xf0118988,%ecx
f0102a03:	8b 11                	mov    (%ecx),%edx
f0102a05:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102a0b:	89 d8                	mov    %ebx,%eax
f0102a0d:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0102a13:	c1 f8 03             	sar    $0x3,%eax
f0102a16:	c1 e0 0c             	shl    $0xc,%eax
f0102a19:	39 c2                	cmp    %eax,%edx
f0102a1b:	74 19                	je     f0102a36 <mem_init+0x161b>
f0102a1d:	68 c0 45 10 f0       	push   $0xf01045c0
f0102a22:	68 09 4b 10 f0       	push   $0xf0104b09
f0102a27:	68 ab 03 00 00       	push   $0x3ab
f0102a2c:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0102a31:	e8 b0 d6 ff ff       	call   f01000e6 <_panic>
	kern_pgdir[0] = 0;
f0102a36:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102a3c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102a41:	74 19                	je     f0102a5c <mem_init+0x1641>
f0102a43:	68 ed 4c 10 f0       	push   $0xf0104ced
f0102a48:	68 09 4b 10 f0       	push   $0xf0104b09
f0102a4d:	68 ad 03 00 00       	push   $0x3ad
f0102a52:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0102a57:	e8 8a d6 ff ff       	call   f01000e6 <_panic>
	pp0->pp_ref = 0;
f0102a5c:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102a62:	83 ec 0c             	sub    $0xc,%esp
f0102a65:	53                   	push   %ebx
f0102a66:	e8 b6 e6 ff ff       	call   f0101121 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102a6b:	c7 04 24 a8 4a 10 f0 	movl   $0xf0104aa8,(%esp)
f0102a72:	e8 7d 00 00 00       	call   f0102af4 <cprintf>
		cprintf("%d,%x\n",i,kern_pgdir+i*PTSIZE);
	}
	}
	*/
	
}
f0102a77:	83 c4 10             	add    $0x10,%esp
f0102a7a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a7d:	5b                   	pop    %ebx
f0102a7e:	5e                   	pop    %esi
f0102a7f:	5f                   	pop    %edi
f0102a80:	5d                   	pop    %ebp
f0102a81:	c3                   	ret    

f0102a82 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102a82:	55                   	push   %ebp
f0102a83:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102a85:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102a88:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102a8b:	5d                   	pop    %ebp
f0102a8c:	c3                   	ret    

f0102a8d <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102a8d:	55                   	push   %ebp
f0102a8e:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102a90:	ba 70 00 00 00       	mov    $0x70,%edx
f0102a95:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a98:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102a99:	ba 71 00 00 00       	mov    $0x71,%edx
f0102a9e:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102a9f:	0f b6 c0             	movzbl %al,%eax
}
f0102aa2:	5d                   	pop    %ebp
f0102aa3:	c3                   	ret    

f0102aa4 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102aa4:	55                   	push   %ebp
f0102aa5:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102aa7:	ba 70 00 00 00       	mov    $0x70,%edx
f0102aac:	8b 45 08             	mov    0x8(%ebp),%eax
f0102aaf:	ee                   	out    %al,(%dx)
f0102ab0:	ba 71 00 00 00       	mov    $0x71,%edx
f0102ab5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ab8:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102ab9:	5d                   	pop    %ebp
f0102aba:	c3                   	ret    

f0102abb <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102abb:	55                   	push   %ebp
f0102abc:	89 e5                	mov    %esp,%ebp
f0102abe:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102ac1:	ff 75 08             	pushl  0x8(%ebp)
f0102ac4:	e8 84 db ff ff       	call   f010064d <cputchar>
	*cnt++;
}
f0102ac9:	83 c4 10             	add    $0x10,%esp
f0102acc:	c9                   	leave  
f0102acd:	c3                   	ret    

f0102ace <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102ace:	55                   	push   %ebp
f0102acf:	89 e5                	mov    %esp,%ebp
f0102ad1:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102ad4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102adb:	ff 75 0c             	pushl  0xc(%ebp)
f0102ade:	ff 75 08             	pushl  0x8(%ebp)
f0102ae1:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102ae4:	50                   	push   %eax
f0102ae5:	68 bb 2a 10 f0       	push   $0xf0102abb
f0102aea:	e8 60 04 00 00       	call   f0102f4f <vprintfmt>
	return cnt;
}
f0102aef:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102af2:	c9                   	leave  
f0102af3:	c3                   	ret    

f0102af4 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102af4:	55                   	push   %ebp
f0102af5:	89 e5                	mov    %esp,%ebp
f0102af7:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102afa:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102afd:	50                   	push   %eax
f0102afe:	ff 75 08             	pushl  0x8(%ebp)
f0102b01:	e8 c8 ff ff ff       	call   f0102ace <vcprintf>
	va_end(ap);

	return cnt;
}
f0102b06:	c9                   	leave  
f0102b07:	c3                   	ret    

f0102b08 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102b08:	55                   	push   %ebp
f0102b09:	89 e5                	mov    %esp,%ebp
f0102b0b:	57                   	push   %edi
f0102b0c:	56                   	push   %esi
f0102b0d:	53                   	push   %ebx
f0102b0e:	83 ec 14             	sub    $0x14,%esp
f0102b11:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102b14:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102b17:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102b1a:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102b1d:	8b 1a                	mov    (%edx),%ebx
f0102b1f:	8b 01                	mov    (%ecx),%eax
f0102b21:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102b24:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102b2b:	eb 7f                	jmp    f0102bac <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0102b2d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102b30:	01 d8                	add    %ebx,%eax
f0102b32:	89 c6                	mov    %eax,%esi
f0102b34:	c1 ee 1f             	shr    $0x1f,%esi
f0102b37:	01 c6                	add    %eax,%esi
f0102b39:	d1 fe                	sar    %esi
f0102b3b:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0102b3e:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102b41:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0102b44:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102b46:	eb 03                	jmp    f0102b4b <stab_binsearch+0x43>
			m--;
f0102b48:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102b4b:	39 c3                	cmp    %eax,%ebx
f0102b4d:	7f 0d                	jg     f0102b5c <stab_binsearch+0x54>
f0102b4f:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102b53:	83 ea 0c             	sub    $0xc,%edx
f0102b56:	39 f9                	cmp    %edi,%ecx
f0102b58:	75 ee                	jne    f0102b48 <stab_binsearch+0x40>
f0102b5a:	eb 05                	jmp    f0102b61 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102b5c:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0102b5f:	eb 4b                	jmp    f0102bac <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102b61:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102b64:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102b67:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102b6b:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102b6e:	76 11                	jbe    f0102b81 <stab_binsearch+0x79>
			*region_left = m;
f0102b70:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0102b73:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0102b75:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102b78:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102b7f:	eb 2b                	jmp    f0102bac <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102b81:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102b84:	73 14                	jae    f0102b9a <stab_binsearch+0x92>
			*region_right = m - 1;
f0102b86:	83 e8 01             	sub    $0x1,%eax
f0102b89:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102b8c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102b8f:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102b91:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102b98:	eb 12                	jmp    f0102bac <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102b9a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102b9d:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102b9f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0102ba3:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102ba5:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102bac:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102baf:	0f 8e 78 ff ff ff    	jle    f0102b2d <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102bb5:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0102bb9:	75 0f                	jne    f0102bca <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0102bbb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102bbe:	8b 00                	mov    (%eax),%eax
f0102bc0:	83 e8 01             	sub    $0x1,%eax
f0102bc3:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102bc6:	89 06                	mov    %eax,(%esi)
f0102bc8:	eb 2c                	jmp    f0102bf6 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102bca:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102bcd:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102bcf:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102bd2:	8b 0e                	mov    (%esi),%ecx
f0102bd4:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102bd7:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0102bda:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102bdd:	eb 03                	jmp    f0102be2 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102bdf:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102be2:	39 c8                	cmp    %ecx,%eax
f0102be4:	7e 0b                	jle    f0102bf1 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0102be6:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0102bea:	83 ea 0c             	sub    $0xc,%edx
f0102bed:	39 df                	cmp    %ebx,%edi
f0102bef:	75 ee                	jne    f0102bdf <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102bf1:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102bf4:	89 06                	mov    %eax,(%esi)
	}
}
f0102bf6:	83 c4 14             	add    $0x14,%esp
f0102bf9:	5b                   	pop    %ebx
f0102bfa:	5e                   	pop    %esi
f0102bfb:	5f                   	pop    %edi
f0102bfc:	5d                   	pop    %ebp
f0102bfd:	c3                   	ret    

f0102bfe <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102bfe:	55                   	push   %ebp
f0102bff:	89 e5                	mov    %esp,%ebp
f0102c01:	57                   	push   %edi
f0102c02:	56                   	push   %esi
f0102c03:	53                   	push   %ebx
f0102c04:	83 ec 3c             	sub    $0x3c,%esp
f0102c07:	8b 75 08             	mov    0x8(%ebp),%esi
f0102c0a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102c0d:	c7 03 8e 3f 10 f0    	movl   $0xf0103f8e,(%ebx)
	info->eip_line = 0;
f0102c13:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102c1a:	c7 43 08 8e 3f 10 f0 	movl   $0xf0103f8e,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102c21:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102c28:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102c2b:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102c32:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102c38:	76 11                	jbe    f0102c4b <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102c3a:	b8 59 d2 10 f0       	mov    $0xf010d259,%eax
f0102c3f:	3d fd b2 10 f0       	cmp    $0xf010b2fd,%eax
f0102c44:	77 19                	ja     f0102c5f <debuginfo_eip+0x61>
f0102c46:	e9 b8 01 00 00       	jmp    f0102e03 <debuginfo_eip+0x205>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102c4b:	83 ec 04             	sub    $0x4,%esp
f0102c4e:	68 00 4e 10 f0       	push   $0xf0104e00
f0102c53:	6a 7f                	push   $0x7f
f0102c55:	68 0d 4e 10 f0       	push   $0xf0104e0d
f0102c5a:	e8 87 d4 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102c5f:	80 3d 58 d2 10 f0 00 	cmpb   $0x0,0xf010d258
f0102c66:	0f 85 9e 01 00 00    	jne    f0102e0a <debuginfo_eip+0x20c>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102c6c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102c73:	b8 fc b2 10 f0       	mov    $0xf010b2fc,%eax
f0102c78:	2d 50 50 10 f0       	sub    $0xf0105050,%eax
f0102c7d:	c1 f8 02             	sar    $0x2,%eax
f0102c80:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102c86:	83 e8 01             	sub    $0x1,%eax
f0102c89:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102c8c:	83 ec 08             	sub    $0x8,%esp
f0102c8f:	56                   	push   %esi
f0102c90:	6a 64                	push   $0x64
f0102c92:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102c95:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102c98:	b8 50 50 10 f0       	mov    $0xf0105050,%eax
f0102c9d:	e8 66 fe ff ff       	call   f0102b08 <stab_binsearch>
	if (lfile == 0)
f0102ca2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102ca5:	83 c4 10             	add    $0x10,%esp
f0102ca8:	85 c0                	test   %eax,%eax
f0102caa:	0f 84 61 01 00 00    	je     f0102e11 <debuginfo_eip+0x213>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102cb0:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102cb3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102cb6:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102cb9:	83 ec 08             	sub    $0x8,%esp
f0102cbc:	56                   	push   %esi
f0102cbd:	6a 24                	push   $0x24
f0102cbf:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102cc2:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102cc5:	b8 50 50 10 f0       	mov    $0xf0105050,%eax
f0102cca:	e8 39 fe ff ff       	call   f0102b08 <stab_binsearch>

	if (lfun <= rfun) {
f0102ccf:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102cd2:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102cd5:	83 c4 10             	add    $0x10,%esp
f0102cd8:	39 d0                	cmp    %edx,%eax
f0102cda:	7f 40                	jg     f0102d1c <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102cdc:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0102cdf:	c1 e1 02             	shl    $0x2,%ecx
f0102ce2:	8d b9 50 50 10 f0    	lea    -0xfefafb0(%ecx),%edi
f0102ce8:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0102ceb:	8b b9 50 50 10 f0    	mov    -0xfefafb0(%ecx),%edi
f0102cf1:	b9 59 d2 10 f0       	mov    $0xf010d259,%ecx
f0102cf6:	81 e9 fd b2 10 f0    	sub    $0xf010b2fd,%ecx
f0102cfc:	39 cf                	cmp    %ecx,%edi
f0102cfe:	73 09                	jae    f0102d09 <debuginfo_eip+0x10b>
		{info->eip_fn_name = stabstr + stabs[lfun].n_strx;}
f0102d00:	81 c7 fd b2 10 f0    	add    $0xf010b2fd,%edi
f0102d06:	89 7b 08             	mov    %edi,0x8(%ebx)
				
		info->eip_fn_addr = stabs[lfun].n_value;
f0102d09:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102d0c:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102d0f:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102d12:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0102d14:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0102d17:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102d1a:	eb 0f                	jmp    f0102d2b <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102d1c:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102d1f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102d22:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0102d25:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102d28:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102d2b:	83 ec 08             	sub    $0x8,%esp
f0102d2e:	6a 3a                	push   $0x3a
f0102d30:	ff 73 08             	pushl  0x8(%ebx)
f0102d33:	e8 4b 0a 00 00       	call   f0103783 <strfind>
f0102d38:	2b 43 08             	sub    0x8(%ebx),%eax
f0102d3b:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
		stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0102d3e:	83 c4 08             	add    $0x8,%esp
f0102d41:	56                   	push   %esi
f0102d42:	6a 44                	push   $0x44
f0102d44:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0102d47:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0102d4a:	b8 50 50 10 f0       	mov    $0xf0105050,%eax
f0102d4f:	e8 b4 fd ff ff       	call   f0102b08 <stab_binsearch>
	if(lline<=rline){
f0102d54:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d57:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0102d5a:	83 c4 10             	add    $0x10,%esp
f0102d5d:	39 d0                	cmp    %edx,%eax
f0102d5f:	0f 8f b3 00 00 00    	jg     f0102e18 <debuginfo_eip+0x21a>
		info->eip_line = stabs[rline].n_desc;}
f0102d65:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102d68:	0f b7 14 95 56 50 10 	movzwl -0xfefafaa(,%edx,4),%edx
f0102d6f:	f0 
f0102d70:	89 53 04             	mov    %edx,0x4(%ebx)
	else{
	return -1;}
info->eip_fn_narg=addr;
f0102d73:	89 73 14             	mov    %esi,0x14(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102d76:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102d79:	89 c2                	mov    %eax,%edx
f0102d7b:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102d7e:	8d 04 85 50 50 10 f0 	lea    -0xfefafb0(,%eax,4),%eax
f0102d85:	eb 06                	jmp    f0102d8d <debuginfo_eip+0x18f>
f0102d87:	83 ea 01             	sub    $0x1,%edx
f0102d8a:	83 e8 0c             	sub    $0xc,%eax
f0102d8d:	39 d7                	cmp    %edx,%edi
f0102d8f:	7f 34                	jg     f0102dc5 <debuginfo_eip+0x1c7>
	       && stabs[lline].n_type != N_SOL
f0102d91:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0102d95:	80 f9 84             	cmp    $0x84,%cl
f0102d98:	74 0b                	je     f0102da5 <debuginfo_eip+0x1a7>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102d9a:	80 f9 64             	cmp    $0x64,%cl
f0102d9d:	75 e8                	jne    f0102d87 <debuginfo_eip+0x189>
f0102d9f:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102da3:	74 e2                	je     f0102d87 <debuginfo_eip+0x189>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102da5:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102da8:	8b 14 85 50 50 10 f0 	mov    -0xfefafb0(,%eax,4),%edx
f0102daf:	b8 59 d2 10 f0       	mov    $0xf010d259,%eax
f0102db4:	2d fd b2 10 f0       	sub    $0xf010b2fd,%eax
f0102db9:	39 c2                	cmp    %eax,%edx
f0102dbb:	73 08                	jae    f0102dc5 <debuginfo_eip+0x1c7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102dbd:	81 c2 fd b2 10 f0    	add    $0xf010b2fd,%edx
f0102dc3:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102dc5:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102dc8:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102dcb:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102dd0:	39 f2                	cmp    %esi,%edx
f0102dd2:	7d 50                	jge    f0102e24 <debuginfo_eip+0x226>
		for (lline = lfun + 1;
f0102dd4:	83 c2 01             	add    $0x1,%edx
f0102dd7:	89 d0                	mov    %edx,%eax
f0102dd9:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102ddc:	8d 14 95 50 50 10 f0 	lea    -0xfefafb0(,%edx,4),%edx
f0102de3:	eb 04                	jmp    f0102de9 <debuginfo_eip+0x1eb>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102de5:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102de9:	39 c6                	cmp    %eax,%esi
f0102deb:	7e 32                	jle    f0102e1f <debuginfo_eip+0x221>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102ded:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102df1:	83 c0 01             	add    $0x1,%eax
f0102df4:	83 c2 0c             	add    $0xc,%edx
f0102df7:	80 f9 a0             	cmp    $0xa0,%cl
f0102dfa:	74 e9                	je     f0102de5 <debuginfo_eip+0x1e7>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102dfc:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e01:	eb 21                	jmp    f0102e24 <debuginfo_eip+0x226>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102e03:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102e08:	eb 1a                	jmp    f0102e24 <debuginfo_eip+0x226>
f0102e0a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102e0f:	eb 13                	jmp    f0102e24 <debuginfo_eip+0x226>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102e11:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102e16:	eb 0c                	jmp    f0102e24 <debuginfo_eip+0x226>
	// Your code here.
		stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if(lline<=rline){
		info->eip_line = stabs[rline].n_desc;}
	else{
	return -1;}
f0102e18:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102e1d:	eb 05                	jmp    f0102e24 <debuginfo_eip+0x226>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102e1f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102e24:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e27:	5b                   	pop    %ebx
f0102e28:	5e                   	pop    %esi
f0102e29:	5f                   	pop    %edi
f0102e2a:	5d                   	pop    %ebp
f0102e2b:	c3                   	ret    

f0102e2c <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102e2c:	55                   	push   %ebp
f0102e2d:	89 e5                	mov    %esp,%ebp
f0102e2f:	57                   	push   %edi
f0102e30:	56                   	push   %esi
f0102e31:	53                   	push   %ebx
f0102e32:	83 ec 1c             	sub    $0x1c,%esp
f0102e35:	89 c7                	mov    %eax,%edi
f0102e37:	89 d6                	mov    %edx,%esi
f0102e39:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e3c:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102e3f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e42:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102e45:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102e48:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102e4d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102e50:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102e53:	39 d3                	cmp    %edx,%ebx
f0102e55:	72 05                	jb     f0102e5c <printnum+0x30>
f0102e57:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102e5a:	77 45                	ja     f0102ea1 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102e5c:	83 ec 0c             	sub    $0xc,%esp
f0102e5f:	ff 75 18             	pushl  0x18(%ebp)
f0102e62:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e65:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102e68:	53                   	push   %ebx
f0102e69:	ff 75 10             	pushl  0x10(%ebp)
f0102e6c:	83 ec 08             	sub    $0x8,%esp
f0102e6f:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102e72:	ff 75 e0             	pushl  -0x20(%ebp)
f0102e75:	ff 75 dc             	pushl  -0x24(%ebp)
f0102e78:	ff 75 d8             	pushl  -0x28(%ebp)
f0102e7b:	e8 30 0b 00 00       	call   f01039b0 <__udivdi3>
f0102e80:	83 c4 18             	add    $0x18,%esp
f0102e83:	52                   	push   %edx
f0102e84:	50                   	push   %eax
f0102e85:	89 f2                	mov    %esi,%edx
f0102e87:	89 f8                	mov    %edi,%eax
f0102e89:	e8 9e ff ff ff       	call   f0102e2c <printnum>
f0102e8e:	83 c4 20             	add    $0x20,%esp
f0102e91:	eb 18                	jmp    f0102eab <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102e93:	83 ec 08             	sub    $0x8,%esp
f0102e96:	56                   	push   %esi
f0102e97:	ff 75 18             	pushl  0x18(%ebp)
f0102e9a:	ff d7                	call   *%edi
f0102e9c:	83 c4 10             	add    $0x10,%esp
f0102e9f:	eb 03                	jmp    f0102ea4 <printnum+0x78>
f0102ea1:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102ea4:	83 eb 01             	sub    $0x1,%ebx
f0102ea7:	85 db                	test   %ebx,%ebx
f0102ea9:	7f e8                	jg     f0102e93 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102eab:	83 ec 08             	sub    $0x8,%esp
f0102eae:	56                   	push   %esi
f0102eaf:	83 ec 04             	sub    $0x4,%esp
f0102eb2:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102eb5:	ff 75 e0             	pushl  -0x20(%ebp)
f0102eb8:	ff 75 dc             	pushl  -0x24(%ebp)
f0102ebb:	ff 75 d8             	pushl  -0x28(%ebp)
f0102ebe:	e8 1d 0c 00 00       	call   f0103ae0 <__umoddi3>
f0102ec3:	83 c4 14             	add    $0x14,%esp
f0102ec6:	0f be 80 1b 4e 10 f0 	movsbl -0xfefb1e5(%eax),%eax
f0102ecd:	50                   	push   %eax
f0102ece:	ff d7                	call   *%edi
}
f0102ed0:	83 c4 10             	add    $0x10,%esp
f0102ed3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ed6:	5b                   	pop    %ebx
f0102ed7:	5e                   	pop    %esi
f0102ed8:	5f                   	pop    %edi
f0102ed9:	5d                   	pop    %ebp
f0102eda:	c3                   	ret    

f0102edb <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102edb:	55                   	push   %ebp
f0102edc:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102ede:	83 fa 01             	cmp    $0x1,%edx
f0102ee1:	7e 0e                	jle    f0102ef1 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102ee3:	8b 10                	mov    (%eax),%edx
f0102ee5:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102ee8:	89 08                	mov    %ecx,(%eax)
f0102eea:	8b 02                	mov    (%edx),%eax
f0102eec:	8b 52 04             	mov    0x4(%edx),%edx
f0102eef:	eb 22                	jmp    f0102f13 <getuint+0x38>
	else if (lflag)
f0102ef1:	85 d2                	test   %edx,%edx
f0102ef3:	74 10                	je     f0102f05 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102ef5:	8b 10                	mov    (%eax),%edx
f0102ef7:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102efa:	89 08                	mov    %ecx,(%eax)
f0102efc:	8b 02                	mov    (%edx),%eax
f0102efe:	ba 00 00 00 00       	mov    $0x0,%edx
f0102f03:	eb 0e                	jmp    f0102f13 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102f05:	8b 10                	mov    (%eax),%edx
f0102f07:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102f0a:	89 08                	mov    %ecx,(%eax)
f0102f0c:	8b 02                	mov    (%edx),%eax
f0102f0e:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102f13:	5d                   	pop    %ebp
f0102f14:	c3                   	ret    

f0102f15 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102f15:	55                   	push   %ebp
f0102f16:	89 e5                	mov    %esp,%ebp
f0102f18:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102f1b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102f1f:	8b 10                	mov    (%eax),%edx
f0102f21:	3b 50 04             	cmp    0x4(%eax),%edx
f0102f24:	73 0a                	jae    f0102f30 <sprintputch+0x1b>
		*b->buf++ = ch;
f0102f26:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102f29:	89 08                	mov    %ecx,(%eax)
f0102f2b:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f2e:	88 02                	mov    %al,(%edx)
}
f0102f30:	5d                   	pop    %ebp
f0102f31:	c3                   	ret    

f0102f32 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102f32:	55                   	push   %ebp
f0102f33:	89 e5                	mov    %esp,%ebp
f0102f35:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102f38:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102f3b:	50                   	push   %eax
f0102f3c:	ff 75 10             	pushl  0x10(%ebp)
f0102f3f:	ff 75 0c             	pushl  0xc(%ebp)
f0102f42:	ff 75 08             	pushl  0x8(%ebp)
f0102f45:	e8 05 00 00 00       	call   f0102f4f <vprintfmt>
	va_end(ap);
}
f0102f4a:	83 c4 10             	add    $0x10,%esp
f0102f4d:	c9                   	leave  
f0102f4e:	c3                   	ret    

f0102f4f <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102f4f:	55                   	push   %ebp
f0102f50:	89 e5                	mov    %esp,%ebp
f0102f52:	57                   	push   %edi
f0102f53:	56                   	push   %esi
f0102f54:	53                   	push   %ebx
f0102f55:	83 ec 2c             	sub    $0x2c,%esp
f0102f58:	8b 75 08             	mov    0x8(%ebp),%esi
f0102f5b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102f5e:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102f61:	eb 12                	jmp    f0102f75 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102f63:	85 c0                	test   %eax,%eax
f0102f65:	0f 84 89 03 00 00    	je     f01032f4 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0102f6b:	83 ec 08             	sub    $0x8,%esp
f0102f6e:	53                   	push   %ebx
f0102f6f:	50                   	push   %eax
f0102f70:	ff d6                	call   *%esi
f0102f72:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102f75:	83 c7 01             	add    $0x1,%edi
f0102f78:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102f7c:	83 f8 25             	cmp    $0x25,%eax
f0102f7f:	75 e2                	jne    f0102f63 <vprintfmt+0x14>
f0102f81:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102f85:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102f8c:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102f93:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102f9a:	ba 00 00 00 00       	mov    $0x0,%edx
f0102f9f:	eb 07                	jmp    f0102fa8 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102fa1:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102fa4:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102fa8:	8d 47 01             	lea    0x1(%edi),%eax
f0102fab:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102fae:	0f b6 07             	movzbl (%edi),%eax
f0102fb1:	0f b6 c8             	movzbl %al,%ecx
f0102fb4:	83 e8 23             	sub    $0x23,%eax
f0102fb7:	3c 55                	cmp    $0x55,%al
f0102fb9:	0f 87 1a 03 00 00    	ja     f01032d9 <vprintfmt+0x38a>
f0102fbf:	0f b6 c0             	movzbl %al,%eax
f0102fc2:	ff 24 85 c0 4e 10 f0 	jmp    *-0xfefb140(,%eax,4)
f0102fc9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102fcc:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102fd0:	eb d6                	jmp    f0102fa8 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102fd2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102fd5:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fda:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102fdd:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102fe0:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102fe4:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102fe7:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102fea:	83 fa 09             	cmp    $0x9,%edx
f0102fed:	77 39                	ja     f0103028 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102fef:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102ff2:	eb e9                	jmp    f0102fdd <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102ff4:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ff7:	8d 48 04             	lea    0x4(%eax),%ecx
f0102ffa:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102ffd:	8b 00                	mov    (%eax),%eax
f0102fff:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103002:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103005:	eb 27                	jmp    f010302e <vprintfmt+0xdf>
f0103007:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010300a:	85 c0                	test   %eax,%eax
f010300c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103011:	0f 49 c8             	cmovns %eax,%ecx
f0103014:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103017:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010301a:	eb 8c                	jmp    f0102fa8 <vprintfmt+0x59>
f010301c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f010301f:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103026:	eb 80                	jmp    f0102fa8 <vprintfmt+0x59>
f0103028:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010302b:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f010302e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103032:	0f 89 70 ff ff ff    	jns    f0102fa8 <vprintfmt+0x59>
				width = precision, precision = -1;
f0103038:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010303b:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010303e:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103045:	e9 5e ff ff ff       	jmp    f0102fa8 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f010304a:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010304d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103050:	e9 53 ff ff ff       	jmp    f0102fa8 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103055:	8b 45 14             	mov    0x14(%ebp),%eax
f0103058:	8d 50 04             	lea    0x4(%eax),%edx
f010305b:	89 55 14             	mov    %edx,0x14(%ebp)
f010305e:	83 ec 08             	sub    $0x8,%esp
f0103061:	53                   	push   %ebx
f0103062:	ff 30                	pushl  (%eax)
f0103064:	ff d6                	call   *%esi
			break;
f0103066:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103069:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f010306c:	e9 04 ff ff ff       	jmp    f0102f75 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103071:	8b 45 14             	mov    0x14(%ebp),%eax
f0103074:	8d 50 04             	lea    0x4(%eax),%edx
f0103077:	89 55 14             	mov    %edx,0x14(%ebp)
f010307a:	8b 00                	mov    (%eax),%eax
f010307c:	99                   	cltd   
f010307d:	31 d0                	xor    %edx,%eax
f010307f:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103081:	83 f8 07             	cmp    $0x7,%eax
f0103084:	7f 0b                	jg     f0103091 <vprintfmt+0x142>
f0103086:	8b 14 85 20 50 10 f0 	mov    -0xfefafe0(,%eax,4),%edx
f010308d:	85 d2                	test   %edx,%edx
f010308f:	75 18                	jne    f01030a9 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0103091:	50                   	push   %eax
f0103092:	68 33 4e 10 f0       	push   $0xf0104e33
f0103097:	53                   	push   %ebx
f0103098:	56                   	push   %esi
f0103099:	e8 94 fe ff ff       	call   f0102f32 <printfmt>
f010309e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01030a1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01030a4:	e9 cc fe ff ff       	jmp    f0102f75 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f01030a9:	52                   	push   %edx
f01030aa:	68 1b 4b 10 f0       	push   $0xf0104b1b
f01030af:	53                   	push   %ebx
f01030b0:	56                   	push   %esi
f01030b1:	e8 7c fe ff ff       	call   f0102f32 <printfmt>
f01030b6:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01030b9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01030bc:	e9 b4 fe ff ff       	jmp    f0102f75 <vprintfmt+0x26>
			break;

		// string
		case 's':
				//putch(precision, putdat);
			if ((p = va_arg(ap, char *)) == NULL)
f01030c1:	8b 45 14             	mov    0x14(%ebp),%eax
f01030c4:	8d 50 04             	lea    0x4(%eax),%edx
f01030c7:	89 55 14             	mov    %edx,0x14(%ebp)
f01030ca:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01030cc:	85 ff                	test   %edi,%edi
f01030ce:	b8 2c 4e 10 f0       	mov    $0xf0104e2c,%eax
f01030d3:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01030d6:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01030da:	0f 8e 94 00 00 00    	jle    f0103174 <vprintfmt+0x225>
f01030e0:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01030e4:	0f 84 98 00 00 00    	je     f0103182 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f01030ea:	83 ec 08             	sub    $0x8,%esp
f01030ed:	ff 75 d0             	pushl  -0x30(%ebp)
f01030f0:	57                   	push   %edi
f01030f1:	e8 43 05 00 00       	call   f0103639 <strnlen>
f01030f6:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01030f9:	29 c1                	sub    %eax,%ecx
f01030fb:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f01030fe:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103101:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103105:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103108:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010310b:	89 cf                	mov    %ecx,%edi
		case 's':
				//putch(precision, putdat);
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010310d:	eb 0f                	jmp    f010311e <vprintfmt+0x1cf>
					putch(padc, putdat);
f010310f:	83 ec 08             	sub    $0x8,%esp
f0103112:	53                   	push   %ebx
f0103113:	ff 75 e0             	pushl  -0x20(%ebp)
f0103116:	ff d6                	call   *%esi
		case 's':
				//putch(precision, putdat);
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103118:	83 ef 01             	sub    $0x1,%edi
f010311b:	83 c4 10             	add    $0x10,%esp
f010311e:	85 ff                	test   %edi,%edi
f0103120:	7f ed                	jg     f010310f <vprintfmt+0x1c0>
f0103122:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103125:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0103128:	85 c9                	test   %ecx,%ecx
f010312a:	b8 00 00 00 00       	mov    $0x0,%eax
f010312f:	0f 49 c1             	cmovns %ecx,%eax
f0103132:	29 c1                	sub    %eax,%ecx
f0103134:	89 75 08             	mov    %esi,0x8(%ebp)
f0103137:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010313a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010313d:	89 cb                	mov    %ecx,%ebx
f010313f:	eb 4d                	jmp    f010318e <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103141:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103145:	74 1b                	je     f0103162 <vprintfmt+0x213>
f0103147:	0f be c0             	movsbl %al,%eax
f010314a:	83 e8 20             	sub    $0x20,%eax
f010314d:	83 f8 5e             	cmp    $0x5e,%eax
f0103150:	76 10                	jbe    f0103162 <vprintfmt+0x213>
					putch('?', putdat);
f0103152:	83 ec 08             	sub    $0x8,%esp
f0103155:	ff 75 0c             	pushl  0xc(%ebp)
f0103158:	6a 3f                	push   $0x3f
f010315a:	ff 55 08             	call   *0x8(%ebp)
f010315d:	83 c4 10             	add    $0x10,%esp
f0103160:	eb 0d                	jmp    f010316f <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0103162:	83 ec 08             	sub    $0x8,%esp
f0103165:	ff 75 0c             	pushl  0xc(%ebp)
f0103168:	52                   	push   %edx
f0103169:	ff 55 08             	call   *0x8(%ebp)
f010316c:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010316f:	83 eb 01             	sub    $0x1,%ebx
f0103172:	eb 1a                	jmp    f010318e <vprintfmt+0x23f>
f0103174:	89 75 08             	mov    %esi,0x8(%ebp)
f0103177:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010317a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010317d:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103180:	eb 0c                	jmp    f010318e <vprintfmt+0x23f>
f0103182:	89 75 08             	mov    %esi,0x8(%ebp)
f0103185:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103188:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010318b:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010318e:	83 c7 01             	add    $0x1,%edi
f0103191:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103195:	0f be d0             	movsbl %al,%edx
f0103198:	85 d2                	test   %edx,%edx
f010319a:	74 23                	je     f01031bf <vprintfmt+0x270>
f010319c:	85 f6                	test   %esi,%esi
f010319e:	78 a1                	js     f0103141 <vprintfmt+0x1f2>
f01031a0:	83 ee 01             	sub    $0x1,%esi
f01031a3:	79 9c                	jns    f0103141 <vprintfmt+0x1f2>
f01031a5:	89 df                	mov    %ebx,%edi
f01031a7:	8b 75 08             	mov    0x8(%ebp),%esi
f01031aa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01031ad:	eb 18                	jmp    f01031c7 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01031af:	83 ec 08             	sub    $0x8,%esp
f01031b2:	53                   	push   %ebx
f01031b3:	6a 20                	push   $0x20
f01031b5:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01031b7:	83 ef 01             	sub    $0x1,%edi
f01031ba:	83 c4 10             	add    $0x10,%esp
f01031bd:	eb 08                	jmp    f01031c7 <vprintfmt+0x278>
f01031bf:	89 df                	mov    %ebx,%edi
f01031c1:	8b 75 08             	mov    0x8(%ebp),%esi
f01031c4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01031c7:	85 ff                	test   %edi,%edi
f01031c9:	7f e4                	jg     f01031af <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01031cb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01031ce:	e9 a2 fd ff ff       	jmp    f0102f75 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01031d3:	83 fa 01             	cmp    $0x1,%edx
f01031d6:	7e 16                	jle    f01031ee <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f01031d8:	8b 45 14             	mov    0x14(%ebp),%eax
f01031db:	8d 50 08             	lea    0x8(%eax),%edx
f01031de:	89 55 14             	mov    %edx,0x14(%ebp)
f01031e1:	8b 50 04             	mov    0x4(%eax),%edx
f01031e4:	8b 00                	mov    (%eax),%eax
f01031e6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01031e9:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01031ec:	eb 32                	jmp    f0103220 <vprintfmt+0x2d1>
	else if (lflag)
f01031ee:	85 d2                	test   %edx,%edx
f01031f0:	74 18                	je     f010320a <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f01031f2:	8b 45 14             	mov    0x14(%ebp),%eax
f01031f5:	8d 50 04             	lea    0x4(%eax),%edx
f01031f8:	89 55 14             	mov    %edx,0x14(%ebp)
f01031fb:	8b 00                	mov    (%eax),%eax
f01031fd:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103200:	89 c1                	mov    %eax,%ecx
f0103202:	c1 f9 1f             	sar    $0x1f,%ecx
f0103205:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103208:	eb 16                	jmp    f0103220 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f010320a:	8b 45 14             	mov    0x14(%ebp),%eax
f010320d:	8d 50 04             	lea    0x4(%eax),%edx
f0103210:	89 55 14             	mov    %edx,0x14(%ebp)
f0103213:	8b 00                	mov    (%eax),%eax
f0103215:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103218:	89 c1                	mov    %eax,%ecx
f010321a:	c1 f9 1f             	sar    $0x1f,%ecx
f010321d:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103220:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103223:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103226:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f010322b:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010322f:	79 74                	jns    f01032a5 <vprintfmt+0x356>
				putch('-', putdat);
f0103231:	83 ec 08             	sub    $0x8,%esp
f0103234:	53                   	push   %ebx
f0103235:	6a 2d                	push   $0x2d
f0103237:	ff d6                	call   *%esi
				num = -(long long) num;
f0103239:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010323c:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010323f:	f7 d8                	neg    %eax
f0103241:	83 d2 00             	adc    $0x0,%edx
f0103244:	f7 da                	neg    %edx
f0103246:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103249:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010324e:	eb 55                	jmp    f01032a5 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103250:	8d 45 14             	lea    0x14(%ebp),%eax
f0103253:	e8 83 fc ff ff       	call   f0102edb <getuint>
			base = 10;
f0103258:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f010325d:	eb 46                	jmp    f01032a5 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			//putch('o', putdat);
			num = getuint(&ap, lflag);
f010325f:	8d 45 14             	lea    0x14(%ebp),%eax
f0103262:	e8 74 fc ff ff       	call   f0102edb <getuint>
			base = 8;
f0103267:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f010326c:	eb 37                	jmp    f01032a5 <vprintfmt+0x356>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f010326e:	83 ec 08             	sub    $0x8,%esp
f0103271:	53                   	push   %ebx
f0103272:	6a 30                	push   $0x30
f0103274:	ff d6                	call   *%esi
			putch('x', putdat);
f0103276:	83 c4 08             	add    $0x8,%esp
f0103279:	53                   	push   %ebx
f010327a:	6a 78                	push   $0x78
f010327c:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010327e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103281:	8d 50 04             	lea    0x4(%eax),%edx
f0103284:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103287:	8b 00                	mov    (%eax),%eax
f0103289:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010328e:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103291:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103296:	eb 0d                	jmp    f01032a5 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103298:	8d 45 14             	lea    0x14(%ebp),%eax
f010329b:	e8 3b fc ff ff       	call   f0102edb <getuint>
			base = 16;
f01032a0:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01032a5:	83 ec 0c             	sub    $0xc,%esp
f01032a8:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01032ac:	57                   	push   %edi
f01032ad:	ff 75 e0             	pushl  -0x20(%ebp)
f01032b0:	51                   	push   %ecx
f01032b1:	52                   	push   %edx
f01032b2:	50                   	push   %eax
f01032b3:	89 da                	mov    %ebx,%edx
f01032b5:	89 f0                	mov    %esi,%eax
f01032b7:	e8 70 fb ff ff       	call   f0102e2c <printnum>
			break;
f01032bc:	83 c4 20             	add    $0x20,%esp
f01032bf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01032c2:	e9 ae fc ff ff       	jmp    f0102f75 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01032c7:	83 ec 08             	sub    $0x8,%esp
f01032ca:	53                   	push   %ebx
f01032cb:	51                   	push   %ecx
f01032cc:	ff d6                	call   *%esi
			break;
f01032ce:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032d1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01032d4:	e9 9c fc ff ff       	jmp    f0102f75 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01032d9:	83 ec 08             	sub    $0x8,%esp
f01032dc:	53                   	push   %ebx
f01032dd:	6a 25                	push   $0x25
f01032df:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01032e1:	83 c4 10             	add    $0x10,%esp
f01032e4:	eb 03                	jmp    f01032e9 <vprintfmt+0x39a>
f01032e6:	83 ef 01             	sub    $0x1,%edi
f01032e9:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01032ed:	75 f7                	jne    f01032e6 <vprintfmt+0x397>
f01032ef:	e9 81 fc ff ff       	jmp    f0102f75 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01032f4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01032f7:	5b                   	pop    %ebx
f01032f8:	5e                   	pop    %esi
f01032f9:	5f                   	pop    %edi
f01032fa:	5d                   	pop    %ebp
f01032fb:	c3                   	ret    

f01032fc <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01032fc:	55                   	push   %ebp
f01032fd:	89 e5                	mov    %esp,%ebp
f01032ff:	83 ec 18             	sub    $0x18,%esp
f0103302:	8b 45 08             	mov    0x8(%ebp),%eax
f0103305:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103308:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010330b:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010330f:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103312:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103319:	85 c0                	test   %eax,%eax
f010331b:	74 26                	je     f0103343 <vsnprintf+0x47>
f010331d:	85 d2                	test   %edx,%edx
f010331f:	7e 22                	jle    f0103343 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103321:	ff 75 14             	pushl  0x14(%ebp)
f0103324:	ff 75 10             	pushl  0x10(%ebp)
f0103327:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010332a:	50                   	push   %eax
f010332b:	68 15 2f 10 f0       	push   $0xf0102f15
f0103330:	e8 1a fc ff ff       	call   f0102f4f <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103335:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103338:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010333b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010333e:	83 c4 10             	add    $0x10,%esp
f0103341:	eb 05                	jmp    f0103348 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103343:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103348:	c9                   	leave  
f0103349:	c3                   	ret    

f010334a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010334a:	55                   	push   %ebp
f010334b:	89 e5                	mov    %esp,%ebp
f010334d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103350:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103353:	50                   	push   %eax
f0103354:	ff 75 10             	pushl  0x10(%ebp)
f0103357:	ff 75 0c             	pushl  0xc(%ebp)
f010335a:	ff 75 08             	pushl  0x8(%ebp)
f010335d:	e8 9a ff ff ff       	call   f01032fc <vsnprintf>
	va_end(ap);

	return rc;
}
f0103362:	c9                   	leave  
f0103363:	c3                   	ret    

f0103364 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];
static int flag=0;
char *
readline(const char *prompt,char** cmd_history, int current_cmd)
{	
f0103364:	55                   	push   %ebp
f0103365:	89 e5                	mov    %esp,%ebp
f0103367:	57                   	push   %edi
f0103368:	56                   	push   %esi
f0103369:	53                   	push   %ebx
f010336a:	83 ec 1c             	sub    $0x1c,%esp
f010336d:	8b 45 08             	mov    0x8(%ebp),%eax
		cprintf("%s ",cmd_history[i]);
	}
	*/
	int i, c, echoing;
	int count=current_cmd;
	if (prompt != NULL)
f0103370:	85 c0                	test   %eax,%eax
f0103372:	74 11                	je     f0103385 <readline+0x21>
		//if(prompt=='[A'){
		//cprintf("111");}
	//else{
		cprintf("%s", prompt);
f0103374:	83 ec 08             	sub    $0x8,%esp
f0103377:	50                   	push   %eax
f0103378:	68 1b 4b 10 f0       	push   $0xf0104b1b
f010337d:	e8 72 f7 ff ff       	call   f0102af4 <cprintf>
f0103382:	83 c4 10             	add    $0x10,%esp
//}

	i = 0;
	echoing = iscons(0);
f0103385:	83 ec 0c             	sub    $0xc,%esp
f0103388:	6a 00                	push   $0x0
f010338a:	e8 df d2 ff ff       	call   f010066e <iscons>
f010338f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103392:	83 c4 10             	add    $0x10,%esp
	for(int i=0;i<current_cmd;i++){
		cprintf("%s ",cmd_history[i]);
	}
	*/
	int i, c, echoing;
	int count=current_cmd;
f0103395:	8b 45 10             	mov    0x10(%ebp),%eax
f0103398:	89 45 dc             	mov    %eax,-0x24(%ebp)
		//cprintf("111");}
	//else{
		cprintf("%s", prompt);
//}

	i = 0;
f010339b:	bf 00 00 00 00       	mov    $0x0,%edi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01033a0:	e8 b8 d2 ff ff       	call   f010065d <getchar>
f01033a5:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01033a7:	85 c0                	test   %eax,%eax
f01033a9:	79 1b                	jns    f01033c6 <readline+0x62>
			cprintf("read error: %e\n", c);
f01033ab:	83 ec 08             	sub    $0x8,%esp
f01033ae:	50                   	push   %eax
f01033af:	68 40 50 10 f0       	push   $0xf0105040
f01033b4:	e8 3b f7 ff ff       	call   f0102af4 <cprintf>
			return NULL;
f01033b9:	83 c4 10             	add    $0x10,%esp
f01033bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01033c1:	e9 53 02 00 00       	jmp    f0103619 <readline+0x2b5>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01033c6:	83 f8 08             	cmp    $0x8,%eax
f01033c9:	0f 94 c2             	sete   %dl
f01033cc:	83 f8 7f             	cmp    $0x7f,%eax
f01033cf:	0f 94 c0             	sete   %al
f01033d2:	08 c2                	or     %al,%dl
f01033d4:	74 1c                	je     f01033f2 <readline+0x8e>
f01033d6:	85 ff                	test   %edi,%edi
f01033d8:	7e 18                	jle    f01033f2 <readline+0x8e>
			if (echoing)
f01033da:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01033de:	74 0d                	je     f01033ed <readline+0x89>
				cputchar('\b');
f01033e0:	83 ec 0c             	sub    $0xc,%esp
f01033e3:	6a 08                	push   $0x8
f01033e5:	e8 63 d2 ff ff       	call   f010064d <cputchar>
f01033ea:	83 c4 10             	add    $0x10,%esp
			i--;
f01033ed:	83 ef 01             	sub    $0x1,%edi
f01033f0:	eb ae                	jmp    f01033a0 <readline+0x3c>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01033f2:	83 fb 1f             	cmp    $0x1f,%ebx
f01033f5:	0f 8e f1 01 00 00    	jle    f01035ec <readline+0x288>
f01033fb:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0103401:	0f 8f e5 01 00 00    	jg     f01035ec <readline+0x288>
			if(c=='['&&flag==0){flag=1;continue;}
f0103407:	83 fb 5b             	cmp    $0x5b,%ebx
f010340a:	75 1c                	jne    f0103428 <readline+0xc4>
f010340c:	83 3d 60 85 11 f0 00 	cmpl   $0x0,0xf0118560
f0103413:	0f 85 a0 01 00 00    	jne    f01035b9 <readline+0x255>
f0103419:	c7 05 60 85 11 f0 01 	movl   $0x1,0xf0118560
f0103420:	00 00 00 
f0103423:	e9 78 ff ff ff       	jmp    f01033a0 <readline+0x3c>
			if(c=='A'&&flag==1){
f0103428:	83 fb 41             	cmp    $0x41,%ebx
f010342b:	0f 85 be 00 00 00    	jne    f01034ef <readline+0x18b>
f0103431:	83 3d 60 85 11 f0 01 	cmpl   $0x1,0xf0118560
f0103438:	0f 85 8e 01 00 00    	jne    f01035cc <readline+0x268>
				flag=0;
f010343e:	c7 05 60 85 11 f0 00 	movl   $0x0,0xf0118560
f0103445:	00 00 00 
				if(count<=0)continue;
f0103448:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010344b:	85 c0                	test   %eax,%eax
f010344d:	0f 8e 4d ff ff ff    	jle    f01033a0 <readline+0x3c>
f0103453:	89 7d e4             	mov    %edi,-0x1c(%ebp)
				
				if(count<current_cmd){
f0103456:	3b 45 10             	cmp    0x10(%ebp),%eax
f0103459:	7d 40                	jge    f010349b <readline+0x137>
					int back_len=strlen(cmd_history[count]);
f010345b:	83 ec 0c             	sub    $0xc,%esp
f010345e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103461:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103464:	ff 34 88             	pushl  (%eax,%ecx,4)
f0103467:	e8 b5 01 00 00       	call   f0103621 <strlen>
f010346c:	89 c6                	mov    %eax,%esi
					for(int j=0;j<back_len;j++){
f010346e:	83 c4 10             	add    $0x10,%esp
f0103471:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103476:	eb 10                	jmp    f0103488 <readline+0x124>
						cputchar('\b');
f0103478:	83 ec 0c             	sub    $0xc,%esp
f010347b:	6a 08                	push   $0x8
f010347d:	e8 cb d1 ff ff       	call   f010064d <cputchar>
				flag=0;
				if(count<=0)continue;
				
				if(count<current_cmd){
					int back_len=strlen(cmd_history[count]);
					for(int j=0;j<back_len;j++){
f0103482:	83 c3 01             	add    $0x1,%ebx
f0103485:	83 c4 10             	add    $0x10,%esp
f0103488:	39 f3                	cmp    %esi,%ebx
f010348a:	7c ec                	jl     f0103478 <readline+0x114>
f010348c:	85 f6                	test   %esi,%esi
f010348e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103493:	0f 48 f0             	cmovs  %eax,%esi
f0103496:	29 f7                	sub    %esi,%edi
f0103498:	89 7d e4             	mov    %edi,-0x1c(%ebp)
						cputchar('\b');
						i--;
					}
				}
				
				char* cmd_string=cmd_history[--count];
f010349b:	83 6d dc 01          	subl   $0x1,-0x24(%ebp)
f010349f:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01034a2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01034a5:	8b 34 81             	mov    (%ecx,%eax,4),%esi
				cprintf("%s",cmd_string);
f01034a8:	83 ec 08             	sub    $0x8,%esp
f01034ab:	56                   	push   %esi
f01034ac:	68 1b 4b 10 f0       	push   $0xf0104b1b
f01034b1:	e8 3e f6 ff ff       	call   f0102af4 <cprintf>
				for(int j=0;j<strlen(cmd_string);j++){
f01034b6:	83 c4 10             	add    $0x10,%esp
f01034b9:	bb 00 00 00 00       	mov    $0x0,%ebx
f01034be:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01034c1:	eb 0e                	jmp    f01034d1 <readline+0x16d>
					buf[i++] = cmd_string[j];
f01034c3:	0f b6 04 1e          	movzbl (%esi,%ebx,1),%eax
f01034c7:	88 84 1f 80 85 11 f0 	mov    %al,-0xfee7a80(%edi,%ebx,1)
					}
				}
				
				char* cmd_string=cmd_history[--count];
				cprintf("%s",cmd_string);
				for(int j=0;j<strlen(cmd_string);j++){
f01034ce:	83 c3 01             	add    $0x1,%ebx
f01034d1:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f01034d4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01034d7:	83 ec 0c             	sub    $0xc,%esp
f01034da:	56                   	push   %esi
f01034db:	e8 41 01 00 00       	call   f0103621 <strlen>
f01034e0:	83 c4 10             	add    $0x10,%esp
f01034e3:	39 c3                	cmp    %eax,%ebx
f01034e5:	7c dc                	jl     f01034c3 <readline+0x15f>
f01034e7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01034ea:	e9 b1 fe ff ff       	jmp    f01033a0 <readline+0x3c>
					buf[i++] = cmd_string[j];
				}
			
				continue;
			}
			if(c=='B'&&flag==1){
f01034ef:	83 fb 42             	cmp    $0x42,%ebx
f01034f2:	0f 85 c1 00 00 00    	jne    f01035b9 <readline+0x255>
f01034f8:	83 3d 60 85 11 f0 01 	cmpl   $0x1,0xf0118560
f01034ff:	0f 85 c7 00 00 00    	jne    f01035cc <readline+0x268>
				flag=0;
f0103505:	c7 05 60 85 11 f0 00 	movl   $0x0,0xf0118560
f010350c:	00 00 00 
				if(count<0)continue;
f010350f:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103512:	85 c0                	test   %eax,%eax
f0103514:	0f 88 86 fe ff ff    	js     f01033a0 <readline+0x3c>
				if(count>=current_cmd)continue;
f010351a:	3b 45 10             	cmp    0x10(%ebp),%eax
f010351d:	0f 8d 7d fe ff ff    	jge    f01033a0 <readline+0x3c>
				int back_len=strlen(cmd_history[count]);
f0103523:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
f010352a:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f010352d:	83 ec 0c             	sub    $0xc,%esp
f0103530:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103533:	ff 34 81             	pushl  (%ecx,%eax,4)
f0103536:	e8 e6 00 00 00       	call   f0103621 <strlen>
f010353b:	89 c6                	mov    %eax,%esi
					for(int j=0;j<back_len;j++){
f010353d:	83 c4 10             	add    $0x10,%esp
f0103540:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103545:	eb 10                	jmp    f0103557 <readline+0x1f3>
						cputchar('\b');
f0103547:	83 ec 0c             	sub    $0xc,%esp
f010354a:	6a 08                	push   $0x8
f010354c:	e8 fc d0 ff ff       	call   f010064d <cputchar>
			if(c=='B'&&flag==1){
				flag=0;
				if(count<0)continue;
				if(count>=current_cmd)continue;
				int back_len=strlen(cmd_history[count]);
					for(int j=0;j<back_len;j++){
f0103551:	83 c3 01             	add    $0x1,%ebx
f0103554:	83 c4 10             	add    $0x10,%esp
f0103557:	39 f3                	cmp    %esi,%ebx
f0103559:	7c ec                	jl     f0103547 <readline+0x1e3>
f010355b:	85 f6                	test   %esi,%esi
f010355d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103562:	0f 48 f0             	cmovs  %eax,%esi
f0103565:	29 f7                	sub    %esi,%edi
						cputchar('\b');
						i--;
					}
				char* cmd_string=cmd_history[++count];
f0103567:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
f010356b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010356e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103571:	8b 74 08 04          	mov    0x4(%eax,%ecx,1),%esi
				cprintf("%s",cmd_string);
f0103575:	83 ec 08             	sub    $0x8,%esp
f0103578:	56                   	push   %esi
f0103579:	68 1b 4b 10 f0       	push   $0xf0104b1b
f010357e:	e8 71 f5 ff ff       	call   f0102af4 <cprintf>
				for(int j=0;j<strlen(cmd_string);j++){
f0103583:	83 c4 10             	add    $0x10,%esp
f0103586:	bb 00 00 00 00       	mov    $0x0,%ebx
f010358b:	eb 0e                	jmp    f010359b <readline+0x237>
					buf[i++] = cmd_string[j];
f010358d:	0f b6 04 1e          	movzbl (%esi,%ebx,1),%eax
f0103591:	88 84 3b 80 85 11 f0 	mov    %al,-0xfee7a80(%ebx,%edi,1)
						cputchar('\b');
						i--;
					}
				char* cmd_string=cmd_history[++count];
				cprintf("%s",cmd_string);
				for(int j=0;j<strlen(cmd_string);j++){
f0103598:	83 c3 01             	add    $0x1,%ebx
f010359b:	8d 04 3b             	lea    (%ebx,%edi,1),%eax
f010359e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01035a1:	83 ec 0c             	sub    $0xc,%esp
f01035a4:	56                   	push   %esi
f01035a5:	e8 77 00 00 00       	call   f0103621 <strlen>
f01035aa:	83 c4 10             	add    $0x10,%esp
f01035ad:	39 c3                	cmp    %eax,%ebx
f01035af:	7c dc                	jl     f010358d <readline+0x229>
f01035b1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01035b4:	e9 e7 fd ff ff       	jmp    f01033a0 <readline+0x3c>
					buf[i++] = cmd_string[j];
				}
				continue;
			}
			if(flag==1){flag=0;}
f01035b9:	83 3d 60 85 11 f0 01 	cmpl   $0x1,0xf0118560
f01035c0:	75 0a                	jne    f01035cc <readline+0x268>
f01035c2:	c7 05 60 85 11 f0 00 	movl   $0x0,0xf0118560
f01035c9:	00 00 00 
			if (echoing)
f01035cc:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01035d0:	74 0c                	je     f01035de <readline+0x27a>
				cputchar(c);
f01035d2:	83 ec 0c             	sub    $0xc,%esp
f01035d5:	53                   	push   %ebx
f01035d6:	e8 72 d0 ff ff       	call   f010064d <cputchar>
f01035db:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01035de:	88 9f 80 85 11 f0    	mov    %bl,-0xfee7a80(%edi)
f01035e4:	8d 7f 01             	lea    0x1(%edi),%edi
f01035e7:	e9 b4 fd ff ff       	jmp    f01033a0 <readline+0x3c>
		} else if (c == '\n' || c == '\r') {
f01035ec:	83 fb 0a             	cmp    $0xa,%ebx
f01035ef:	74 09                	je     f01035fa <readline+0x296>
f01035f1:	83 fb 0d             	cmp    $0xd,%ebx
f01035f4:	0f 85 a6 fd ff ff    	jne    f01033a0 <readline+0x3c>
			if (echoing)
f01035fa:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01035fe:	74 0d                	je     f010360d <readline+0x2a9>
				cputchar('\n');
f0103600:	83 ec 0c             	sub    $0xc,%esp
f0103603:	6a 0a                	push   $0xa
f0103605:	e8 43 d0 ff ff       	call   f010064d <cputchar>
f010360a:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f010360d:	c6 87 80 85 11 f0 00 	movb   $0x0,-0xfee7a80(%edi)
			return buf;
f0103614:	b8 80 85 11 f0       	mov    $0xf0118580,%eax
		}
	}
}
f0103619:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010361c:	5b                   	pop    %ebx
f010361d:	5e                   	pop    %esi
f010361e:	5f                   	pop    %edi
f010361f:	5d                   	pop    %ebp
f0103620:	c3                   	ret    

f0103621 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103621:	55                   	push   %ebp
f0103622:	89 e5                	mov    %esp,%ebp
f0103624:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103627:	b8 00 00 00 00       	mov    $0x0,%eax
f010362c:	eb 03                	jmp    f0103631 <strlen+0x10>
		n++;
f010362e:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103631:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103635:	75 f7                	jne    f010362e <strlen+0xd>
		n++;
	return n;
}
f0103637:	5d                   	pop    %ebp
f0103638:	c3                   	ret    

f0103639 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103639:	55                   	push   %ebp
f010363a:	89 e5                	mov    %esp,%ebp
f010363c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010363f:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103642:	ba 00 00 00 00       	mov    $0x0,%edx
f0103647:	eb 03                	jmp    f010364c <strnlen+0x13>
		n++;
f0103649:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010364c:	39 c2                	cmp    %eax,%edx
f010364e:	74 08                	je     f0103658 <strnlen+0x1f>
f0103650:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103654:	75 f3                	jne    f0103649 <strnlen+0x10>
f0103656:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103658:	5d                   	pop    %ebp
f0103659:	c3                   	ret    

f010365a <strcpy>:

char *
strcpy(char *dst, const char *src_)
{
f010365a:	55                   	push   %ebp
f010365b:	89 e5                	mov    %esp,%ebp
f010365d:	53                   	push   %ebx
f010365e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103661:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;
	//cprintf("%x\n",dst_);
	const char *src=src_;
	ret = dst;
	while ((*dst++ = *src++) != '\0');
f0103664:	89 c2                	mov    %eax,%edx
f0103666:	83 c2 01             	add    $0x1,%edx
f0103669:	83 c1 01             	add    $0x1,%ecx
f010366c:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103670:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103673:	84 db                	test   %bl,%bl
f0103675:	75 ef                	jne    f0103666 <strcpy+0xc>
		/* do nothing */
		
	return ret;
}
f0103677:	5b                   	pop    %ebx
f0103678:	5d                   	pop    %ebp
f0103679:	c3                   	ret    

f010367a <strcat>:

char *
strcat(char *dst, const char *src)
{
f010367a:	55                   	push   %ebp
f010367b:	89 e5                	mov    %esp,%ebp
f010367d:	53                   	push   %ebx
f010367e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103681:	53                   	push   %ebx
f0103682:	e8 9a ff ff ff       	call   f0103621 <strlen>
f0103687:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010368a:	ff 75 0c             	pushl  0xc(%ebp)
f010368d:	01 d8                	add    %ebx,%eax
f010368f:	50                   	push   %eax
f0103690:	e8 c5 ff ff ff       	call   f010365a <strcpy>
	return dst;
}
f0103695:	89 d8                	mov    %ebx,%eax
f0103697:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010369a:	c9                   	leave  
f010369b:	c3                   	ret    

f010369c <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010369c:	55                   	push   %ebp
f010369d:	89 e5                	mov    %esp,%ebp
f010369f:	56                   	push   %esi
f01036a0:	53                   	push   %ebx
f01036a1:	8b 75 08             	mov    0x8(%ebp),%esi
f01036a4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01036a7:	89 f3                	mov    %esi,%ebx
f01036a9:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01036ac:	89 f2                	mov    %esi,%edx
f01036ae:	eb 0f                	jmp    f01036bf <strncpy+0x23>
		*dst++ = *src;
f01036b0:	83 c2 01             	add    $0x1,%edx
f01036b3:	0f b6 01             	movzbl (%ecx),%eax
f01036b6:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01036b9:	80 39 01             	cmpb   $0x1,(%ecx)
f01036bc:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01036bf:	39 da                	cmp    %ebx,%edx
f01036c1:	75 ed                	jne    f01036b0 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01036c3:	89 f0                	mov    %esi,%eax
f01036c5:	5b                   	pop    %ebx
f01036c6:	5e                   	pop    %esi
f01036c7:	5d                   	pop    %ebp
f01036c8:	c3                   	ret    

f01036c9 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01036c9:	55                   	push   %ebp
f01036ca:	89 e5                	mov    %esp,%ebp
f01036cc:	56                   	push   %esi
f01036cd:	53                   	push   %ebx
f01036ce:	8b 75 08             	mov    0x8(%ebp),%esi
f01036d1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01036d4:	8b 55 10             	mov    0x10(%ebp),%edx
f01036d7:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01036d9:	85 d2                	test   %edx,%edx
f01036db:	74 21                	je     f01036fe <strlcpy+0x35>
f01036dd:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01036e1:	89 f2                	mov    %esi,%edx
f01036e3:	eb 09                	jmp    f01036ee <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01036e5:	83 c2 01             	add    $0x1,%edx
f01036e8:	83 c1 01             	add    $0x1,%ecx
f01036eb:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01036ee:	39 c2                	cmp    %eax,%edx
f01036f0:	74 09                	je     f01036fb <strlcpy+0x32>
f01036f2:	0f b6 19             	movzbl (%ecx),%ebx
f01036f5:	84 db                	test   %bl,%bl
f01036f7:	75 ec                	jne    f01036e5 <strlcpy+0x1c>
f01036f9:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01036fb:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01036fe:	29 f0                	sub    %esi,%eax
}
f0103700:	5b                   	pop    %ebx
f0103701:	5e                   	pop    %esi
f0103702:	5d                   	pop    %ebp
f0103703:	c3                   	ret    

f0103704 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103704:	55                   	push   %ebp
f0103705:	89 e5                	mov    %esp,%ebp
f0103707:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010370a:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010370d:	eb 06                	jmp    f0103715 <strcmp+0x11>
		p++, q++;
f010370f:	83 c1 01             	add    $0x1,%ecx
f0103712:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103715:	0f b6 01             	movzbl (%ecx),%eax
f0103718:	84 c0                	test   %al,%al
f010371a:	74 04                	je     f0103720 <strcmp+0x1c>
f010371c:	3a 02                	cmp    (%edx),%al
f010371e:	74 ef                	je     f010370f <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103720:	0f b6 c0             	movzbl %al,%eax
f0103723:	0f b6 12             	movzbl (%edx),%edx
f0103726:	29 d0                	sub    %edx,%eax
}
f0103728:	5d                   	pop    %ebp
f0103729:	c3                   	ret    

f010372a <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010372a:	55                   	push   %ebp
f010372b:	89 e5                	mov    %esp,%ebp
f010372d:	53                   	push   %ebx
f010372e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103731:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103734:	89 c3                	mov    %eax,%ebx
f0103736:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103739:	eb 06                	jmp    f0103741 <strncmp+0x17>
		n--, p++, q++;
f010373b:	83 c0 01             	add    $0x1,%eax
f010373e:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103741:	39 d8                	cmp    %ebx,%eax
f0103743:	74 15                	je     f010375a <strncmp+0x30>
f0103745:	0f b6 08             	movzbl (%eax),%ecx
f0103748:	84 c9                	test   %cl,%cl
f010374a:	74 04                	je     f0103750 <strncmp+0x26>
f010374c:	3a 0a                	cmp    (%edx),%cl
f010374e:	74 eb                	je     f010373b <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103750:	0f b6 00             	movzbl (%eax),%eax
f0103753:	0f b6 12             	movzbl (%edx),%edx
f0103756:	29 d0                	sub    %edx,%eax
f0103758:	eb 05                	jmp    f010375f <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010375a:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010375f:	5b                   	pop    %ebx
f0103760:	5d                   	pop    %ebp
f0103761:	c3                   	ret    

f0103762 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103762:	55                   	push   %ebp
f0103763:	89 e5                	mov    %esp,%ebp
f0103765:	8b 45 08             	mov    0x8(%ebp),%eax
f0103768:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010376c:	eb 07                	jmp    f0103775 <strchr+0x13>
		if (*s == c)
f010376e:	38 ca                	cmp    %cl,%dl
f0103770:	74 0f                	je     f0103781 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103772:	83 c0 01             	add    $0x1,%eax
f0103775:	0f b6 10             	movzbl (%eax),%edx
f0103778:	84 d2                	test   %dl,%dl
f010377a:	75 f2                	jne    f010376e <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010377c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103781:	5d                   	pop    %ebp
f0103782:	c3                   	ret    

f0103783 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103783:	55                   	push   %ebp
f0103784:	89 e5                	mov    %esp,%ebp
f0103786:	8b 45 08             	mov    0x8(%ebp),%eax
f0103789:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010378d:	eb 03                	jmp    f0103792 <strfind+0xf>
f010378f:	83 c0 01             	add    $0x1,%eax
f0103792:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103795:	38 ca                	cmp    %cl,%dl
f0103797:	74 04                	je     f010379d <strfind+0x1a>
f0103799:	84 d2                	test   %dl,%dl
f010379b:	75 f2                	jne    f010378f <strfind+0xc>
			break;
	return (char *) s;
}
f010379d:	5d                   	pop    %ebp
f010379e:	c3                   	ret    

f010379f <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010379f:	55                   	push   %ebp
f01037a0:	89 e5                	mov    %esp,%ebp
f01037a2:	57                   	push   %edi
f01037a3:	56                   	push   %esi
f01037a4:	53                   	push   %ebx
f01037a5:	8b 7d 08             	mov    0x8(%ebp),%edi
f01037a8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01037ab:	85 c9                	test   %ecx,%ecx
f01037ad:	74 36                	je     f01037e5 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01037af:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01037b5:	75 28                	jne    f01037df <memset+0x40>
f01037b7:	f6 c1 03             	test   $0x3,%cl
f01037ba:	75 23                	jne    f01037df <memset+0x40>
		c &= 0xFF;
f01037bc:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01037c0:	89 d3                	mov    %edx,%ebx
f01037c2:	c1 e3 08             	shl    $0x8,%ebx
f01037c5:	89 d6                	mov    %edx,%esi
f01037c7:	c1 e6 18             	shl    $0x18,%esi
f01037ca:	89 d0                	mov    %edx,%eax
f01037cc:	c1 e0 10             	shl    $0x10,%eax
f01037cf:	09 f0                	or     %esi,%eax
f01037d1:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01037d3:	89 d8                	mov    %ebx,%eax
f01037d5:	09 d0                	or     %edx,%eax
f01037d7:	c1 e9 02             	shr    $0x2,%ecx
f01037da:	fc                   	cld    
f01037db:	f3 ab                	rep stos %eax,%es:(%edi)
f01037dd:	eb 06                	jmp    f01037e5 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01037df:	8b 45 0c             	mov    0xc(%ebp),%eax
f01037e2:	fc                   	cld    
f01037e3:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01037e5:	89 f8                	mov    %edi,%eax
f01037e7:	5b                   	pop    %ebx
f01037e8:	5e                   	pop    %esi
f01037e9:	5f                   	pop    %edi
f01037ea:	5d                   	pop    %ebp
f01037eb:	c3                   	ret    

f01037ec <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01037ec:	55                   	push   %ebp
f01037ed:	89 e5                	mov    %esp,%ebp
f01037ef:	57                   	push   %edi
f01037f0:	56                   	push   %esi
f01037f1:	8b 45 08             	mov    0x8(%ebp),%eax
f01037f4:	8b 75 0c             	mov    0xc(%ebp),%esi
f01037f7:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01037fa:	39 c6                	cmp    %eax,%esi
f01037fc:	73 35                	jae    f0103833 <memmove+0x47>
f01037fe:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103801:	39 d0                	cmp    %edx,%eax
f0103803:	73 2e                	jae    f0103833 <memmove+0x47>
		s += n;
		d += n;
f0103805:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103808:	89 d6                	mov    %edx,%esi
f010380a:	09 fe                	or     %edi,%esi
f010380c:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103812:	75 13                	jne    f0103827 <memmove+0x3b>
f0103814:	f6 c1 03             	test   $0x3,%cl
f0103817:	75 0e                	jne    f0103827 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103819:	83 ef 04             	sub    $0x4,%edi
f010381c:	8d 72 fc             	lea    -0x4(%edx),%esi
f010381f:	c1 e9 02             	shr    $0x2,%ecx
f0103822:	fd                   	std    
f0103823:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103825:	eb 09                	jmp    f0103830 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103827:	83 ef 01             	sub    $0x1,%edi
f010382a:	8d 72 ff             	lea    -0x1(%edx),%esi
f010382d:	fd                   	std    
f010382e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103830:	fc                   	cld    
f0103831:	eb 1d                	jmp    f0103850 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103833:	89 f2                	mov    %esi,%edx
f0103835:	09 c2                	or     %eax,%edx
f0103837:	f6 c2 03             	test   $0x3,%dl
f010383a:	75 0f                	jne    f010384b <memmove+0x5f>
f010383c:	f6 c1 03             	test   $0x3,%cl
f010383f:	75 0a                	jne    f010384b <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103841:	c1 e9 02             	shr    $0x2,%ecx
f0103844:	89 c7                	mov    %eax,%edi
f0103846:	fc                   	cld    
f0103847:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103849:	eb 05                	jmp    f0103850 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010384b:	89 c7                	mov    %eax,%edi
f010384d:	fc                   	cld    
f010384e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103850:	5e                   	pop    %esi
f0103851:	5f                   	pop    %edi
f0103852:	5d                   	pop    %ebp
f0103853:	c3                   	ret    

f0103854 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103854:	55                   	push   %ebp
f0103855:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103857:	ff 75 10             	pushl  0x10(%ebp)
f010385a:	ff 75 0c             	pushl  0xc(%ebp)
f010385d:	ff 75 08             	pushl  0x8(%ebp)
f0103860:	e8 87 ff ff ff       	call   f01037ec <memmove>
}
f0103865:	c9                   	leave  
f0103866:	c3                   	ret    

f0103867 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103867:	55                   	push   %ebp
f0103868:	89 e5                	mov    %esp,%ebp
f010386a:	56                   	push   %esi
f010386b:	53                   	push   %ebx
f010386c:	8b 45 08             	mov    0x8(%ebp),%eax
f010386f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103872:	89 c6                	mov    %eax,%esi
f0103874:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103877:	eb 1a                	jmp    f0103893 <memcmp+0x2c>
		if (*s1 != *s2)
f0103879:	0f b6 08             	movzbl (%eax),%ecx
f010387c:	0f b6 1a             	movzbl (%edx),%ebx
f010387f:	38 d9                	cmp    %bl,%cl
f0103881:	74 0a                	je     f010388d <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103883:	0f b6 c1             	movzbl %cl,%eax
f0103886:	0f b6 db             	movzbl %bl,%ebx
f0103889:	29 d8                	sub    %ebx,%eax
f010388b:	eb 0f                	jmp    f010389c <memcmp+0x35>
		s1++, s2++;
f010388d:	83 c0 01             	add    $0x1,%eax
f0103890:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103893:	39 f0                	cmp    %esi,%eax
f0103895:	75 e2                	jne    f0103879 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103897:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010389c:	5b                   	pop    %ebx
f010389d:	5e                   	pop    %esi
f010389e:	5d                   	pop    %ebp
f010389f:	c3                   	ret    

f01038a0 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01038a0:	55                   	push   %ebp
f01038a1:	89 e5                	mov    %esp,%ebp
f01038a3:	53                   	push   %ebx
f01038a4:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01038a7:	89 c1                	mov    %eax,%ecx
f01038a9:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01038ac:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01038b0:	eb 0a                	jmp    f01038bc <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01038b2:	0f b6 10             	movzbl (%eax),%edx
f01038b5:	39 da                	cmp    %ebx,%edx
f01038b7:	74 07                	je     f01038c0 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01038b9:	83 c0 01             	add    $0x1,%eax
f01038bc:	39 c8                	cmp    %ecx,%eax
f01038be:	72 f2                	jb     f01038b2 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01038c0:	5b                   	pop    %ebx
f01038c1:	5d                   	pop    %ebp
f01038c2:	c3                   	ret    

f01038c3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01038c3:	55                   	push   %ebp
f01038c4:	89 e5                	mov    %esp,%ebp
f01038c6:	57                   	push   %edi
f01038c7:	56                   	push   %esi
f01038c8:	53                   	push   %ebx
f01038c9:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01038cc:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01038cf:	eb 03                	jmp    f01038d4 <strtol+0x11>
		s++;
f01038d1:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01038d4:	0f b6 01             	movzbl (%ecx),%eax
f01038d7:	3c 20                	cmp    $0x20,%al
f01038d9:	74 f6                	je     f01038d1 <strtol+0xe>
f01038db:	3c 09                	cmp    $0x9,%al
f01038dd:	74 f2                	je     f01038d1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01038df:	3c 2b                	cmp    $0x2b,%al
f01038e1:	75 0a                	jne    f01038ed <strtol+0x2a>
		s++;
f01038e3:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01038e6:	bf 00 00 00 00       	mov    $0x0,%edi
f01038eb:	eb 11                	jmp    f01038fe <strtol+0x3b>
f01038ed:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01038f2:	3c 2d                	cmp    $0x2d,%al
f01038f4:	75 08                	jne    f01038fe <strtol+0x3b>
		s++, neg = 1;
f01038f6:	83 c1 01             	add    $0x1,%ecx
f01038f9:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01038fe:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103904:	75 15                	jne    f010391b <strtol+0x58>
f0103906:	80 39 30             	cmpb   $0x30,(%ecx)
f0103909:	75 10                	jne    f010391b <strtol+0x58>
f010390b:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010390f:	75 7c                	jne    f010398d <strtol+0xca>
		s += 2, base = 16;
f0103911:	83 c1 02             	add    $0x2,%ecx
f0103914:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103919:	eb 16                	jmp    f0103931 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010391b:	85 db                	test   %ebx,%ebx
f010391d:	75 12                	jne    f0103931 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010391f:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103924:	80 39 30             	cmpb   $0x30,(%ecx)
f0103927:	75 08                	jne    f0103931 <strtol+0x6e>
		s++, base = 8;
f0103929:	83 c1 01             	add    $0x1,%ecx
f010392c:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103931:	b8 00 00 00 00       	mov    $0x0,%eax
f0103936:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103939:	0f b6 11             	movzbl (%ecx),%edx
f010393c:	8d 72 d0             	lea    -0x30(%edx),%esi
f010393f:	89 f3                	mov    %esi,%ebx
f0103941:	80 fb 09             	cmp    $0x9,%bl
f0103944:	77 08                	ja     f010394e <strtol+0x8b>
			dig = *s - '0';
f0103946:	0f be d2             	movsbl %dl,%edx
f0103949:	83 ea 30             	sub    $0x30,%edx
f010394c:	eb 22                	jmp    f0103970 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f010394e:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103951:	89 f3                	mov    %esi,%ebx
f0103953:	80 fb 19             	cmp    $0x19,%bl
f0103956:	77 08                	ja     f0103960 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103958:	0f be d2             	movsbl %dl,%edx
f010395b:	83 ea 57             	sub    $0x57,%edx
f010395e:	eb 10                	jmp    f0103970 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103960:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103963:	89 f3                	mov    %esi,%ebx
f0103965:	80 fb 19             	cmp    $0x19,%bl
f0103968:	77 16                	ja     f0103980 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010396a:	0f be d2             	movsbl %dl,%edx
f010396d:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103970:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103973:	7d 0b                	jge    f0103980 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103975:	83 c1 01             	add    $0x1,%ecx
f0103978:	0f af 45 10          	imul   0x10(%ebp),%eax
f010397c:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010397e:	eb b9                	jmp    f0103939 <strtol+0x76>

	if (endptr)
f0103980:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103984:	74 0d                	je     f0103993 <strtol+0xd0>
		*endptr = (char *) s;
f0103986:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103989:	89 0e                	mov    %ecx,(%esi)
f010398b:	eb 06                	jmp    f0103993 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010398d:	85 db                	test   %ebx,%ebx
f010398f:	74 98                	je     f0103929 <strtol+0x66>
f0103991:	eb 9e                	jmp    f0103931 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103993:	89 c2                	mov    %eax,%edx
f0103995:	f7 da                	neg    %edx
f0103997:	85 ff                	test   %edi,%edi
f0103999:	0f 45 c2             	cmovne %edx,%eax
}
f010399c:	5b                   	pop    %ebx
f010399d:	5e                   	pop    %esi
f010399e:	5f                   	pop    %edi
f010399f:	5d                   	pop    %ebp
f01039a0:	c3                   	ret    
f01039a1:	66 90                	xchg   %ax,%ax
f01039a3:	66 90                	xchg   %ax,%ax
f01039a5:	66 90                	xchg   %ax,%ax
f01039a7:	66 90                	xchg   %ax,%ax
f01039a9:	66 90                	xchg   %ax,%ax
f01039ab:	66 90                	xchg   %ax,%ax
f01039ad:	66 90                	xchg   %ax,%ax
f01039af:	90                   	nop

f01039b0 <__udivdi3>:
f01039b0:	55                   	push   %ebp
f01039b1:	57                   	push   %edi
f01039b2:	56                   	push   %esi
f01039b3:	53                   	push   %ebx
f01039b4:	83 ec 1c             	sub    $0x1c,%esp
f01039b7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01039bb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01039bf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01039c3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01039c7:	85 f6                	test   %esi,%esi
f01039c9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01039cd:	89 ca                	mov    %ecx,%edx
f01039cf:	89 f8                	mov    %edi,%eax
f01039d1:	75 3d                	jne    f0103a10 <__udivdi3+0x60>
f01039d3:	39 cf                	cmp    %ecx,%edi
f01039d5:	0f 87 c5 00 00 00    	ja     f0103aa0 <__udivdi3+0xf0>
f01039db:	85 ff                	test   %edi,%edi
f01039dd:	89 fd                	mov    %edi,%ebp
f01039df:	75 0b                	jne    f01039ec <__udivdi3+0x3c>
f01039e1:	b8 01 00 00 00       	mov    $0x1,%eax
f01039e6:	31 d2                	xor    %edx,%edx
f01039e8:	f7 f7                	div    %edi
f01039ea:	89 c5                	mov    %eax,%ebp
f01039ec:	89 c8                	mov    %ecx,%eax
f01039ee:	31 d2                	xor    %edx,%edx
f01039f0:	f7 f5                	div    %ebp
f01039f2:	89 c1                	mov    %eax,%ecx
f01039f4:	89 d8                	mov    %ebx,%eax
f01039f6:	89 cf                	mov    %ecx,%edi
f01039f8:	f7 f5                	div    %ebp
f01039fa:	89 c3                	mov    %eax,%ebx
f01039fc:	89 d8                	mov    %ebx,%eax
f01039fe:	89 fa                	mov    %edi,%edx
f0103a00:	83 c4 1c             	add    $0x1c,%esp
f0103a03:	5b                   	pop    %ebx
f0103a04:	5e                   	pop    %esi
f0103a05:	5f                   	pop    %edi
f0103a06:	5d                   	pop    %ebp
f0103a07:	c3                   	ret    
f0103a08:	90                   	nop
f0103a09:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103a10:	39 ce                	cmp    %ecx,%esi
f0103a12:	77 74                	ja     f0103a88 <__udivdi3+0xd8>
f0103a14:	0f bd fe             	bsr    %esi,%edi
f0103a17:	83 f7 1f             	xor    $0x1f,%edi
f0103a1a:	0f 84 98 00 00 00    	je     f0103ab8 <__udivdi3+0x108>
f0103a20:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103a25:	89 f9                	mov    %edi,%ecx
f0103a27:	89 c5                	mov    %eax,%ebp
f0103a29:	29 fb                	sub    %edi,%ebx
f0103a2b:	d3 e6                	shl    %cl,%esi
f0103a2d:	89 d9                	mov    %ebx,%ecx
f0103a2f:	d3 ed                	shr    %cl,%ebp
f0103a31:	89 f9                	mov    %edi,%ecx
f0103a33:	d3 e0                	shl    %cl,%eax
f0103a35:	09 ee                	or     %ebp,%esi
f0103a37:	89 d9                	mov    %ebx,%ecx
f0103a39:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103a3d:	89 d5                	mov    %edx,%ebp
f0103a3f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103a43:	d3 ed                	shr    %cl,%ebp
f0103a45:	89 f9                	mov    %edi,%ecx
f0103a47:	d3 e2                	shl    %cl,%edx
f0103a49:	89 d9                	mov    %ebx,%ecx
f0103a4b:	d3 e8                	shr    %cl,%eax
f0103a4d:	09 c2                	or     %eax,%edx
f0103a4f:	89 d0                	mov    %edx,%eax
f0103a51:	89 ea                	mov    %ebp,%edx
f0103a53:	f7 f6                	div    %esi
f0103a55:	89 d5                	mov    %edx,%ebp
f0103a57:	89 c3                	mov    %eax,%ebx
f0103a59:	f7 64 24 0c          	mull   0xc(%esp)
f0103a5d:	39 d5                	cmp    %edx,%ebp
f0103a5f:	72 10                	jb     f0103a71 <__udivdi3+0xc1>
f0103a61:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103a65:	89 f9                	mov    %edi,%ecx
f0103a67:	d3 e6                	shl    %cl,%esi
f0103a69:	39 c6                	cmp    %eax,%esi
f0103a6b:	73 07                	jae    f0103a74 <__udivdi3+0xc4>
f0103a6d:	39 d5                	cmp    %edx,%ebp
f0103a6f:	75 03                	jne    f0103a74 <__udivdi3+0xc4>
f0103a71:	83 eb 01             	sub    $0x1,%ebx
f0103a74:	31 ff                	xor    %edi,%edi
f0103a76:	89 d8                	mov    %ebx,%eax
f0103a78:	89 fa                	mov    %edi,%edx
f0103a7a:	83 c4 1c             	add    $0x1c,%esp
f0103a7d:	5b                   	pop    %ebx
f0103a7e:	5e                   	pop    %esi
f0103a7f:	5f                   	pop    %edi
f0103a80:	5d                   	pop    %ebp
f0103a81:	c3                   	ret    
f0103a82:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103a88:	31 ff                	xor    %edi,%edi
f0103a8a:	31 db                	xor    %ebx,%ebx
f0103a8c:	89 d8                	mov    %ebx,%eax
f0103a8e:	89 fa                	mov    %edi,%edx
f0103a90:	83 c4 1c             	add    $0x1c,%esp
f0103a93:	5b                   	pop    %ebx
f0103a94:	5e                   	pop    %esi
f0103a95:	5f                   	pop    %edi
f0103a96:	5d                   	pop    %ebp
f0103a97:	c3                   	ret    
f0103a98:	90                   	nop
f0103a99:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103aa0:	89 d8                	mov    %ebx,%eax
f0103aa2:	f7 f7                	div    %edi
f0103aa4:	31 ff                	xor    %edi,%edi
f0103aa6:	89 c3                	mov    %eax,%ebx
f0103aa8:	89 d8                	mov    %ebx,%eax
f0103aaa:	89 fa                	mov    %edi,%edx
f0103aac:	83 c4 1c             	add    $0x1c,%esp
f0103aaf:	5b                   	pop    %ebx
f0103ab0:	5e                   	pop    %esi
f0103ab1:	5f                   	pop    %edi
f0103ab2:	5d                   	pop    %ebp
f0103ab3:	c3                   	ret    
f0103ab4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103ab8:	39 ce                	cmp    %ecx,%esi
f0103aba:	72 0c                	jb     f0103ac8 <__udivdi3+0x118>
f0103abc:	31 db                	xor    %ebx,%ebx
f0103abe:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103ac2:	0f 87 34 ff ff ff    	ja     f01039fc <__udivdi3+0x4c>
f0103ac8:	bb 01 00 00 00       	mov    $0x1,%ebx
f0103acd:	e9 2a ff ff ff       	jmp    f01039fc <__udivdi3+0x4c>
f0103ad2:	66 90                	xchg   %ax,%ax
f0103ad4:	66 90                	xchg   %ax,%ax
f0103ad6:	66 90                	xchg   %ax,%ax
f0103ad8:	66 90                	xchg   %ax,%ax
f0103ada:	66 90                	xchg   %ax,%ax
f0103adc:	66 90                	xchg   %ax,%ax
f0103ade:	66 90                	xchg   %ax,%ax

f0103ae0 <__umoddi3>:
f0103ae0:	55                   	push   %ebp
f0103ae1:	57                   	push   %edi
f0103ae2:	56                   	push   %esi
f0103ae3:	53                   	push   %ebx
f0103ae4:	83 ec 1c             	sub    $0x1c,%esp
f0103ae7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0103aeb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0103aef:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103af3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103af7:	85 d2                	test   %edx,%edx
f0103af9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103afd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103b01:	89 f3                	mov    %esi,%ebx
f0103b03:	89 3c 24             	mov    %edi,(%esp)
f0103b06:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103b0a:	75 1c                	jne    f0103b28 <__umoddi3+0x48>
f0103b0c:	39 f7                	cmp    %esi,%edi
f0103b0e:	76 50                	jbe    f0103b60 <__umoddi3+0x80>
f0103b10:	89 c8                	mov    %ecx,%eax
f0103b12:	89 f2                	mov    %esi,%edx
f0103b14:	f7 f7                	div    %edi
f0103b16:	89 d0                	mov    %edx,%eax
f0103b18:	31 d2                	xor    %edx,%edx
f0103b1a:	83 c4 1c             	add    $0x1c,%esp
f0103b1d:	5b                   	pop    %ebx
f0103b1e:	5e                   	pop    %esi
f0103b1f:	5f                   	pop    %edi
f0103b20:	5d                   	pop    %ebp
f0103b21:	c3                   	ret    
f0103b22:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103b28:	39 f2                	cmp    %esi,%edx
f0103b2a:	89 d0                	mov    %edx,%eax
f0103b2c:	77 52                	ja     f0103b80 <__umoddi3+0xa0>
f0103b2e:	0f bd ea             	bsr    %edx,%ebp
f0103b31:	83 f5 1f             	xor    $0x1f,%ebp
f0103b34:	75 5a                	jne    f0103b90 <__umoddi3+0xb0>
f0103b36:	3b 54 24 04          	cmp    0x4(%esp),%edx
f0103b3a:	0f 82 e0 00 00 00    	jb     f0103c20 <__umoddi3+0x140>
f0103b40:	39 0c 24             	cmp    %ecx,(%esp)
f0103b43:	0f 86 d7 00 00 00    	jbe    f0103c20 <__umoddi3+0x140>
f0103b49:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103b4d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103b51:	83 c4 1c             	add    $0x1c,%esp
f0103b54:	5b                   	pop    %ebx
f0103b55:	5e                   	pop    %esi
f0103b56:	5f                   	pop    %edi
f0103b57:	5d                   	pop    %ebp
f0103b58:	c3                   	ret    
f0103b59:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103b60:	85 ff                	test   %edi,%edi
f0103b62:	89 fd                	mov    %edi,%ebp
f0103b64:	75 0b                	jne    f0103b71 <__umoddi3+0x91>
f0103b66:	b8 01 00 00 00       	mov    $0x1,%eax
f0103b6b:	31 d2                	xor    %edx,%edx
f0103b6d:	f7 f7                	div    %edi
f0103b6f:	89 c5                	mov    %eax,%ebp
f0103b71:	89 f0                	mov    %esi,%eax
f0103b73:	31 d2                	xor    %edx,%edx
f0103b75:	f7 f5                	div    %ebp
f0103b77:	89 c8                	mov    %ecx,%eax
f0103b79:	f7 f5                	div    %ebp
f0103b7b:	89 d0                	mov    %edx,%eax
f0103b7d:	eb 99                	jmp    f0103b18 <__umoddi3+0x38>
f0103b7f:	90                   	nop
f0103b80:	89 c8                	mov    %ecx,%eax
f0103b82:	89 f2                	mov    %esi,%edx
f0103b84:	83 c4 1c             	add    $0x1c,%esp
f0103b87:	5b                   	pop    %ebx
f0103b88:	5e                   	pop    %esi
f0103b89:	5f                   	pop    %edi
f0103b8a:	5d                   	pop    %ebp
f0103b8b:	c3                   	ret    
f0103b8c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103b90:	8b 34 24             	mov    (%esp),%esi
f0103b93:	bf 20 00 00 00       	mov    $0x20,%edi
f0103b98:	89 e9                	mov    %ebp,%ecx
f0103b9a:	29 ef                	sub    %ebp,%edi
f0103b9c:	d3 e0                	shl    %cl,%eax
f0103b9e:	89 f9                	mov    %edi,%ecx
f0103ba0:	89 f2                	mov    %esi,%edx
f0103ba2:	d3 ea                	shr    %cl,%edx
f0103ba4:	89 e9                	mov    %ebp,%ecx
f0103ba6:	09 c2                	or     %eax,%edx
f0103ba8:	89 d8                	mov    %ebx,%eax
f0103baa:	89 14 24             	mov    %edx,(%esp)
f0103bad:	89 f2                	mov    %esi,%edx
f0103baf:	d3 e2                	shl    %cl,%edx
f0103bb1:	89 f9                	mov    %edi,%ecx
f0103bb3:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103bb7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103bbb:	d3 e8                	shr    %cl,%eax
f0103bbd:	89 e9                	mov    %ebp,%ecx
f0103bbf:	89 c6                	mov    %eax,%esi
f0103bc1:	d3 e3                	shl    %cl,%ebx
f0103bc3:	89 f9                	mov    %edi,%ecx
f0103bc5:	89 d0                	mov    %edx,%eax
f0103bc7:	d3 e8                	shr    %cl,%eax
f0103bc9:	89 e9                	mov    %ebp,%ecx
f0103bcb:	09 d8                	or     %ebx,%eax
f0103bcd:	89 d3                	mov    %edx,%ebx
f0103bcf:	89 f2                	mov    %esi,%edx
f0103bd1:	f7 34 24             	divl   (%esp)
f0103bd4:	89 d6                	mov    %edx,%esi
f0103bd6:	d3 e3                	shl    %cl,%ebx
f0103bd8:	f7 64 24 04          	mull   0x4(%esp)
f0103bdc:	39 d6                	cmp    %edx,%esi
f0103bde:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103be2:	89 d1                	mov    %edx,%ecx
f0103be4:	89 c3                	mov    %eax,%ebx
f0103be6:	72 08                	jb     f0103bf0 <__umoddi3+0x110>
f0103be8:	75 11                	jne    f0103bfb <__umoddi3+0x11b>
f0103bea:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0103bee:	73 0b                	jae    f0103bfb <__umoddi3+0x11b>
f0103bf0:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103bf4:	1b 14 24             	sbb    (%esp),%edx
f0103bf7:	89 d1                	mov    %edx,%ecx
f0103bf9:	89 c3                	mov    %eax,%ebx
f0103bfb:	8b 54 24 08          	mov    0x8(%esp),%edx
f0103bff:	29 da                	sub    %ebx,%edx
f0103c01:	19 ce                	sbb    %ecx,%esi
f0103c03:	89 f9                	mov    %edi,%ecx
f0103c05:	89 f0                	mov    %esi,%eax
f0103c07:	d3 e0                	shl    %cl,%eax
f0103c09:	89 e9                	mov    %ebp,%ecx
f0103c0b:	d3 ea                	shr    %cl,%edx
f0103c0d:	89 e9                	mov    %ebp,%ecx
f0103c0f:	d3 ee                	shr    %cl,%esi
f0103c11:	09 d0                	or     %edx,%eax
f0103c13:	89 f2                	mov    %esi,%edx
f0103c15:	83 c4 1c             	add    $0x1c,%esp
f0103c18:	5b                   	pop    %ebx
f0103c19:	5e                   	pop    %esi
f0103c1a:	5f                   	pop    %edi
f0103c1b:	5d                   	pop    %ebp
f0103c1c:	c3                   	ret    
f0103c1d:	8d 76 00             	lea    0x0(%esi),%esi
f0103c20:	29 f9                	sub    %edi,%ecx
f0103c22:	19 d6                	sbb    %edx,%esi
f0103c24:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103c28:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103c2c:	e9 18 ff ff ff       	jmp    f0103b49 <__umoddi3+0x69>
