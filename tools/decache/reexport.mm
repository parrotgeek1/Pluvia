
/*
#include <stdio.h>
#include <sys/stat.h>
#include <map>

#include <sys/mman.h>
#include <fcntl.h>

#include <mach-o/loader.h>
#include <mach-o/nlist.h>
*/

//#include <fstream.h>

#include "common.h"

#include "reexport.h"

int fsize(const char *fname)
{
    struct stat results;
    if (lstat(fname, &results) == 0)
	{
		if(results.st_mode & S_IFREG)
			return results.st_size;
	}
    return 0;
}

/*
struct exported_sym
{
	uint32_t flags;	//
	uint32_t stub;
	uint32_t resolver;
	uint32_t ordinal;
	char name[0x20];
	char reexport[0x20];
	
	int nbase;
};
*/

uint32_t append_uleb(char* p, uint32_t val)
{
	if(!val)
	{
		p[0] = 0;
		return 1;
	}
	int i=0;
	
	for(; val; i++)
	{
		uint8_t base = val & 0x7F;
		val = val >> 7;
		base |= (val ? 0x80 : 0);
		p[i] = base;
	}
	return i;
}


uint32_t append_sleb(char* p, int32_t val)
{
	if(!val)
	{
		p[0] = 0;
		return 1;
	}
	int i=0;
	
	bool next = 1;
	
	for(; next; i++)
	{
		uint8_t base = val & 0x7F;
		val = val >> 7;
		
		next = !((val==-1) || (val == 0 && (~base & 0x40)));
		
		base |= (next ? 0x80 : 0);
		p[i] = base;
	}
	
	
	return i;
}


static uintptr_t read_uleb128(const uint8_t*& p, const uint8_t* end)
{
	uint64_t result = 0;
	int		 bit = 0;
	do {

		uint64_t slice = *p & 0x7f;

		result |= (slice << bit);
		bit += 7;
	} while (*p++ & 0x80);
	return result;
}

/*
static intptr_t read_sleb128(const uint8_t*& p, const uint8_t* end)
{
	int64_t result = 0;
	int bit = 0;
	uint8_t byte;
	do {
		byte = *p++;
		result |= ((byte & 0x7f) << bit);
		bit += 7;
	} while (byte & 0x80);
	// sign extend negative numbers
	if ( (byte & 0x40) != 0 )
		result |= (-1LL) << bit;
	return result;
}
*/

/*
struct exported_node
{
	char base[0x80];
	exported_node* child;
	exported_node* sibling;
	
	int offs;
	int nterm;
	char terminal[0x80];
};
*/

//#define EXPORT_SYMBOL_FLAGS_KIND_REGULAR			0x00
//#define EXPORT_SYMBOL_FLAGS_REEXPORT				0x08
//#define EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER			0x10

/*
void print_exported_node(exported_node* node, char* strbuf, int tabdepth = 0)
{
	int nStr = strlen(node->base);
	memcpy(&strbuf[tabdepth], node->base, nStr+1);
	
	if(node->nterm)
	{
		fprintf(stdout, "Node %s: ", strbuf, node->base);
		
		for(int i=0; i<node->nterm; i++)
		{
			fprintf(stdout, "%02x", ((uint8_t*)node->terminal)[i]);
		}
		fprintf(stdout, "\n");
	}
	
	if(node->child)
	{
		print_exported_node(node->child, strbuf, tabdepth + nStr);
	}
	if(node->sibling)
	{
		print_exported_node(node->sibling, strbuf, tabdepth);
	}
}
*/

int flatten_exported_node(char* buf, exported_node* node, int base_off = 0)
{
	int offset = base_off;
	int nterm = node->nterm;
	offset += append_uleb(&buf[offset], nterm);
	if(nterm)
	{
		memcpy(&buf[offset], node->terminal, nterm);
		offset += nterm;
	}
	
	int nchild = 0;
	int strlen_child = 0;
	
	exported_node* child = node->child;
	
//	CommonLog("child = %p %d", node->child, base_off);
	
	for(; child; child = child->sibling)
	{
//		CommonLog("child = %p %p %p %p", node->child, child, child->base, child->sibling);
		strlen_child += strlen(child->base);
		nchild++;
	}
	
	offset += append_uleb(&buf[offset], nchild);
	
	if(!nchild)
		return offset;
	
	int next_base_off = offset + strlen_child + nchild * (1 + 3); // null + 2-char uleb assumption
	
	child = node->child;
	for(; child; child = child->sibling)
	{
		int nStr = strlen(child->base);
		memcpy(&buf[offset], child->base, nStr+1);
		offset += nStr+1;
		
		offset += append_uleb(&buf[offset], next_base_off);
		next_base_off = flatten_exported_node(buf, child, next_base_off);
	}
	return next_base_off;
}



