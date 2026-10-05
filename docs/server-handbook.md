# CloudByte Solutions Server Handbook

## Server overview

CloudByte's Linux server provides shared team storage, company documents, backup services, and routine administration tooling for Engineering, Marketing, and Operations. 
The server started with the basic user, group, and shared-folder structure and has since been extended with controlled permissions, backup automation, retention cleanup, 
scheduled jobs, and verification scripts. The design follows least privilege so staff can work in their own team areas while administrators retain the additional access 
required for operations work.

Rationale: The server has evolved from a basic shared Linux system into a small, automated operations platform with access control, backups, and self-checks.

## Users and groups

CloudByte runs with twelve staff across three teams: Engineering, Marketing, and Operations. Each team has its own group, and two Operations staff also sit in the `admins` 
group for sysadmin work. Every user has a standard home directory and a shell login.

| Username | Full name       | Group(s)           | Department  |
|----------|-----------------|--------------------|-------------|
| alice    | Alice Tan       | engineering        | Engineering |
| bob      | Bob Patel       | engineering        | Engineering |
| carol    | Carol O'Sullivan| engineering        | Engineering |
| dave     | Dave Yamamoto   | engineering        | Engineering |
| emma     | Emma Kowalski   | marketing          | Marketing   |
| frank    | Frank Nguyen    | marketing          | Marketing   |
| grace    | Grace Okafor    | marketing          | Marketing   |
| henry    | Henry Mendez    | operations         | Operations  |
| iris     | Iris Brennan    | operations         | Operations  | 
| jack     | Jack Hossain    | operations         | Operations  |
| kate     | Kate Reilly     | operations, admins | Operations  |
| leo      | Leo Costa       | operations, admins | Operations  |

| Group       | Members                      | Access                                                                        |
|-------------|------------------------------|-------------------------------------------------------------------------------|
| engineering | alice, bob, carol, dave      | Read/write to `/shared/engineering`                                           |
| marketing   | emma, frank, grace           | Read/write to `/shared/marketing`                                             |
| operations  | henry, iris, jack, kate, leo | Read/write to `/shared/operations`                                            |
| admins      | kate, leo                    | Write to `/shared/company-docs` and `/logs/reports`; read dropbox submissions |

Admins post to the company notice board and reports directories and triage the dropbox; team members write only to their own folder. Least-privilege as usual.

## Server layout

The shared storage lives below `/shared/`. Each department has its own directory and group ownership, while administrative areas are restricted to the appropriate users. 
The backup directory is owned by `root`, belongs to the `admins` group, and uses setgid permissions so new files inherit the `admins` group.

