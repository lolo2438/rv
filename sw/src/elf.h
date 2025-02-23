#ifndef __ELF_H__
#define __ELF_H__

#include <stdint.h>
#include <stdio.h>
#include <errno.h>

#define EI_MAG          0x00
#define EI_CLASS        0x04
#define EI_DATA         0x05
#define EI_VERSION      0x06
#define EI_OSABI        0x07
#define EI_ABIVERSION   0x08
#define EI_PAD          0x09

enum ELF_ABI {
        SYSTEMV=0x00,
        HPUX=0x01,
        NETBSD=0x02,
        LINUX=0x03,
        GNUHURD=0x04,
        SOLARIS=0x06,
        AIX=0x07,
        IRIX=0x08,
        FREEBSD=0x09,
        TRU64=0x0A,
        NOVELLMOSESTO=0x0B,
        OPENBSD=0x0C,
        OPENVMS=0x0D,
        NONSTOPKERNEL=0x0E,
        AROS=0x0F,
        FENIXOS=0x10,
        NUXICLOUDABI=0x11,
        STOPENVOS=0x12
};

enum ELF_ISA {
        NOISA=0x00,
        ATTWE32100=0x01,
        SPARC=0x02,
        X86=0x03,
        M68K=0x04,
        M88k=0x05,
        INTEL_MCU=0x06,
        INTEL_80860=0x07,
        MIPS=0x08,
        SYSTEM370=0x09,
        MIPS_RS3000_LE=0x0A,
        PA_RISC=0x0F,
        INTEL_80960=0x13,
        POWER_PC_32=0x14,
        POWER_PC_64=0x15,
        S390=0x16,
        IBM_SPU_SPC=0x17,
        NEC_V800=0x24,
        FR20=0x25,
        TRW_RH_32=0x26,
        MOTOROLA_RCE=0x27,
        ARM=0x28,
        DIGIAL_ALPHA=0x29,
        SUPERH=0x2A,
        SPARC_V9=0x2B,
        SIEMENS_TRICORE=0x2C,
        ARGONAUT=0x2D,
        H8300=0x2E,
        H8300H=0x2F,
        H8S=0x30,
        H8500=0x31,
        IA_64=0x32,
        MIPSX=0x33,
        COLDFIRE=0x34,
        M68HC12=0x35,
        FUJITSU_MMA=0x36,
        PCP=0x37,
        NCPU=0x38,
        NDR1=0x39,
        STARCORE=0x3A,
        ME16=0x3B,
        ST100=0x3C,
        TinyJ=0x3D,
        X86_64=0x3E,
        SONY_DSP=0x3F,
        PDP10=0x40,
        PDP11=0x41,
        FX66=0x42,
        ST9=0x43,
        ST7=0x44,
        MC68HC16=0x45,
        MC68HC11=0x46,
        MC68HC08=0x47,
        MC68HC05=0x48,
        SVX=0x49,
        ST19=0x4A,
        DVAX=0x4B,
        AXIS_32=0x4C,
        INFINEON_32=0x4D,
        ELEMENT14=0x4E,
        LSI_16=0x4F,
        TMS320C6000=0x8C,
        MCST_ELBRUS_E2K=0xAF,
        ARM64=0xB7,
        Z80=0xDC,
        RISCV=0xF3,
        BPF=0xF7,
        WDC65C816=0x101,
        LOONGARCH=0x102,
};

struct elf_header {
        uint8_t indent[16];

        uint16_t type;
        uint16_t machine;

        uint32_t version;

        uint64_t entry; // Memory address of the entry point where process starts executing
        uint64_t phoff; // Points to the program header table
        uint64_t shoff; // Points to the section header table

        uint32_t flags;
        uint16_t ehsize;
        uint16_t phentsize;
        uint16_t phnum;
        uint16_t shentsize;
        uint16_t shnum;
        uint16_t shtrndx;
};

#define PT_NULL         0x00000000      //Program header table entry unused.
#define PT_LOAD         0x00000001      //Loadable segment.
#define PT_DYNAMIC      0x00000002      //Dynamic linking information.
#define PT_INTERP       0x00000003      //Interpreter information.
#define PT_NOTE         0x00000004      //Auxiliary information.
#define PT_SHLIB        0x00000005      //Reserved.
#define PT_PHDR         0x00000006      //Segment containing program header table itself.
#define PT_TLS          0x00000007      //Thread-Local Storage template.
#define PT_L00S         0x60000000      //Reserved inclusive range. Operating system specific.
#define PT_HIOS         0x6FFFFFFF
#define PT_LOPROC       0x70000000      //Reserved inclusive range. Processor specific.
#define PT_HIPROC       0x7FFFFFFF

#define PF_X 0x1
#define PF_W 0x2
#define PF_R 0x4

struct elf_pheader {
        uint32_t type;
        uint32_t flags;
        uint64_t offset;
        uint64_t vaddr;
        uint64_t paddr;
        uint64_t filesz;
        uint64_t memsz;
        uint64_t align;
};

#define SHT_NULL                0x0
#define SHT_PROGBITS            0x1
#define SHT_SYMTAB              0x2
#define SHT_STRTAB              0x3
#define SHT_RELA                0x4
#define SHT_HASH                0x5
#define SHT_DYNAMIC             0x6
#define SHT_NOTE                0x7
#define SHT_NOBITS              0x8
#define SHT_REL                 0x9
#define SHT_SHLIB               0xA
#define SHT_DYNSYM              0xB
#define SHT_INIT_ARRAY          0xE
#define SHT_FINI_ARRAY          0xF
#define SHT_PREINIT_ARRAY       0x10
#define SHT_GROUP               0x11
#define SHT_SYMTAB_SHNDX        0x12
#define SHT_NUM                 0x13
#define SHT_LOOS                0x600000000

#define SHF_WRITE	        0x1             //Writable
#define SHF_ALLOC	        0x2             //Occupies memory during execution
#define SHF_EXECINSTR	        0x4             //Executable
#define SHF_MERGE	        0x10            //Might be merged
#define SHF_STRINGS	        0x20            //Contains null-terminated strings
#define SHF_INFO_LINK	        0x40            //'sh_info' contains SHT index
#define SHF_LINK_ORDER	        0x80            //Preserve order after combining
#define SHF_OS_NONCONFORMING	0x100           //Non-standard OS specific handling required
#define SHF_GROUP	        0x200           //Section is member of a group
#define SHF_TLS	Section         0x400           //hold thread-local data
#define SHF_MASKOS	        0x0FF00000      //OS-specific
#define SHF_MASKPROC	        0xF0000000      //Processor-specific
#define SHF_ORDERED	        0x4000000       //Special ordering requirement (Solaris)
#define SHF_EXCLUDE             0x8000000	//Section is excluded unless referenced or allocated (Solaris)

struct elf_sheader {
        uint32_t name;
        uint32_t type;
        uint64_t flags;
        uint64_t addr;
        uint64_t offset;
        uint64_t size;
        uint32_t link;
        uint32_t info;
        uint64_t addralign;
        uint64_t entsize;
};

struct elf_file {
        struct elf_header e;
        struct elf_pheader p;
        struct elf_sheader sh;
        FILE * f;
};

int elf_open(const char *path, struct elf_file *f);

int elf_close(struct elf_file *f);

#endif