void scan_export_tree(
		const uint8_t *start, int len, char* strbuf,
		void (*callback)(exported_node* node, uintptr_t context), uintptr_t context,
		const uint32_t coffset, const uint8_t tabdepth)
//void print_export_commands(const uint8_t *start, int len, char* strbuf, const uint32_t coffset = 0, const uint8_t tabdepth=0)
{
	//CommonLog("Context = %p", context);
	const uint8_t* p = &start[coffset];
	const uint8_t* end = &start[len];

	uint32_t terminalSize = *p++;
	if ( terminalSize > 127 )
	{
		--p;
		terminalSize = read_uleb128(p, end);
	}
	if(terminalSize)
	{
		const uint8_t* p2 = p;
		const uint32_t flags = read_uleb128(p2, end);
		//fprintf(stdout, "termsize=%08x flags=%08x (%08x %08x)\n", terminalSize, flags, p-start, coffset);
		
		
		exported_node *node = (exported_node*) malloc(sizeof(exported_node));
		memset(node, 0, sizeof(exported_node));
		
		memcpy(node->base, strbuf, strlen(strbuf)+1);
		
		node->flags = flags;
		
		
		if(flags & EXPORT_SYMBOL_FLAGS_REEXPORT)
		{
			node->ordinal = read_uleb128(p2, end);
			memcpy(node->reexport, p2, strlen((const char*)p2)+1);
		}
		else if(flags & EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER)
		{
			node->stub = read_uleb128(p2, end);
			node->resolver = read_uleb128(p2, end);
		}
		else
		{
			node->stub = read_uleb128(p2, end);

			if( (flags & EXPORT_SYMBOL_FLAGS_KIND_MASK ) == EXPORT_SYMBOL_FLAGS_KIND_REGULAR)
			{
				
			}
			else if( (flags & EXPORT_SYMBOL_FLAGS_KIND_MASK ) == EXPORT_SYMBOL_FLAGS_KIND_THREAD_LOCAL)
			{
				
			}
			else
			{
				
			}
		}
		//print_export_commands_sub(node, NULL);
		
		
		/*
		if((flags & EXPORT_SYMBOL_FLAGS_KIND_MASK) == EXPORT_SYMBOL_FLAGS_KIND_REGULAR)
		{
			if(flags & EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER)
			{
				node->stub = read_uleb128(p2, end);
				node->resolver = read_uleb128(p2, end);
			//	fprintf(stdout, ".EXPORT_RESOLVER %08x %08x %s\n", stub, resolver, strbuf);
			}
			else if(flags & EXPORT_SYMBOL_FLAGS_REEXPORT)
			{
				node->ordinal = read_uleb128(p2, end);
				memcpy(node->reexport, p2, strlen((const char*)p2)+1);
			//	fprintf(stdout, ".EXPORT_REEXPORT %02x %s %s\n", ordinal, strbuf, p2);
			}
			else
			{
				node->stub = read_uleb128(p2, end);
			//	fprintf(stdout, ".EXPORT %08x %s\n", stub, strbuf);
			}
		}
		else
		{
			//flags = EXPORT_SYMBOL_FLAGS_KIND_REGULAR;
			//node->flags = EXPORT_SYMBOL_FLAGS_KIND_REGULAR;
			//node->stub = read_uleb128(p2, end);

			//fprintf(stderr, "cannot handle export style %08x.  faking\n", flags);
			PANIC("cannot handle export style %08x", flags);
		}
		*/
		//CommonLog("rContext = %p", context);

		callback(node, context);
		
		
		/*
		if((flags & EXPORT_SYMBOL_FLAGS_KIND_MASK) == EXPORT_SYMBOL_FLAGS_KIND_REGULAR)
		{
			if(flags & EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER)
			{
				const uint32_t stub = read_uleb128(p2, end);
				const uint32_t resolver = read_uleb128(p2, end);
				fprintf(stdout, ".EXPORT_RESOLVER %08x %08x %s\n", stub, resolver, strbuf);
			}
			else if(flags & EXPORT_SYMBOL_FLAGS_REEXPORT)
			{
				const uint32_t ordinal = read_uleb128(p2, end);
				fprintf(stdout, ".EXPORT_REEXPORT %02x %s %s\n", ordinal, strbuf, p2);
			}
			else
			{
				const uint32_t stub = read_uleb128(p2, end);
				fprintf(stdout, ".EXPORT %08x %s\n", stub, strbuf);
			}
		}
		
		else
		{
			fprintf(stderr, "cannot handle export style %08x\n", flags);
			exit(1);
		}*/
		//return;
	}
		
	const uint8_t* children = p + terminalSize;
	
	uint8_t childrenRemaining = *children++;
	//printf("children: %d\n", childrenRemaining);
	
	p = children;
	uint32_t nodeOffset = 0;
	for (; childrenRemaining > 0; --childrenRemaining)
	{
		// scan past string
		char* str = (char*)p;
		while(*p != '\0')
			++p;
		++p;
		
		// append string to buffer.
		int nStr = strlen(str);
		memcpy(&strbuf[tabdepth], str, nStr+1);
		
		// recurse
		nodeOffset = read_uleb128(p, end);
		if(nodeOffset < coffset)
			continue;
		//fprintf(stdout, "# recurse %s %p\n", str, nodeOffset);
		scan_export_tree(start, len, strbuf, callback, context, nodeOffset, tabdepth+nStr);
		
	}	
}