```text
/shared/
├── engineering/       engineering:engineering
├── marketing/         marketing:marketing
├── operations/        operations:operations
├── company-docs/      root:admins
├── dropbox/           root:admins
└── backups/           root:admins


The important permissions are:

| Path                   | Owner | Group       | Mode             | Purpose           |
| ---------------------- | ----- | ----------- | ---------------- | ----------------- |
| `/shared/engineering`  | root  | engineering | team-controlled  | Engineering files |
| `/shared/marketing`    | root  | marketing   | team-controlled  | Marketing files   |
| `/shared/operations`   | root  | operations  | team-controlled  | Operations files  |
| `/shared/company-docs` | root  | admins      | admin-controlled | Company documents |
| `/shared/dropbox`      | root  | admins      | admin-controlled | Submitted files   |
| `/shared/backups`      | root  | admins      | `2770`           | Backup archives   |

The /shared/backups directory uses 2770, which gives the owner and group full access, denies access to others, and enables setgid group inheritance.

Rationale: Group ownership and least-privilege permissions keep departmental data separated while allowing administrators to manage shared operational areas.

## Scripts inventory

The scripts/ directory contains the server administration and verification scripts used to manage users, backups, cleanup, and routine checks.

| Script               | Purpose                                                                                                                | Trigger                                              |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| `onboard-user.sh`    | Creates a user, sets a temporary password, adds the user to a team group, and forces a password change at first login. | Manual administrator operation                       |
| `backup-shared.sh`   | Creates a compressed backup archive of `/shared`.                                                                      | Scheduled cron job or manual administrator operation |
| `cleanup-backups.sh` | Removes backup archives older than the configured retention period. Supports `--preview`.                              | Scheduled cron job or manual administrator operation |
| `verify-backup.sh`   | Verifies that the expected backup archive exists and can be checked successfully.                                      | Manual self-check                                    |
| `verify-*.sh`        | Additional verification scripts confirm server configuration and required permissions.                                 | Manual self-check                                    |

Administrative scripts should normally be run with sudo because they modify users, permissions, or system backup data.

Rationale: Keeping operational tasks in small, documented scripts makes routine administration repeatable and reduces manual errors.

## Scheduled jobs

CloudByte uses cron to automate recurring maintenance tasks. The backup job creates the daily shared-data archive and records its activity in the backup log.

| Schedule                                                                             | Command                                   | Log path                              |
| ------------------------------------------------------------------------------------ | ------------------------------------------| ------------------------------------- |
| `0 2 * * * /vagrant/scripts/backup-shared.sh >> /var/log/cloudbyte-backup.log 2>&1   | `sudo /vagrant/scripts/backup-shared.sh`  | `/var/log/cloudbyte-backup.log`       |
| `0 3 * * 0 /vagrant/scripts/cleanup-backups.sh >> /var/log/cloudbyte-cleanup.log 2>&1| `sudo /vagrant/scripts/cleanup-backups.sh'| `/var/log/cleanup-backups.log`        |

The backup log can be inspected with:  sudo tail -n 20 /var/log/cloudbyte-backup.log

Cron activity can be checked with:   sudo journalctl -t CROND --since "2 minutes ago"

To filter for the backup job:   sudo journalctl -t CROND --since "2 minutes ago" | grep "backup-shared.sh"

Rationale: Scheduled jobs remove repetitive manual work while logs and cron records provide evidence that automation actually ran.

## Common operations

The following commands cover common junior-sysadmin tasks on the server.

| Task                                | Command                                                                                                   |
| ----------------------------------- | --------------------------------------------------------------------------------------------------------- |
| Check shared storage                | `ls -la /shared`                                                                                          |
| Check backup directory              | `sudo ls -lah /shared/backups`                                                                            |
| Check backup directory permissions  | `ls -ld /shared/backups`                                                                                  |
| Run a shared-data backup manually   | `sudo bash scripts/backup-shared.sh`                                                                      |
| Preview old backups before deletion | `sudo bash scripts/cleanup-backups.sh --preview`                                                          |
| Remove expired backups              | `sudo bash scripts/cleanup-backups.sh`                                                                    |
| Check backup log                    | `sudo tail -n 20 /var/log/cloudbyte-backup.log`                                                           |
| Find today's recent backup          | `sudo find /shared/backups/ -maxdepth 1 -type f -name "cloudbyte-shared-$(date +%F).tar.gz" -mmin -2 -ls` |
| Check a user's groups               | `id username`                                                                                             |
| Check whether a group exists        | `getent group groupname`                                                                                  |
| Check whether a user exists         | `getent passwd username`                                                                                  |
| Check script syntax                 | `bash -n scripts/script-name.sh`                                                                          |

For a new user, confirm the requested group exists before creating the account, create the account with the onboarding script, and verify the resulting group membership 
with id username.

Rationale: Common operations are documented as short, copyable commands so a junior administrator can perform routine work consistently

## Self-checks

The verification scripts provide quick checks that the server configuration still matches the expected design.

Run the available verification scripts from the repository:   sudo bash scripts/verify-backup.sh, sudo bash scripts/verify-*.sh

The backup verification confirms that the expected backup archive is present and usable. The other verify-*.sh scripts confirm the corresponding server configuration, 
permissions, or setup requirements defined by the project.

Before committing changes, also check the handbook itself:  


