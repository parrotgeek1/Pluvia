/*
 Sean Quinn 
 Ethan Nelson-Moore
 */

#include <sys/types.h>
#include <dirent.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>
#include <limits.h>
#include <pwd.h>
#include <errno.h>
#ifndef PATH_MAX
#define PATH_MAX 2048
#endif
#include <ftw.h>
#include <math.h>
#include <grp.h>
#include <fcntl.h>
#include <utime.h>

#include "mytar.h"

extern int32_t extract_special_int(char *where, int len);
extern int insert_special_int(char *where, size_t size, int32_t val);

FILE *archiveFile;
struct stat outStat;
int v = 0;
int s = 0;

int currentNameIsInList(char * name, char *list[]){
    int i;
    int sl;
    int dotslashdel =0;
    int sln= strlen(name);
    if(list[0] == NULL){
        return 1;
    }
    for( i = 0; list[i]; i++){
        if(strcmp(name, list[i]) == 0){
            return 1;
        }
        sl=strlen(list[i]);
        while(name[0] == '.' && name[1] == '/'){
            name++;
            name++;
            dotslashdel =1;
        }
        if(dotslashdel &&
           ((sl==1 && list[i][0]=='.') || (sl==2 && strcmp(list[i],"./")==0)))
               return 1;

        if(strcmp(name, list[i]) == 0){
            return 1;
        }else if (strstr(name, list[i]) == name){
            /* either, the character at the end of list[i] must be /
             of the character AFTER the end of it, in name, is / */
            if((sl>0 && list[i][sl-1]=='/')
               || (sln > sl && name[sl] == '/'))
                return 1;
        }
    }
    return  0;
}

int roundUp(int numToRound, int multiple) {
    if (multiple == 0)
        return numToRound;

    int remainder = numToRound % multiple;
    if (remainder == 0)
        return numToRound;

    return numToRound + multiple - remainder;
}

/*
 • Permissions for extracted files
 – By default, tar does not try to restore a files’s archived permissions.
 – It offers rw permission to everyone, and the umask applies.
 – If any execute bits are set in the archived permissions,
 tar offers execute permission to all on the extracted file.
 */

int hasAnyExec(char *permission) {
    int i;
    for (i = 0; i < 8; i++){
        if(permission[i] =='1' || permission[i] =='3'
           || permission[i] =='5'  || permission[i] =='7' ) {
            return 1;
        }
    }
    return 0;
}