void describe_node(exported_node* node)
{
	if(node->flags & EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER)
	{
		fprintf(stdout, ".EXPORT_RESOLVER %08x %08x %s\n", node->stub, node->resolver, node->base);
	}
	else if(node->flags & EXPORT_SYMBOL_FLAGS_REEXPORT)
	{
		fprintf(stdout, ".EXPORT_REEXPORT %02x %s %s\n", node->ordinal, node->base, node->reexport);
	}
	else
	{
		if( (node->flags & EXPORT_SYMBOL_FLAGS_KIND_MASK ) == EXPORT_SYMBOL_FLAGS_KIND_REGULAR)
		{
			fprintf(stdout, ".EXPORT %08x %s\n", node->stub, node->base);
		}
		else if( (node->flags & EXPORT_SYMBOL_FLAGS_KIND_MASK ) == EXPORT_SYMBOL_FLAGS_KIND_THREAD_LOCAL)
		{
			fprintf(stdout, ".EXPORT(LOCAL) %08x %s\n", node->stub, node->base);
		}
		else
		{
			fprintf(stdout, ".EXPORT(FLAGS=%02x) %08x %s\n", node->flags, node->stub, node->base);	
		}
		
	}
}

void print_export_commands_sub(exported_node* node, uintptr_t context)
{
	describe_node(node);
	// WHAT THE F****
	free(node);
}


void export_construct_terminal(exported_node* node)
{
	if(node->flags & EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER)
	{
		node->nterm = 0;
		node->nterm += append_uleb(&(node->terminal[node->nterm]), node->flags);//EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER);
		node->nterm += append_uleb(&(node->terminal[node->nterm]), node->stub);
		node->nterm += append_uleb(&(node->terminal[node->nterm]), node->resolver);
	}
	else if(node->flags & EXPORT_SYMBOL_FLAGS_REEXPORT)
	{
		node->nterm = 0;
		node->nterm += append_uleb(&(node->terminal[node->nterm]), node->flags);//EXPORT_SYMBOL_FLAGS_REEXPORT);
		node->nterm += append_uleb(&(node->terminal[node->nterm]), node->ordinal);
		
		int nReexport = strlen(node->reexport);
		memcpy(&(node->terminal[node->nterm]), node->reexport, nReexport);
		node->nterm +=nReexport;
	}
	else
	{
		node->nterm = 0;
		node->nterm += append_uleb(&(node->terminal[node->nterm]), node->flags);//EXPORT_SYMBOL_FLAGS_KIND_REGULAR);
		node->nterm += append_uleb(&(node->terminal[node->nterm]), node->stub);
	}
}


void print_export_commands(const uintptr_t start, int len)
{
	CommonLog("Scanning... %d", len);
	char strbuf[0x200];
	
	scan_export_tree((uint8_t*) start, len, strbuf, print_export_commands_sub, NULL);

}

void collapse_nodes(exported_node* node)
{
	if(!node)
		return;
	collapse_nodes(node->child);
	collapse_nodes(node->sibling);
	free(node);
}


