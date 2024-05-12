#include "elf.h"

int elf_read(const char *path, struct elf_file *f) {
        int err = 0;

        // ELF Header
        f->f = fopen(path, "r");
        if(!f->f) return ENOENT;

        const char CEI_MAG[] = {0x7F, 0x45, 0x4c, 0x46};

        // Check Header
        for(int i = 0; i < sizeof(CEI_MAG); i += 1 ) {
                f->e.indent[i] = fgetc(f->f);
                if(f->e.indent[i] != CEI_MAG[i]) {
                        err = -1;
                        goto CLEANUP;
                }
        }

        f->e.indent[EI_CLASS] = fgetc(f->f);
        f->e.indent[EI_DATA] = fgetc(f->f);
        f->e.indent[EI_VERSION] = fgetc(f->f);
        f->e.indent[EI_OSABI] = fgetc(f->f);
        f->e.indent[EI_ABIVERSION] = fgetc(f->f);
        fread(f->e.indent + EI_PAD, 1, 0xF - EI_PAD + 1, f->f);

        fread(&f->e.type, 2, 1, f->f);
        fread(&f->e.machine, 2, 1, f->f);
        fread(&f->e.version, 4, 1, f->f);

        if(f->e.indent[EI_DATA] == 0x01) {

        } else if (f->e.indent[EI_DATA] == 0x01) {

        } else {
                err = -2;
                goto CLEANUP;
        }

        // Read the rest of the header
        fread(&f->e.flags, 1, 4 + 2 + 2 + 2 + 2 + 2 + 2, f->f);

        // Program Header

        // Section Header

        return 0;

CLEANUP:
        fclose(f->f);

        return err;
}

int elf_map(struct elf_file *f) {
        return 0;
}