void extractTarOrOutput(char *specified[],int onlyOutput) {
    headerField f;
    int i;
    char theirChksum[8];
    char fPath[257];
    char parent[257];
    char *foundslash = NULL;
    int skipping = 0;
    size_t size;
    size_t fws;
    struct stat sb;
    char *readbuf;
    FILE *output;
    time_t thetime;
    struct utimbuf utb;
    int oneempty = 0;
    int theirint;
    int ourint;

    memset(theirChksum,0,8);
    memset(fPath,0,257);
    memset(parent,0,257);
    while(!feof(archiveFile)) {
    top:
        fread(&f,512,1,archiveFile);
        /* get entire path */
        if(f.name[0]==0) {
            if(oneempty) {
                return;
            }
            oneempty = 1;
            goto top;
        } else {
            oneempty = 0;
        }
        /* if NOT strict don't check 0 at end of ustar,
         if strict check version as 00 */
        if(strncmp(f.magic,"ustar",5) != 0 || (s && f.magic[5] == '0') ||
           (s && (f.version[0] != '0' || f.version[1] != '0'))) {
            fprintf(stderr,"mytar: not a valid tar archive\n");
            fclose(archiveFile);
            exit(EXIT_FAILURE);
        }
        strcpy(theirChksum,f.chksum);
        for(i = 0; i < 8; i++) {
            if(theirChksum[i] == ' ') theirChksum[i] = 0;
        }
        updateChksum(&f);
        theirint = oct2dec(theirChksum);
        ourint = oct2dec(f.chksum);
        if(theirint != ourint) {
            fprintf(stderr,"mytar: bad checksum\n");
            fclose(archiveFile);
            exit(EXIT_FAILURE);
        }
        /*
         ’0’ Regular file
         ’\0’ Regular file (alternate)
         ’2’ symbolic link
         ’5’ directory
         */

        if(f.prefix[0] != 0) {
            strncpy(fPath,f.prefix,155);
            strncat(fPath,"/",1);
            strncat(fPath,f.name,100);
        } else {
            strncpy(fPath,f.name,100);
        }
        if(specified[0] == NULL || currentNameIsInList(fPath,specified)) {
            if(onlyOutput) {
                if(f.typeflag == 0 || f.typeflag == '0'
                   || f.typeflag == '2' || f.typeflag == '5') {
                    if(f.typeflag == '2') {
                        if(f.linkname[0]==0) {
                            fprintf(stderr,"mytar: corrupted archive\n");
                            fclose(archiveFile);
                            exit(EXIT_FAILURE);
                        }
                    }
                    printArchiveListingT(&f);
                    size = findSize(&f);
                    if(f.typeflag == '0' || f.typeflag == 0) {
                        skipping = roundUp(size,512);
                        fseek(archiveFile,skipping,SEEK_CUR);
                    }
                } else {
                    if(f.prefix[0] != '\0') {
                        fprintf(stderr,"mytar: %s/%s: unknown typeflag,"
                            " skipping\n",f.prefix,f.name);
                    } else {
                        fprintf(stderr,"mytar: %s: unknown typeflag,"
                            " skipping\n",f.name);
                    }
                }
            } else {
                if(v) {
                    puts(fPath);
                }

                /* make parent dirs if not exist */
                strcpy(parent,fPath);
                foundslash=strchr(parent,'/');
                /* while / isn't last char */
                while (foundslash!=NULL && *(foundslash+1) != 0)
                {
                    parent[foundslash-parent] = 0;
                    /* to make the part of the string */
                    if(strcmp(parent,".")!= 0
                       && strcmp(parent,"")!= 0 ) {
                        if(mkdir(parent,0777)!=0) {
                            if((errno != EEXIST ||
                                (stat(parent,&sb)!=0&& !S_ISDIR(sb.st_mode)))){
                                    perror(parent);
                                    goto top;
                                } else {
                                    /* if it exists chmod it */
                                    if(chmod(parent,0777)!=0) {
                                        perror(parent);
                                        goto top;
                                    }
                                }
                        }
                    }
                    parent[foundslash-parent] = '/';
                    foundslash=strchr(foundslash+1,'/');
                }

                size = findSize(&f);
                if(f.typeflag == '0' || f.typeflag == 0) {
                    skipping = roundUp(size,512);
                    readbuf = calloc(1,skipping);
                    if(!readbuf) {
                        fprintf(stderr,"calloc fail\n");
                        exit(EXIT_FAILURE);
                    }
                    fread(readbuf,skipping,1,archiveFile);
                    output = fopen(fPath,"wb");
                    if(!output) {
                        perror(fPath);
                        free(readbuf);
                        goto top;
                    }
                    fws = fwrite(readbuf,size,1,output);
                    if(fws !=  1) {
                        perror(fPath);
                        /* it is ok to just continue */
                    }
                    free(readbuf);
                    fclose(output);
                    /*  set perms */
                    if(hasAnyExec(f.mode)) {
                        if(chmod(fPath,0777)!=0) {
                            perror(fPath);
                            goto top;
                        }
                    } else {
                        if(chmod(fPath,0666)!=0) {
                            perror(fPath);
                            goto top;
                        }
                    }

                    /* set mtime */
                    thetime = findTime(&f);
                    utb.modtime = thetime;
                    utb.actime = time(NULL);
                    if(utime(fPath,&utb)!=0) {
                        // whatever
                    }


                } else if(f.typeflag == '2') {
                    if(f.linkname[0]==0) {
                        fprintf(stderr,"mytar: corrupted archive\n");
                        fclose(archiveFile);
                        exit(EXIT_FAILURE);
                    }
                    if(symlink(f.linkname,fPath)!=0) {
                        goto top;
                    }
                    /*  set perms */
                    if(hasAnyExec(f.mode)) {
                        if(chmod(fPath,0777)!=0) {
                           // on some oses you can't set symlink perms
                        }
                    } else {
                        if(chmod(fPath,0666)!=0) {
                            // on some oses you can't set symlink perms

                        }
                    }

                    /* set mtime */
                    thetime = findTime(&f);
                    utb.modtime = thetime;
                    utb.actime = time(NULL);
                    if(utime(fPath,&utb)!=0) {
                        // whatever
                    }

                } else if(f.typeflag == '5') {
                    if(fPath[strlen(fPath)-1] == '/') {
                        fPath[strlen(fPath)-1] = 0;
                    }
                    if(strcmp(fPath,".")!= 0 && strcmp(fPath,"")!= 0 ) {
                        if(mkdir(fPath,0777)!=0) {
                            if((errno != EEXIST ||
                                (!stat(fPath,&sb)&& !S_ISDIR(sb.st_mode)))) {
                                    goto top;
                                }
                        } else {
                            /* if it exists
                             chmod it */
                            if(chmod(fPath, 0777)!=0) {
                                perror(fPath);
                                goto top;
                            }
                            /* set mtime */
                            thetime = findTime(&f);
                            utb.modtime = thetime;
                            utb.actime = time(NULL);
                            if(!utime(fPath,&utb))
                            {
                               // whatever
                            }

                        }
                    }
                } else {
                    if(f.prefix[0] != '\0') {
                        fprintf(stderr,"mytar: %s/%s: unknown typeflag, "
                                "skipping\n",f.prefix,f.name);
                    } else {
                        fprintf(stderr,"mytar: %s: unknown typeflag,"
                            " skipping\n",f.name);
                    }
                }
            } /* end onlyoutput else */
        }else {
            size = findSize(&f);
            if(f.typeflag == '0' || f.typeflag == 0) {
                skipping = roundUp(size,512);
                fseek(archiveFile,skipping,SEEK_CUR);
            }
        }
    }
}