/*
int compress_export(char* obuf, char* ibuf, int nif);
	take a linkedit decompression and regenerate the export table
	
	return = export length
	
	obuf = export destination
	ibuf = source for commands
	nif = command buffer size
*/



void export_add_node(exported_node** _basenode, exported_node* node)
{
	exported_node* basenode = *(_basenode);
	
	
	
	/*
	fprintf(stdout, "Node %s: ", node->base);
	for(int i=0; i<node->nterm; i++)
	{
		fprintf(stdout, "%02x", ((uint8_t*)node->terminal)[i]);
	}
	fprintf(stdout, "\n");
	*/
	
	exported_node* tnode = basenode;
	int symoff = 0;
	
	//CommonLog("node = %p sibling %p", node, node->sibling);
	
	if(!tnode)
	{
		basenode = node;
		*_basenode = basenode;

		node = NULL;
		return;
	}
	
	//fprintf(stderr, "fail!\n");
	
	while(tnode)
	{
		int j=0;
		for(; tnode->base[j] && tnode->base[j]==node->base[j+symoff]; j++)
		{}
		if(j==0)
		{
			// no match; look for sibling
			exported_node* sibling = tnode->sibling;
			if(sibling)
			{
				// check sibling
				tnode = sibling;
			}
			else
			{
				// we are the sibling
				tnode->sibling = node;
				//CommonLog("%p Added sibling %p", tnode, tnode->sibling);
				tnode = NULL;
			}
		}
		else if(!tnode->base[j])
		{
			
			
			// we either are the node or are a child node
			if(node->base[j+symoff])
			{
				// we need to be a child
				symoff += j;
				
				exported_node* child = tnode->child;
				if(child)
				{
					// check child
					tnode = child;
				}
				else
				{
					// we are the child
					tnode->child = node;
					tnode = NULL;
				}
			}
			else
			{
				// we are the node.  copy nterm, terminal over
				tnode->nterm = node->nterm;
				memcpy(tnode->terminal, node->terminal, 0x200);
				tnode = NULL;
				node = NULL;
			}
		}
		else
		{
			// partial node match.
			if(node->base[j+symoff])
			{
				// we need to split the node.  start by cloning the original node
				exported_node* cloned_node = new exported_node;
				memcpy(cloned_node, tnode, sizeof(exported_node));
				// massage the original node
				tnode->nterm = 0;		// kill the terminal
				tnode->base[j] = 0;		//  chop the string
				tnode->child = cloned_node; // set the child
				// now massage the child node
			
				memmove(cloned_node->base, &(cloned_node->base[j]), 0x200-j); // scoot over the string
				cloned_node->sibling = node;
				//CommonLog("%p added sibling %p", cloned_node, cloned_node->sibling);

				tnode = NULL;
				
				symoff += j;
				
			}
			else
			{
				// we need the current node to be our child.  First, shorten up the strings
				
				memmove(tnode->base, &(tnode->base[j]), 0x200-j); // scoot over the string
				
				//swap via a temporary node
				exported_node tmp_node;
				memcpy(&tmp_node, tnode, sizeof(exported_node));
				memcpy(tnode, node, sizeof(exported_node));
				memcpy(node, &tmp_node, sizeof(exported_node));
				
				// link nodes
				tnode->child = node;
				
				
				node = tnode; // for cleanup
				tnode = NULL;
			}
		}
		
		
	}
	
	/*
	if( (uintptr_t)( (*_basenode)->child) == (uintptr_t) 0x1c)
	{
		PANIC("Basenode messup\n");
	}
	CommonLog("BN %p\n", ( (*_basenode)->child));
	*/
	
	//fprintf(stderr, "fail!2\n");
	
	
	if(node && symoff)
	{
	//	fprintf(stderr, "%s %x\n", node->base, (uint32_t) strlen(node->base));
		memmove(node->base, &(node->base[symoff]), 0x200-symoff); // scoot over the string
	}
}


int export_finalize(char* obuf, exported_node* basenode)
{
	if(!basenode)
	{
		CommonLog("WARNING: No export trie!");
		return 0;
	}
	if(basenode->base[0])
	{
		exported_node* node = basenode;
		basenode = (exported_node*) malloc(sizeof(exported_node));
		memset(basenode, 0, sizeof(exported_node));
		basenode->child = node;
	}
	

	//LINE();
	
	int length = flatten_exported_node(obuf, basenode);

	//LINE();
	
	collapse_nodes(basenode);

	//LINE();
	
	return length;
}


