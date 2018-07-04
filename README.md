# encrypted-copy

## vc_encrypted_copy script

Powershell script for creating encrypted copy of file/directory using Veracrypt.

The script needs Veracrypt binaries to be available in Powershell.
Adding Veracrypt dir to PATH environment variable is enough.

```
> powershell -executionpolicy bypass -File vc_encrypted_copy.ps1 -in test_dir -out test_container.vc

Enter password: ********
Creating container test_container.vc - size: 42167899
Mounting container - letter: z
Container mounted
Copying data
Data copied
Container unmounting
Container unmounted
Done!
```