int processEntryC(const char *name, const struct stat *sb, int type) {
    headerField *f;
    char buf[512];
    FILE * currentFile;
    int n = 1;
    memset(buf, 0 , 512);
    if(!((type == FTW_F )||type==FTW_SL||(type == FTW_D))) {
        if(type == FTW_NS || type == FTW_DNR) {
            fprintf(stderr,"mytar: warning: %s cannot be read, skipping\n",
                    name);
        } else {
            fprintf(stderr,"mytar: warning: %s is not a regular"
                " file, link, or directory, skipping\n",name);
        }
        /* we can't read it */
        return 0;
    }

    if(strlen(name)>256) {
        fprintf(stderr,"mytar: %s: path too long, skipping\n",name);
        return 0;
    }

    if((type == FTW_F )||type==FTW_SL||((type == FTW_D)
                                        && strcmp(".", name) != 0)) {
        f = makeHeaderField((char *)name,*sb);
        if(f) {
            if( type == FTW_F){
                if(!sb) {
                    fprintf(stderr,"mytar: warning: %s cannot be read,"
                        " skipping\n",name);
                    free(f);
                    return 0;
                }
                if(sb && sb->st_ino == outStat.st_ino
                   && sb->st_dev == outStat.st_dev){
                    printf("%s: file is the archive; not dumped\n", name);
                }else{
                    /* don't write header if not inserting file */
                    fwrite(f, sizeof(headerField), 1,archiveFile);
                    currentFile = fopen(name, "rb");
                    if( currentFile == NULL){
                        perror(name);

                    }else{
                        while( (n = fread(buf, 1, 512,currentFile))> 0 ){
                            fwrite(buf, 512, 1,archiveFile);
                            memset(buf, 0 , 512);
                        }

                        fclose(currentFile);
                    }
                }
            } else {
                fwrite(f, sizeof(headerField), 1, archiveFile);
            }

            free(f);
        } else {
            fprintf(stderr,"mytar: warning: %s cannot be read, skipping\n",
                    name);
        }
    }


    return 0;
}


/*
 FTW_F    The object is a  file
 FTW_D    ,,    ,,   ,, ,, directory
 FTW_DNR  ,,    ,,   ,, ,, directory that could not be read
 FTW_SL   ,,    ,,   ,, ,, symbolic link
 FTW_NS   The object is NOT a symbolic link and is one for which
 stat() could not be executed
 */

