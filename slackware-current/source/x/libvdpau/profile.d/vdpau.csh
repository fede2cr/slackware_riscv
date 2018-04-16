#!/bin/csh

# Disable debugging output of the vdpau backend
setenv VDPAU_LOG 0

# Use the vdpau backend of the nvidia binary driver
#setenv VDPAU_DRIVER "nvidia"

# Use the vdpau backend of the nouveau driver
#setenv VDPAU_DRIVER "nouveau"

# Use the vdpau backend of the r300 driver
#setenv VDPAU_DRIVER "r300"

# Use the vdpau backend of the r600 driver
#setenv VDPAU_DRIVER "r600"

# Use the vdpau backend of the radeonsi driver
#setenv VDPAU_DRIVER "radeonsi"

# Use the va-api/opengl backend
#setenv VDPAU_DRIVER "va_gl"
