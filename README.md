# EBS Snapshot Utility

## Description

Ruby command line utility to manage EBS Snapshots.

## Usage

### Show overall command usage and global options

```bash
$ ebs-snapshot-util.rb --help
  NAME:

    ebs-snapshot-util

  DESCRIPTION:

    AWS EBS Snapshot Utility

  COMMANDS:

    delete Delete EBS snapshots
    help   Display global or [command] help documentation
    list   List EBS snapshots

  GLOBAL OPTIONS:

    -p, --profile PROFILE
        AWS profile

    -a, --age DAYS
        Snapshots older than AGE days

    -h, --help
        Display help documentation

    -v, --version
        Display version information

    -t, --trace
        Display backtrace when an error occurs
```

### Show `list` command usage and options

```bash
$ ebs-snapshot-util.rb list --help

  NAME:

    list

  SYNOPSIS:

    ebs-snapshot-util list <bucket>

  DESCRIPTION:

    List EBS snapshots

  EXAMPLES:

    # List all EBS snapshots
    ebs-snapshot-util.rb list

    # List all EBS snapshots older than 90 days
    ebs-snapshot-util.rb list --age 90

  OPTIONS:

    -f, --format id|json|csv
        Output format (default: id)
```

### Show `delete` command usage and options

```bash
ebs-snapshot-util.rb delete --help

  NAME:

    delete

  SYNOPSIS:

    ebs-snapshot-util delete

  DESCRIPTION:

    Delete EBS snapshots. Requires --age option.

  EXAMPLES:

    # Delete EBS snapshots older than 90 days
    ebs-snapshot-util.rb delete --age 90
```