int r; /* gross but easy */

int main(int argc, char *argv[]){
    int t=0,c=0,x=0,seenACommand=0;
    int i;
    char buf[512];
    char temp, *temp2[255];

    int ok = 0;

    memset(temp2,0,sizeof(temp2));
    r = 0;

    if(argc >= 3) {
        for (i = 0; i < (int)strlen(argv[1]); i++){
            temp = argv[1][i];
            if(temp == 'c') {
                if(seenACommand || argc < 4) {
                    /* need 4 to specify what to put in archive */
                    ok = 0;
                    break;
                } else {
                    ok = 1;
                    seenACommand = 1;
                    c = 1;
                }
            } else if(temp == 't') {
                if(seenACommand) {
                    ok = 0;
                    break;
                } else {
                    ok = 1;
                    seenACommand = 1;
                    t = 1;
                }
            } else if(temp == 'x') {
                if(seenACommand) {
                    ok = 0;
                    break;
                } else {
                    ok = 1;
                    seenACommand = 1;
                    x = 1;
                }
            } else if(temp == 'v') {
                v = 1;
            } else if(temp == 'R') {
                r = 1;
            } else if(temp == 'S') {
                s = 1;
            } else if(temp != 'f'){
                ok = 0;
                break;
            }
        }
        if(i>0 && argv[1][i-1] != 'f') {
            /* last must be f*/
            ok = 0;
        }
    }

    if(!ok) {
        fprintf(stderr,"Usage: mytar [ctxvRS]f tarfile [ path [ ...  ]  ]\n");
        exit(EXIT_FAILURE);
    }

    if(t) {
        archiveFile = fopen(argv[2],"rb");
        if( archiveFile == NULL){
            perror(argv[2]);
            exit(EXIT_FAILURE);
        }
        if(argc == 3) {
            temp2[0] = NULL;
        } else {
            for (i = 3; i < argc; i++){
                temp2[i-3] = argv[i];
            }
        }
        extractTarOrOutput(temp2,1);
        fclose(archiveFile);
    } else if(c) {
        /* If we are trying to create an archive with 'c' */
        archiveFile = fopen(argv[2],"wb");
        if( archiveFile == NULL){
            perror(argv[2]);
            exit(EXIT_FAILURE);
        }else{
            stat(argv[2],&outStat);
            for (i = 3; i < argc; i++){
                ftw(argv[i], processEntryC, 50);
            }
            memset(buf, 0 , 512);
            fwrite(buf, 512, 1, archiveFile);
            fwrite(buf, 512, 1, archiveFile);
            fclose(archiveFile);
        }
    } else if(x) {
        archiveFile = fopen(argv[2],"rb");
        if( archiveFile == NULL){
            perror(argv[2]);
            exit(EXIT_FAILURE);
        }else{

            if(argc == 3) {
                temp2[0] = NULL;
            }else {
                for (i = 3; i < argc; i++){
                    temp2[i-3] = argv[i];
                }
            }
            extractTarOrOutput(temp2,0);

            fclose(archiveFile);
        }
    }

    return 0;

}

headerField *newHeaderField() {
    headerField *f = malloc(sizeof(headerField));
    if(!f) {
        fprintf(stderr,"malloc fail\n");
        exit(EXIT_FAILURE);
    }
    memset(f,0,sizeof(headerField));
    strncpy(f->version,"00",2);
    strncpy(f->magic,"ustar",6);
    return f;
}

void updateChksum(headerField *f) {
    int i, sum;

    /*
     * Per POSIX, the checksum is the simple sum of all bytes in the header,
     * treating the bytes as unsigned, and treating the checksum field (at
     * offset 148) as though it contained 8 spaces.
     */
    memset(f->chksum,' ',7);
    sum = 8 * ' ';
    for (i = 0; i < 512; i++)
        if (i < 148 || i >= 156) /* skip checksum bytes */
            sum += 0xFF & ((char *)f)[i];
    snprintf(f->chksum,8,"%07o",sum);
    f->chksum[7] = 0;

}

