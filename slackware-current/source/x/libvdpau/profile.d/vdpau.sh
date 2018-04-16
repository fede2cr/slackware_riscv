#!/bin/sh

# Disable debugging output of the vdpau backend
export VDPAU_LOG=0

# Use the vdpau backend of the nvidia binary driver
#export VDPAU_DRIVER="nvidia"

# Use the vdpau backend of the nouveau driver
#export VDPAU_DRIVER="nouveau"

# Use the vdpau backend of the r300 driver
#export VDPAU_DRIVER="r300"

# Use the vdpau backend of the r600 driver
#export VDPAU_DRIVER="r600"

# Use the vdpau backend of the radeonsi driver
#export VDPAU_DRIVER="radeonsi"

# Use the va-api/opengl backend
#export VDPAU_DRIVER="va_gl"
