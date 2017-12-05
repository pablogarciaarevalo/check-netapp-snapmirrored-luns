# Check SnapMirrored LUNs
Check that every source LUNs are replicated in a destination SVM

## Getting Started

This script works for two NetApp SnapMirrored clustered Data ONTAP storage systems.

### Prerequisites

* There is one source SVM with the source LUNs
* There is one destionation SVM with the destination LUNs (without production volumes)
* The destionation SVM has only destionation volumes from one source SVM
* Each LUN is stored in one volume

### Installing

First of all run once the below script to create a secure password

```
./create_securestring_file.ps1
```

## Running the tests

Fill the runtime variables at the beginning of the script and run it

```
./check_snapmirrored_luns.ps1
```