headerField *makeHeaderField(char *path, struct stat sb) {
    int i;
    struct stat linksb;
    char buf[PATH_MAX+1];
    int index;
    headerField *f;
    char *ugrp = NULL;
    ssize_t len;

    i = lstat(path, &sb);
    if(i != 0){
        perror(path);
        return NULL; /* go on to next */
    }
    f = newHeaderField();
    snprintf(f->devmajor,8,"000000 ");
    snprintf(f->devminor,8,"000000 ");

    snprintf(f->mode,8, "%06o ",sb.st_mode & 07777);
    /* mod 20181124 */
    if(!r) {
        if(sb.st_uid > 2097151) {
            if(!s) {
                insert_special_int(f->uid,8,sb.st_uid);
            } else {
                fprintf(stderr,"mytar: can't create uid %d in strict mode\n",
                        sb.st_uid);
                fclose(archiveFile);
                exit(EXIT_FAILURE);
            }
        }
        else
            snprintf(f->uid, 8, "%06o ", sb.st_uid);

        if(sb.st_gid > 2097151) {
            if(!s) {
                insert_special_int(f->gid,8,sb.st_gid);
            } else {
                fprintf(stderr,"mytar: can't create gid %d in strict mode\n",
                        sb.st_gid);
                fclose(archiveFile);
                exit(EXIT_FAILURE);
            }
        }
        else
            snprintf(f->gid, 8, "%06o ", sb.st_gid);
    } else {
        snprintf(f->uid,8,"000000 ");
        snprintf(f->gid,8,"000000 ");
    }

    /* mod 20181124 end */
    if(S_ISDIR(sb.st_mode) || S_ISLNK(sb.st_mode)) {
        snprintf(f->size,11,"00000000000");
        f->size[11]=' ';
        if(S_ISDIR(sb.st_mode)) {
            f->typeflag = '5';
            if(strlen(path)<=99) {
                strncpy(f->name,path,99);
                strcat(f->name,"/");
            } else {
                index = (int)(strrchr(path,'/') - path);
                if(index >= 155) {
                    fprintf(stderr,"mytar: %s: path cannot be separated,"
                        " skipping\n",path);
                }
                strncpy(f->name,strrchr(path,'/')+1,99);
                strcat(f->name,"/");
                strncpy(f->prefix,path,index);
            }
        } else {
            /* using 100 for posix / doesn't have to have null */
            if(strlen(path)<=100) {
                strncpy(f->name,path,100);
            } else {
                index = (int)(strrchr(path,'/') - path);
                if(index >= 155) {
                    fprintf(stderr,"mytar: %s: path cannot be separated,"
                        " skipping\n",path);
                }
                strncpy(f->name,strrchr(path,'/')+1,100);
                strncpy(f->prefix,path,index);
            }
            if(S_ISLNK(sb.st_mode)) {
                f->typeflag = '2';
                /*  update linkname */
                i = lstat(path, &linksb);
                if(i == 0){
                    if ((len = readlink(path, buf,sizeof(buf)-1)) != -1) {
                        buf[len] = '\0';
                        /* snprintf automatically
                         null terminates */
                        snprintf(f->linkname,100, "%s",buf);
                    } else {
                        perror(path);
                        free(f);
                        return NULL; /* go on to next */
                    }
                }
            }
        }
        /* The size of symlinks and directories is zero. */
    } else {
        f->typeflag = '0';
        /* using 100 for posix / doesn't have to have null */
        if(strlen(path)<=100) {
            strncpy(f->name,path,100);
        } else {
            index = (int)(strrchr(path,'/') - path);
            if(index >= 155) {
                fprintf(stderr,"mytar: %s: path cannot be separated,"
                    " skipping\n",path);
            }
            strncpy(f->name,strrchr(path,'/')+1,100);
            strncpy(f->prefix,path,index);
        }
        snprintf(f->size,12,"%011lo",(unsigned long)sb.st_size);
        f->size[11]=' ';
    }
    snprintf(f->mtime,12,"%011lo",sb.st_mtime);
    f->mtime[11]=' ';

    ugrp = findOwn(f);
    if(ugrp) {
        strncpy(f->uname,ugrp,31);
        free(ugrp);
    }
    ugrp = findGrp(f);
    if(ugrp) {
        strncpy(f->gname,ugrp,31);
        free(ugrp);
    }
    updateChksum(f); /* always last */
    return f;
}


