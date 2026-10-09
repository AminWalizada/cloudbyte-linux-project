# CloudByte Solutions: Linux SysAdmin Project

A Linux system administration project, built first on a local VM
and later deployed to AWS EC2. The scenario is CloudByte Solutions, a
fictional 12-person startup that needs a properly configured multi-user
Linux server: user accounts, group-based file access, automated backups,
log analysis, and system health reporting.

## Skills Demonstrated

- Linux administration and file permissions
- Bash scripting and task automation
- User and group management
- Backup creation and retention cleanup
- Log generation, analysis, and reporting
- System health monitoring
- Cron scheduling and troubleshooting
- AWS EC2 deployment and management
- Git and GitHub version control

## Section 1: Server Foundations

Built the core of the server: four groups (`engineering`, `marketing`,
`operations`, `admins`), twelve user accounts, and a directory tree under
`/shared` with group-based access control.

### Groups and users

| Group         | Members                      |
|---------------|------------------------------|
| `engineering` | alice, bob, carol, dave      |
| `marketing`   | emma, frank, grace           |
| `operations`  | henry, iris, jack, kate, leo |
| `admins`      | kate, leo                    |

### Directory structure

| Path                  | Group       | Mode  |
|-----------------------|-------------|-------|
| `/shared/engineering` | engineering | `770` |
| `/shared/marketing`   | marketing   | `770` |
| `/shared/operations`  | operations  | `770` |
| `/shared/company-docs`| admins      | `775` |
| `/logs/reports`       | admins      | `775` |

### Verification

`verify-foundations.sh` checks the groups, users, directories and setup
log in one go. Run it on the VM with:

    # Track 1 (Vagrant): repo is mounted at /vagrant
    bash /vagrant/verify-foundations.sh

    # Track 2 (Lima): repo is mounted at /host inside the VM
    bash /host/verify-foundations.sh

## Section 2: File Management and Permissions

Hardened the team folders and added a shared dropbox. Setgid makes team
ownership reliable; the sticky bit makes the dropbox tamper-resistant.
A permissions test report records what was attempted and what happened.

### Updated directory modes

| Path                  | Owner:Group        | Mode   | What's special                            |
|-----------------------|--------------------|--------|-------------------------------------------|
| `/shared/engineering` | `root:engineering` | `2770` | setgid set                                |
| `/shared/marketing`   | `root:marketing`   | `2770` | setgid set                                |
| `/shared/operations`  | `root:operations`  | `2770` | setgid set                                |
| `/shared/dropbox`     | `root:admins`      | `1773` | sticky bit; others can write but not list |

### Verification

`verify-permissions.sh` checks the team folders, the dropbox, the sample
files, and setgid propagation. Run it on the VM with:

    # Track 1 (Vagrant): repo is mounted at /vagrant
    bash /vagrant/verify-permissions.sh

    # Track 2 (Lima): repo is mounted at /host inside the VM
    bash /host/verify-permissions.sh

## Section 3: User Onboarding Automation

Replaced Section 1's manual user-creation work with a single script,
`scripts/onboard-user.sh`, that takes either an interactive prompt or a
CSV of new hires. Strict mode catches failures early, a `create_user`
function carries the four mutating commands, and `--dry-run` lets the
script be exercised without touching real accounts.

### Script flags

| Flag             | Purpose                                                   |
|------------------|-----------------------------------------------------------|
| `--csv PATH`     | Read users from a CSV (`username,group,fullname`)         |
| `--dry-run`      | Print intended actions without creating anything          |
| `-h`, `--help`   | Print the Usage block from the script header              |

A sample CSV ships at `data/new-hires.csv` for repeat runs and
idempotency checks.

### Verification

`verify-onboarding.sh` walks the script and the CSV end-to-end and
prints a ✅ or ❌ for each requirement. Run it on the VM with:

    # Track 1 (Vagrant): repo is mounted at /vagrant
    bash /vagrant/verify-onboarding.sh

    # Track 2 (Lima): repo is mounted at /host inside the VM
    bash /host/verify-onboarding.sh

## Section 4: Backup Automation

Built two scheduled scripts to keep the team folders backed up.
`scripts/backup-shared.sh` archives the whole `/shared` tree (excluding the
backup directory itself) into a date-stamped `.tar.gz` under
`/shared/backups`, with a `trap` that removes a partial archive if the
script is interrupted mid-run. `scripts/cleanup-backups.sh` prunes archives
older than seven days, with a `--preview` flag that lists what would go
without deleting anything. Root cron drives both.

### Schedule

| Script                       | Schedule    | Log file                         |
|------------------------------|-------------|----------------------------------|
| `scripts/backup-shared.sh`   | `0 2 * * *` | `/var/log/cloudbyte-backup.log`  |
| `scripts/cleanup-backups.sh` | `0 3 * * 0` | `/var/log/cloudbyte-cleanup.log` |

### Verification

`verify-backup.sh` walks the backup directory, both scripts, and the
crontab in one go and prints a ✅ or ❌ for each requirement. Run it on
the VM with:

    # Vagrant: repo is mounted at /vagrant
    bash /vagrant/verify-backup.sh

    # Lima: repo is mounted at /host inside the VM
    bash /host/verify-backup.sh

## Section 6: EC2 Deployment

Deployed the CloudByte server to a t3.micro Amazon Linux 2023 EC2 instance.
Rebuilt the four groups, the twelve users (kate and leo dual-grouped into
`admins`), and the full `/shared/` tree from scratch on the new host. Sent the
two existing docs and the three scripts across with `scp`, re-established the
backup and cleanup cron pipeline with EC2-absolute paths, and wrote a reflective
`differences-log.txt` recording what changed between the local VM and the cloud.

Files added this section:
- `verify-ec2.sh`: runs on EC2, checks the whole deployment from scratch.
- `data/cloudbyte-users.csv`: the twelve-staffer production roster.
- `docs/differences-log.txt`: local-VM-versus-EC2 reflection.

## Section 7: Log Analysis Tools

Built two log-analysis scripts on the EC2 server. `log-generator.sh` fabricates a
synthetic application log at `/logs/cloudbyte-app.log` with weighted severity
levels spread across the day. `analyse-logs.sh` summarises it into a timestamped
report under `/logs/reports/`: counts by severity, the busiest hour, and every
CRITICAL entry, using a `sort | uniq -c | sort -rn` pipeline. Scheduled the
analysis hourly via cron, and added `verify-logs.sh` to check the lot.

## Section 8: System Health Dashboard

Built system-health.sh on the EC2 server. It snapshots uptime/load, memory,
disk, the top processes by CPU, the status of crond and sshd, and logged-in
users into a printf-formatted, timestamped report under /logs/health-reports/.
It raises basic alerts (disk over 80%, zombie processes, a monitored service
down) and archives reports older than a week. Scheduled every 2 hours via cron,
and added verify-health.sh to check the lot.

## Section 9: Administration Menu

Created `scripts/admin-menu.sh`, an interactive menu that provides a single
 entry point for CloudByte's Linux administration tools:

- User onboarding
- Shared-directory backups
- Backup cleanup
- Test log generation
- Application log analysis
- System health reporting

The menu checks whether a tool is installed before running it, handles invalid selections,
provides usage instructions, and requires root privileges for administration tasks.

### Verification

`verify-menu.sh` tests that the menu is executable, displays help without root privileges,
enforces the root guard, dispatches valid selections, rejects invalid input, and handles missing tools safely.

Run the verification script without `sudo`:

```bash
bash verify-menu.sh
