// implement fork from user space

#include <inc/string.h>
#include <inc/lib.h>

// PTE_COW marks copy-on-write page table entries.
// It is one of the bits explicitly allocated to user processes (PTE_AVAIL).
#define PTE_COW		0x800

//
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	int r;
	//cprintf("111\n");
	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).
	
	// LAB 4: Your code here.
		if(!((err&FEC_WR)&&(uvpt[PGNUM(addr)] & PTE_COW))){
			panic("pgfault handler in fork(): not a write, or not to a copy-on-write page");
		}
	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.
	//   No need to explicitly delete the old page's mapping.

	// LAB 4: Your code here.
	// sys_page_alloc(envid_t envid, void *va, int perm)
	// sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
	// sys_page_unmap(envid_t envid, void *va)
	addr=ROUNDDOWN(addr,PGSIZE);
	if((r=sys_page_alloc(0, PFTEMP, PTE_W|PTE_P|PTE_U))<0)
		{
			panic("pgfault handler in fork(): alloc at va %x: %e", addr, r); 
		}
	
	memcpy(PFTEMP,addr,PGSIZE);
	if((r=sys_page_map(0, PFTEMP, 0,addr, PTE_W|PTE_P|PTE_U))<0)
		{
			panic("pgfault handler in fork(): map at va %x: %e", addr, r); 
		}
	if((r=sys_page_unmap(0, PFTEMP))<0)
		{
			panic("pgfault handler in fork(): unmap at va %x: %e", addr, r); 
		}
	//panic("pgfault not implemented");
}

//
// Map our virtual page pn (address pn*PGSIZE) into the target envid
// at the same virtual address.  If the page is writable or copy-on-write,
// the new mapping must be created copy-on-write, and then our mapping must be
// marked copy-on-write as well.  (Exercise: Why do we need to mark ours
// copy-on-write again if it was already copy-on-write at the beginning of
// this function?)
//
// Returns: 0 on success, < 0 on error.
// It is also OK to panic on error.
//
static int
duppage(envid_t envid, unsigned pn)
{
	int r;
	uintptr_t va= pn*PGSIZE;
	if((uvpt[pn]&PTE_W)||(uvpt[pn]&PTE_COW)){
		if((r=sys_page_map(0, (void*)va, envid, (void*)va, PTE_COW|PTE_P|PTE_U))<0)
		{
			panic("duppage,1, at va %x: %e", va, r); 
		}
		
		if((r=sys_page_map(0, (void*)va, 0, (void*)va, PTE_COW|PTE_P|PTE_U))<0)
		{
			panic("duppage,2, at va %x: %e", va, r); 
		}
		
	}
	else{
		sys_page_map(0, (void*)va, envid, (void*)va, PTE_P|PTE_U);
	}
	// LAB 4: Your code here.
	//panic("duppage not implemented");
	return 0;
}

//
// User-level fork with copy-on-write.
// Set up our page fault handler appropriately.
// Create a child.
// Copy our address space and page fault handler setup to the child.
// Then mark the child as runnable and return.
//
// Returns: child's envid to the parent, 0 to the child, < 0 on error.
// It is also OK to panic on error.
//
// Hint:
//   Use uvpd, uvpt, and duppage.
//   Remember to fix "thisenv" in the child process.
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
	// LAB 4: Your code here.
	
	envid_t envid;
	uintptr_t addr;
	int r;
	set_pgfault_handler(pgfault);
	// Allocate a new child environment.
	// The kernel will initialize it with a copy of our register state,
	// so that the child will appear to have called sys_exofork() too -
	// except that in the child, this "fake" call to sys_exofork()
	// will return 0 instead of the envid of the child.
	envid = sys_exofork();
	//cprintf("envid: %x\n", envid);
	if (envid < 0)
		panic("sys_exofork: %e", envid);
	if (envid == 0) {
		// We're the child.
		// The copied value of the global variable 'thisenv'
		// is no longer valid (it refers to the parent!).
		// Fix it and return 0.
		thisenv = &envs[ENVX(sys_getenvid())];
		return 0;
	}

	//cprintf("parent\n");
	// We're the parent.
	// Eagerly copy our entire address space into the child.
	// This is NOT what you should do in your fork implementation.
	for (addr = 0; addr < USTACKTOP; addr += PGSIZE)
	{
		if ((uvpd[PDX(addr)] & PTE_P) && (uvpt[PGNUM(addr)] & PTE_P)
			&& (uvpt[PGNUM(addr)] & PTE_U)) {
			duppage(envid, PGNUM(addr));
		}
	}
	extern void _pgfault_upcall();
	sys_page_alloc(envid, (void*)UXSTACKTOP-PGSIZE, PTE_SYSCALL);
	sys_env_set_pgfault_upcall(envid,_pgfault_upcall );

	// Start the child environment running
	if ((r = sys_env_set_status(envid, ENV_RUNNABLE)) < 0)
		panic("sys_env_set_status: %e", r);

	return envid;
	//panic("fork not implemented");
}

// Challenge!
int
sfork(void)
{
	panic("sfork not implemented");
	return -E_INVAL;
}
