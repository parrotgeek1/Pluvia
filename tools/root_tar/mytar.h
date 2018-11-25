#include <time.h>


typedef struct _headerField {
	char name[100];
	char mode[8];
	char uid[8];
	char gid[8];
	char size[12];
	char mtime[12];
	char chksum[8];
	char typeflag;
	char linkname[100];
	char magic[6];
	char version[2];
	char uname[32];
	char gname[32];
	char devmajor[8];
	char devminor[8];
	char prefix[155];
	char nothing[12];
} headerField;

int currentNameIsInList(char * name, char *list[]);
headerField *newHeaderField(void);
void updateChksum(headerField *f);
headerField *makeHeaderField(char *path,struct stat sb);
int processEntryC(const char *name, const struct stat *sb, int type);
void printArchiveListingT(headerField *head);
char *findPerm(headerField *head);
char * findOwn(headerField *head);
char * findGrp(headerField *head);
unsigned long findSize(headerField * head);
time_t findTime(headerField * head);
long int oct2dec(char *octalstr);
