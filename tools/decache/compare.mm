#include "common.h"
	

static inline int fsize(int fd)
{
	struct stat results;
    if (fstat(fd, &results) == 0)
	{
		if(results.st_mode & S_IFREG)
			return results.st_size;
	}
    return 0;
}


int main(int argc, char** argv)
{
	const char* in_name = NULL;
	const char* section_name = NULL;
	const char* segment_name = NULL;
	const char* compare_name = NULL;
	const char* output_name = NULL;
	
	char ch;
	while((ch = getopt (argc, argv, "i:S:s:o:c:")) != -1)
	{
		switch(ch)
		{
			case 'i':
				if(!in_name)
					in_name = optarg;
				else
					compare_name = optarg;
				break;
			case 's':
				section_name = optarg;
				break;
			case 'S':
				segment_name = optarg;
				break;
			case 'o':
				output_name = optarg;
				break;
			case 'c':
				compare_name = optarg;
				break;
			//case '?':
			default:
				CommonLog("Argument %c = %s", ch, optarg);
		}
	}
	
	
	int fd1 = open(in_name, O_RDONLY);
	int fd2 = open(compare_name, O_RDONLY);
	
	if(fd1 == -1 || fd2 == -1)
		PANIC("Unable to open files");
	int nf1 = fsize(fd1);
	int nf2 = fsize(fd2);

	
	uintptr_t fptr1 = (uintptr_t) mmap(NULL, nf1, PROT_READ, MAP_SHARED, fd1, 0);
	uintptr_t fptr2 = (uintptr_t) mmap(NULL, nf2, PROT_READ, MAP_SHARED, fd2, 0);
	
	mach_header* h1 = (mach_header*) fptr1;
	mach_header* h2 = (mach_header*) fptr2;

	
	section* __t1 = NULL;
	{
		uintptr_t lcptr = fptr1 + sizeof(mach_header);
		for(int i=0; i<h1->ncmds && !__t1; i++)
		{
			int cmd = ((load_command*)lcptr)->cmd;
			//CommonLog("Command %p", cmd);
			if(cmd == LC_SEGMENT)
			{
				segment_command* seg = (segment_command*) lcptr;
				if(!segment_name || !strncmp(seg->segname, segment_name, 16))
				{
					int nsects = seg->nsects;
					if(nsects)
					{
						section* sects = (section*) (lcptr + sizeof(segment_command));
						for(int j=0; j<nsects; j++)
						{
							if(!strncmp(sects[j].sectname, section_name, 16))
							{
								__t1 = &sects[j];
							}
						}
					}
				}
			}
			lcptr += ((load_command*)lcptr)->cmdsize;
		}
	}

	section* __t2 = NULL;
	{
		uintptr_t lcptr = fptr2 + sizeof(mach_header);
		for(int i=0; i<h2->ncmds && !__t2; i++)
		{
			int cmd = ((load_command*)lcptr)->cmd;
			//CommonLog("Command %p", cmd);
			if(cmd == LC_SEGMENT)
			{
				segment_command* seg = (segment_command*) lcptr;
				if(!segment_name || !strncmp(seg->segname, segment_name, 16))
				{
					int nsects = seg->nsects;
					if(nsects)
					{
						section* sects = (section*) (lcptr + sizeof(segment_command));
						for(int j=0; j<nsects; j++)
						{
							if(!strncmp(sects[j].sectname, section_name, 16))
							{
								__t2 = &sects[j];
							}
						}
					}
				}
			}
			lcptr += ((load_command*)lcptr)->cmdsize;
		}
	}
	if(__t1 && __t2)
	{
		uint32_t *p1 = (uint32_t*) (fptr1 + __t1->offset);
		uint32_t *p2 = (uint32_t*) (fptr2 + __t2->offset);
		int np = __t1->size;
		if(np != __t2->size)
			PANIC("Section size mismatch!");
		int mis = 0;
		for(int i=0; i<np/4 && mis < 40; i++)
		{
			if(p1[i] != p2[i])
			{
				CommonLog("Mismatch at %x (%08x!=%08x)", i*4 + __t1->offset, p1[i], p2[i]);
				mis ++;
			}
		}
		if(mis==40)
		{
			CommonLog("mismatch limit reached");
		}
		if(!mis)
			CommonLog("No mismatches detected!");
	}
	else
	{
		CommonLog("Sections not found.");
	}
	
}