


struct exported_node
{
	exported_node* child;
	exported_node* sibling;
	
	int offs;
	int nterm;
	
	// so that we can process the command
	int flags;
	uint32_t stub;
	uint32_t resolver;
	uint32_t ordinal;
	
	char base[0x200];

	char reexport[0x200];
	
	
	char terminal[0x200];
};


uint32_t append_uleb(char* p, uint32_t val);


void scan_export_tree(
		const uint8_t *start, int len, char* strbuf,
		void (*callback)(exported_node* node, uintptr_t context), uintptr_t context = NULL,
		const uint32_t coffset = 0, const uint8_t tabdepth = 0);

void print_export_commands_sub(exported_node* node, uintptr_t context);

void print_export_commands(const uintptr_t start, int len);


void export_construct_terminal(exported_node* node);

void export_add_node(exported_node** _basenode, exported_node* node);

int export_finalize(char* obuf, exported_node* basenode);



