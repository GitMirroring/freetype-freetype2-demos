#**************************************************************************
#*
#*  Cocoa specific rules file, used to compile the Cocoa graphics driver
#*  to the graphics subsystem
#*
#**************************************************************************
ifeq ($(shell uname),Darwin)

  GR_COCOA  := $(GRAPH)/cocoa

  GRAPH_OBJS += $(OBJ_DIR_2)/grcocoa.$O

  DEVICES += COCOA

  $(OBJ_DIR_2)/grcocoa.$O: $(GR_COCOA)/grcocoa.mm $(GR_COCOA)/grcocoa.h $(GRAPH_H)
		$(CC) $(CFLAGS) $(GRAPH_INCLUDES:%=$I%) \
                $I$(subst /,$(COMPILER_SEP),$(GR_COCOA)) \
                $T$(subst /,$(COMPILER_SEP),$@ $<)

endif

# EOF
