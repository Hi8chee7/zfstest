#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>
#include <unistd.h>
#include <fcntl.h>


int main(int argc, char **argv)
	{
	int ret = 1;
	if(argc != 4)
		{
		printf("Usage: %s device hexbyte offset\n", argv[0]);
		return 1;
		}
	uint8_t zahl;
	sscanf(argv[2], "%"SCNx8, &zahl);
	int64_t offset;
	sscanf(argv[3], "%"SCNi64, &offset);

	int fd;
	if((fd = open(argv[1], O_RDWR, 0)) > 0)
		{
		if(lseek(fd, offset, SEEK_SET) == offset)
			{
			uint8_t gelesen;
			if(read(fd, &gelesen, 1) == 1)
				{
				printf("vorher %02"PRIX8"\n", gelesen);
				if(lseek(fd, offset, SEEK_SET) == offset)
					{
					if(write(fd, &zahl, 1) == 1)
						{
						ret = 0;
						}
					else
						{
						puts("Fehler beim Schreiben.");
						}
					}
				else
					{
					puts("Fehler bei zweitem lseek.");
					}
				}
			else
				{
				puts("Fehler mit read.");
				}
			}
		else
			{
			puts("Fehler bei erstem lseek.");
			}
		close(fd);
		}
	else
		{
		printf("Fehler beim Öffnen der Datei \"%s\".\n", argv[1]);
		}

	return ret;
	}
