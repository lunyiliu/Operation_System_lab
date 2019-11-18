#include <inc/stdio.h>
#include <inc/error.h>
#include <inc/string.h>
#define BUFLEN 1024
static char buf[BUFLEN];
static int flag=0;
char *
readline(const char *prompt,char** cmd_history, int current_cmd)
{	
	/*
	for(int i=0;i<current_cmd;i++){
		cprintf("%s ",cmd_history[i]);
	}
	*/
	int i, c, echoing;
	int count=current_cmd;
	if (prompt != NULL)
		//if(prompt=='[A'){
		//cprintf("111");}
	//else{
		cprintf("%s", prompt);
//}

	i = 0;
	echoing = iscons(0);
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
			if (echoing)
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
			if(c=='['&&flag==0){flag=1;continue;}
			if(c=='A'&&flag==1){
				flag=0;
				if(count<=0)continue;
				
				if(count<current_cmd){
					int back_len=strlen(cmd_history[count]);
					for(int j=0;j<back_len;j++){
						cputchar('\b');
						i--;
					}
				}
				
				char* cmd_string=cmd_history[--count];
				cprintf("%s",cmd_string);
				for(int j=0;j<strlen(cmd_string);j++){
					buf[i++] = cmd_string[j];
				}
			
				continue;
			}
			if(c=='B'&&flag==1){
				flag=0;
				if(count<0)continue;
				if(count>=current_cmd)continue;
				int back_len=strlen(cmd_history[count]);
					for(int j=0;j<back_len;j++){
						cputchar('\b');
						i--;
					}
				char* cmd_string=cmd_history[++count];
				cprintf("%s",cmd_string);
				for(int j=0;j<strlen(cmd_string);j++){
					buf[i++] = cmd_string[j];
				}
				continue;
			}
			if(flag==1){flag=0;}
			if (echoing)
				cputchar(c);
			buf[i++] = c;
		} else if (c == '\n' || c == '\r') {
			if (echoing)
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}

