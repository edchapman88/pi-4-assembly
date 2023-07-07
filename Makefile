# Default to the RPi4.
BSP ?= rpi4

ifeq ($(BSP),rpi3)
    TARGET            = aarch64-unknown-none-softfloat
    KERNEL_BIN        = kernel8.img
    # QEMU_BINARY       = qemu-system-aarch64
    # QEMU_MACHINE_TYPE = raspi3
    # QEMU_RELEASE_ARGS = -d in_asm -display none
    # OBJDUMP_BINARY    = aarch64-none-elf-objdump
    # NM_BINARY         = aarch64-none-elf-nm
    # READELF_BINARY    = aarch64-none-elf-readelf
    LD_SCRIPT_PATH    = $(shell pwd)/src/bsp/raspberrypi
    RUSTC_MISC_ARGS   = -C target-cpu=cortex-a53
else ifeq ($(BSP),rpi4)
    TARGET            = aarch64-unknown-none-softfloat
    KERNEL_BIN        = kernel8.img
    # QEMU_BINARY       = qemu-system-aarch64
    # QEMU_MACHINE_TYPE =
    # QEMU_RELEASE_ARGS = -d in_asm -display none
    # OBJDUMP_BINARY    = aarch64-none-elf-objdump
    # NM_BINARY         = aarch64-none-elf-nm
    # READELF_BINARY    = aarch64-none-elf-readelf
    LD_SCRIPT_PATH    = $(shell pwd)/src
    RUSTC_MISC_ARGS   = -C target-cpu=cortex-a72
endif

# Export for build.rs.
export LD_SCRIPT_PATH

##--------------------------------------------------------------------------------------------------
## Targets and Prerequisites
##--------------------------------------------------------------------------------------------------
KERNEL_MANIFEST      = Cargo.toml
KERNEL_LINKER_SCRIPT = kernel.ld
LAST_BUILD_CONFIG    = target/$(BSP).build_config

KERNEL_ELF      = target/$(TARGET)/release/kernel
# This parses cargo's dep-info file.
# https://doc.rust-lang.org/cargo/guide/build-cache.html#dep-info-files
KERNEL_ELF_DEPS = $(filter-out %: ,$(file < $(KERNEL_ELF).d)) $(KERNEL_MANIFEST) $(LAST_BUILD_CONFIG)


##--------------------------------------------------------------------------------------------------
## Command building blocks
##--------------------------------------------------------------------------------------------------
RUSTFLAGS = $(RUSTC_MISC_ARGS)                   \
    -C link-arg=--library-path=$(LD_SCRIPT_PATH) \
    -C link-arg=--script=$(KERNEL_LINKER_SCRIPT)

COMPILER_ARGS = --target=$(TARGET) \
    --release

RUSTC_CMD   = cargo rustc $(COMPILER_ARGS)
CLIPPY_CMD  = cargo clippy $(COMPILER_ARGS)
OBJCOPY_CMD = rust-objcopy \
    --strip-all            \
    -O binary

.PHONY: all clippy clean
all: $(KERNEL_BIN)

##------------------------------------------------------------------------------
## Save the configuration as a file, so make understands if it changed.
##------------------------------------------------------------------------------
$(LAST_BUILD_CONFIG):
	@rm -f target/*.build_config
	@mkdir -p target
	@touch $(LAST_BUILD_CONFIG)

##------------------------------------------------------------------------------
## Compile the kernel ELF
##------------------------------------------------------------------------------
$(KERNEL_ELF): $(KERNEL_ELF_DEPS)
	$(call color_header, "Compiling kernel ELF - $(BSP)")
	@RUSTFLAGS="$(RUSTFLAGS)" $(RUSTC_CMD)

##------------------------------------------------------------------------------
## Generate the stripped kernel binary
##------------------------------------------------------------------------------
$(KERNEL_BIN): $(KERNEL_ELF)
	$(call color_header, "Generating stripped binary")
	@$(OBJCOPY_CMD) $(KERNEL_ELF) $(KERNEL_BIN)
	$(call color_progress_prefix, "Name")
	@echo $(KERNEL_BIN)
	$(call color_progress_prefix, "Size")
	$(call disk_usage_KiB, $(KERNEL_BIN))

##------------------------------------------------------------------------------
## Run clippy
##------------------------------------------------------------------------------
clippy:
	@RUSTFLAGS="$(RUSTFLAGS)" $(CLIPPY_CMD)

##------------------------------------------------------------------------------
## Clean
##------------------------------------------------------------------------------
clean:
	rm -rf target $(KERNEL_BIN)