int compress_export_str(char* obuf, char* ibuf, int nif)
{
	int exported_syms = 0;
	exported_node* basenode = NULL;
	
	for(int i=0; i < nif; i++)
	{
		int lastI = i;
		for(; ibuf[i]!='\n' && i < nif; i++)
		{}
		
		exported_node *node = 0;
		
		if(!strncmp(&ibuf[lastI], ".EXPORT ", 8))
		{
			exported_syms++;
			
			node = (exported_node*) malloc(sizeof(exported_node));
			memset(node, 0, sizeof(exported_node));
			
			uint32_t stub;
			sscanf(&ibuf[lastI], ".EXPORT %x %s", &stub, node->base);
			
			node->nterm = 0;
			node->nterm += append_uleb(&(node->terminal[node->nterm]), EXPORT_SYMBOL_FLAGS_KIND_REGULAR);
			node->nterm += append_uleb(&(node->terminal[node->nterm]), stub);
			
		//	fprintf(stdout, "%.*s\n", i-lastI, &ibuf[lastI]);
		}
		else if(!strncmp(&ibuf[lastI], ".EXPORT_RESOLVER ", 17))
		{
			exported_syms++;
			
			node = (exported_node*) malloc(sizeof(exported_node));
			memset(node, 0, sizeof(exported_node));
			
			uint32_t stub;
			uint32_t resolver;
			sscanf(&ibuf[lastI], ".EXPORT_RESOLVER %x %x %s", &stub, &resolver, node->base);
			
			node->nterm = 0;
			node->nterm += append_uleb(&(node->terminal[node->nterm]), EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER);
			node->nterm += append_uleb(&(node->terminal[node->nterm]), stub);
			node->nterm += append_uleb(&(node->terminal[node->nterm]), resolver);
		}
		else if(!strncmp(&ibuf[lastI], ".EXPORT_REEXPORT ", 17))
		{
			exported_syms++;
			
			
			node = (exported_node*) malloc(sizeof(exported_node));
			memset(node, 0, sizeof(exported_node));
			
			uint32_t ordinal;
			char name_buf[0x200];
			sscanf(&ibuf[lastI], ".EXPORT_REEXPORT %x %s %s", &ordinal, node->base, name_buf);
			
			node->nterm = 0;
			node->nterm += append_uleb(&(node->terminal[node->nterm]), EXPORT_SYMBOL_FLAGS_REEXPORT);
			node->nterm += append_uleb(&(node->terminal[node->nterm]), ordinal);
			
			int nNameBuf = strlen(name_buf);
			memcpy(&(node->terminal[node->nterm]), name_buf, nNameBuf);
			node->nterm +=nNameBuf;
			//node->nterm += append_uleb(node->terminal, resolver);
		}
		if(node)
		{
			export_add_node(&basenode, node);
		}
	}
	
	int length = export_finalize(obuf, basenode);
	
	//fprintf(stdout, "%d exported syms\n", exported_syms);
//	char strbuf[0x80];
//	print_exported_node(basenode, strbuf);
	
	
	
	return length;
}







/*
	
	// import exports
	{
		int length = compress_export(&buf[offs], cbuf, ncf);
		dinfoc->export_off = length ? offs : 0;
		dinfoc->export_size = length;
		offs += length;
		offs = (offs + 3) & ~3; // align
	}
	
	linkedit->filesize = offs - linkedit->fileoff;
	
	//char* obuf = (char*)malloc(0x10000);
	
	/ *
	int length;
	
	length = bind_process(obuf, cbuf, ncf, ".BIND ");
	print_stream_commands((uint8_t*) obuf, length, "BIND");
	
	length = bind_process(obuf, cbuf, ncf, ".LAZY_BIND ", 1);
	print_stream_commands((uint8_t*) obuf, length, "LAZY_BIND");

	length = bind_process(obuf, cbuf, ncf, ".WEAK_BIND ");
	print_stream_commands((uint8_t*) obuf, length, "WEAK_BIND");
	
	//return 0;
	// handle export section
	
	length = compress_export(obuf, cbuf, ncf);
	
	char strbuf[0x80];
	print_export_commands((uint8_t*) obuf, length, strbuf);
	* /
	
	
	msync(buf, nfile+0x1000, MS_ASYNC);
	munmap(buf, nfile);
	ftruncate(fd, offs);
	close(fd);
	
	close(ifd);
	close(cfd);
	
	unlink(ifname);
	rename(ofname, ifname);
}
*/