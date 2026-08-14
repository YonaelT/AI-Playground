savedcmd_btusb.mod := printf '%s\n'   btusb.o | awk '!x[$$0]++ { print("./"$$0) }' > btusb.mod