void printArchiveListingT(headerField *head){
    char *perm = NULL;
    unsigned long size;
    time_t time;
    char owngrp[18], mtime[17];
    char temp[18];

    if(v) {
        perm = findPerm(head);
        size = findSize(head);
        time = findTime(head);
        temp[17] = '\0';
        if( strcmp(head->uname,"") == 0 ){
            sprintf(owngrp, "%ld", oct2dec(head->uid));
            strcat(owngrp, "/");
            if( strcmp(head->gname,"") == 0){
                sprintf(temp, "%ld", oct2dec(head->gid));
                strcat(owngrp,temp );
            }else{
                strcat(owngrp, head->gname);
            }
        }else if ( strcmp(head->gname,"") == 0 ){
            strcpy(owngrp, head->uname);
            strcat(owngrp, "/");
            sprintf(temp, "%ld", oct2dec(head->gid));
            strcat(owngrp,temp );
        }else{
            snprintf(owngrp, 18, "%s/%s",head->uname,head->gname);
        }

        owngrp[17] = '\0';
        strftime(mtime,17,"%Y-%m-%d %H:%M",localtime(&time));
        mtime[16] = '\0';

        if(head->prefix[0] != '\0') {
            printf("%s %-17s %8lu %-16s %.155s/%.100s\n", perm, owngrp,size,
                   mtime,head->prefix, head->name);
        } else {
            printf("%s %-17s %8lu %-16s %.100s\n", perm, owngrp, size,mtime,
                   head->name);
        }
        free(perm);
    } else {
        if(head->prefix[0] != '\0') {
            printf("%.155s/%.100s\n", head->prefix, head->name);
        } else {
            printf("%.100s\n",head->name);
        }
    }

}

long int oct2dec(char *octalstr) {
    return strtol(octalstr,NULL,8);
}

unsigned long findSize(headerField * head){
    return (unsigned long)oct2dec(head->size);
}

time_t findTime(headerField * head){
    return (time_t)oct2dec(head->mtime);
}

char * findOwn(headerField *head){
    char* ownGrp = malloc(33);
    int uid;
    int specialint;
    struct passwd *passwd1;
    memset(ownGrp,0,33);

    specialint = extract_special_int(head->uid,8);
    if(specialint == -1) {
        uid = oct2dec(head->uid);
    } else {
        uid = specialint;
    }

    passwd1 = getpwuid(uid);
    if(!passwd1) {
        free(ownGrp);
        return NULL;
    } else {
        strncpy(ownGrp, passwd1->pw_name,32);
    }
    return ownGrp;
}

char * findGrp(headerField *head){
    char* ownGrp = malloc(33);
    int gid;
    int specialint;
    struct group *group;
    memset(ownGrp,0,33);

    specialint = extract_special_int(head->gid,8);
    if(specialint == -1) {
        gid = oct2dec(head->gid);
    } else {
        gid = specialint;
    }

    group = getgrgid(gid);
    if(!group) {
        free(ownGrp);
        return NULL;
    } else {
        strncpy(ownGrp, group->gr_name,32);
    }
    return ownGrp;
}

char *findPerm(headerField *head){

    int temp;
    int i;
    char* perm = malloc(11);
    int mode = 0;
    if(!perm) {
        fprintf(stderr,"malloc fail\n");
        exit(EXIT_FAILURE);
    }
    memset(perm,'-',10);
    perm[10] = '\0';
    if(head->typeflag == '2')
        perm[0] = 'l';
    else if(head->typeflag == '5')
        perm[0] = 'd';
    else
        perm[0] = '-';
    temp = 1;
    i = 0;
    while(head->mode[i] == '0'){
        i++;
    }
    for (; i < 8; i++){
        if(head->mode [i] == 0 || head->mode[i] == ' ') break;
        mode = head->mode[i] - '0';

        if((mode & 4) == 4){
            perm[temp] = 'r';
        }
        if((mode & 2) == 2){
            perm[temp + 1] = 'w';
        }
        if((mode & 1) == 1){
            perm[temp + 2] = 'x';
        }
        temp += 3;
    }
    perm[10] = '\0';
    return perm;
}
