// Simple command-line kernel monitor useful for
// controlling the kernel and exploring the system interactively.

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/assert.h>
#include <inc/x86.h>

#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/kdebug.h>
#include <kern/pmap.h>
#define CMDBUF_SIZE	80	// enough for one VGA text line
#define MAX_CMD_SIZE 100
struct Command {
	const char *name;
	const char *desc;
	// return -1 to force monitor to exit
	int (*func)(int argc, char** argv, struct Trapframe* tf);
};

static struct Command commands[] = {
	{ "help", "Display this list of commands", mon_help },
	{ "kerninfo", "Display information about the kernel", mon_kerninfo },
	{ "backtrace", "backtrace the file", mon_backtrace },
	{ "lab2_check", "check the exercise in lab 2", check_lab2 },
	{ "showmappings", "show mappings of va to pa, format: cmd va pa", showmappings },
	{ "update_page_perm", "change page permissions, format: cmd va pa", update_page_perm },
	
};
#define NCOMMANDS (sizeof(commands)/sizeof(commands[0]))

/***** Implementations of basic kernel monitor commands *****/
int check_lab2(){
mem_init();	
return 0;
}
int showmappings(int argc, char **argv, struct Trapframe *tf){
	uintptr_t va_start=(uintptr_t) strtol(argv[1],0,16);
	uintptr_t va_end=(uintptr_t) strtol(argv[2],0,16);
		//cprintf("%x\n",va_start);
	struct PageInfo* page;
	physaddr_t pa;
	pte_t* pte;
	uintptr_t va_current;
	va_start=ROUNDDOWN(va_start,PGSIZE);
	va_end=ROUNDUP(va_end,PGSIZE);
	int n= (va_end-va_start)/PGSIZE;
	cprintf("mapping           permissions\n");
	for(int i=0;i<n;i++){
		va_current=va_start+i*PGSIZE;
		page=page_lookup(kern_pgdir,(void*)va_current,&pte);
		if(page==NULL){
			cprintf("%08x->unallocated\n",va_current);
			continue;}
		pa=page2pa(page);
		cprintf("%08x->%08x       ",va_current,pa);
		if(*pte& PTE_P){cprintf("PTE_P ");}
		if(*pte& PTE_U){cprintf("PTE_U ");}
		if(*pte& PTE_W){cprintf("PTE_W ");}
		cprintf("\n");
	}
	
	return 0;
}
int update_page_perm(int argc, char **argv, struct Trapframe *tf){
	
	uintptr_t va_start=(uintptr_t) strtol(argv[1],0,16);
	uintptr_t va_end=(uintptr_t) strtol(argv[2],0,16);
	uint32_t perm=(uint32_t) strtol(argv[3],0,16);
	pte_t* pte;
	uintptr_t va_current;
	va_start=ROUNDDOWN(va_start,PGSIZE);
	va_end=ROUNDUP(va_end,PGSIZE);
	int n= (va_end-va_start)/PGSIZE;
		for(int i=0;i<n;i++){
		va_current=va_start+i*PGSIZE;
		pte=pgdir_walk(kern_pgdir, (void*)va_current, false);
		if(pte==NULL){
			cprintf("update failed! page mapped at va %08x is unallocated\n",va_current);
			}
			else{
				pte[0]=(pte[0]&(~0xFFF))|perm;
			}
	}
	
	return 0;
}
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	cprintf("Stack backtrace:\n");
	uint32_t ebp=0xffffffff;
	//cprintf("%x\n",read_ebp());
	while(ebp!=0){
	if(ebp==0xffffffff){
		ebp=read_ebp();
	}
		else{
		ebp=*(int*)ebp;
		}
		uint32_t eip=*(int*)(ebp+4);
		uint32_t arg1=*(int*)(ebp+8);
		uint32_t arg2=*(int*)(ebp+12);
		uint32_t arg3=*(int*)(ebp+16);
		uint32_t arg4=*(int*)(ebp+20);
		uint32_t arg5=*(int*)(ebp+24);
		cprintf("ebp %x  eip %x  args %08x %08x %08x %08x %08x\n",ebp,eip,arg1,arg2,arg3,arg4,arg5);
		struct Eipdebuginfo info_={"<unknown>",0,"<unknown>",9,0,0};
		struct Eipdebuginfo* info= &info_;
		debuginfo_eip(eip,info);
		//*(p)='\0';
		cprintf("       %s:%d: ",info->eip_file,info->eip_line );
		cprintf("%.*s",info->eip_fn_namelen,info->eip_fn_name);
		cprintf("+%d\n",info->eip_fn_narg);
	}
	return 0;
}



/***** Kernel monitor command interpreter *****/

#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
	return 0;
}

void
monitor(struct Trapframe *tf)
{
	char* cmd_history[MAX_CMD_SIZE];
	for(int i=0;i<MAX_CMD_SIZE;i++){
		cmd_history[i]=(char*)(i*100+KERNBASE);
	}
	int current_cmd=0;
	char *buf;
	//char buf_copy[MAX_CMD_SIZE];
	//char* buf_p=buf_copy;
	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");
    cprintf("x=%d y=%d", 3);
cprintf("\n");
check_lab2();
	while (1) {
		buf = readline("K> ",cmd_history,current_cmd);
		//cprintf("current_cmd%x",cmd_history[current_cmd]);
		strcpy(cmd_history[current_cmd],buf);
		//cmd_history[current_cmd]=buf;
		current_cmd++;
		//cprintf("command[0],%x\n",cmd_history[0]);
		//cprintf("%s",buf_copy);
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
