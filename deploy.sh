#!/bin/bash
# ============================================================
# Linux+ Milestone 2 — Server Deployment Script
#
# Student:     Melanie Erickson
# Date:        07/23/2026
# Environment: Ubuntu 22.04 container (Docker)
# Scenario:    Deploy and harden a web server role
#
# HOW TO USE THIS SCRIPT:
#   1. Run ./run_container.sh to start your container environment
#   2. Inside the container, run: bash /opt/deploy/deploy.sh
#   3. Check output and fix any errors
#   4. Run ./test_deploy.sh to verify your deployment
#   5. Commit your work to GitHub with meaningful commit messages
#
# WHAT THIS SCRIPT MUST DO (each section is graded):
#   Section 1: Create a non-login service account
#   Section 2: Configure web root directory and permissions
#   Section 3: Install the web server package
#   Section 4: Enable and start the service
#   Section 5: Configure the firewall
#   Section 6: Set up log rotation via cron
#
# COMMENT REQUIREMENT:
#   Every section must have comments explaining WHAT you are doing and WHY.
#   Comments are graded. A correct command with no explanation earns partial credit.
#   A comment like "# add user" is not sufficient. Explain the security rationale.
#
# IMPORTANT NOTE ON SYSTEMCTL IN CONTAINERS:
#   systemctl may behave differently inside a Docker container than on a real server.
#   This is a known container limitation (systemd as PID 1 requires special flags).
#   You are expected to:
#     - Write the correct systemctl commands as you would on a real server
#     - Note in a comment what you observed when you ran the command
#     - Explain what you would verify on a production system
#   Full marks are awarded for correct syntax + honest documentation of container behavior.
# ============================================================

# ── LOGGING FUNCTION ─────────────────────────────────────────
# This function is provided for you. Use log "message" throughout your script
# to record what the script is doing. Required: all actions must appear in the log.
LOG_FILE="/var/log/deploy.log"

log() {
    # tee writes to both the terminal (so you can see it) and the log file
    echo "[$(date +%Y-%m-%dT%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

# Create log file directory if it doesn't exist
mkdir -p "$(dirname $LOG_FILE)"

log "============================================================"
log "Deployment script started"
log "Running as user: $(whoami)"
log "Environment: $(uname -a)"
log "============================================================"


# ── SECTION 1: Create Service Account ────────────────────────
# A service account is a user account created specifically to run a service or daemon.
# It should NOT be a regular login account.
#
# TODO: Create a user account named "webservice"
#       Requirements:
#         - No login shell (the account cannot be used to log in interactively)
#         - Home directory: /var/lib/webservice
#         - System account (use the appropriate flag)
#
# TODO: Add an explanatory comment that answers:
#         - Why should this account not have a login shell?
#         - What is the security risk if it does?
#         - Which flag sets a non-login shell and what value does it use?
#
# HINT: Look up: useradd --help or man useradd
#       Key flags: -r (system account), -s (shell), -d (home directory), -m (create home)

# YOUR CODE HERE: 

useradd -r -s /usr/sbin/nologin -d /var/lib/webservice -m webservice


#should not have interactive log indue to it usually having permissions needed for an application to function.
#attackers get the password, now they have access to files, logs, etc.
log "Section 1 complete"


# ── SECTION 2: Configure Web Root Permissions ─────────────────
# The web root is where web server files are served from.
# Incorrect permissions here are a common security vulnerability.
#
# TODO: Create the directory /var/www/html if it does not already exist
#       Hint: mkdir with a flag to create parent directories silently
#
# TODO: Set the ownership of /var/www/html to the webservice account
#       The webservice user should own the files it serves.
#
# TODO: Set permissions on /var/www/html
#       The directory should be: owner=rwx, group=rx, other=rx
#       Translated to numeric: ???
#
# TODO: Create a simple placeholder index.html owned by webservice
#
# TODO: Add comments explaining:
#         - What does each part of the permission value mean? (owner/group/other)
#         - Why should "other" not have write permission on a web root?
#         - What is the numeric permission value you chose and why?

# YOUR CODE HERE: 
mkdir -p /var/www/html
chown webservice:webservice /var/www/html
chmod 755 /var/www/html
echo "<h1>Welcome to Web Service</h1>" > /var/www/html/index.html
chown webservice:webservice /var/www/html/index.html
#    - Verify 
ls -ld /var/www/html


#ovwer has rwx (read, write, execute)
#group and other has r and x (read and execute)
#others should have the ability to write because they should have access to edit or modify files or applications
#need to know 
#755 is the numeric permissions i set because it 7 is for the owner have the read(4) write(2) and execute(1)
#group and others read(4) and execute (1) giving 5 
log "Section 2 complete"


# ── SECTION 3: Install Web Server Package ─────────────────────
# Package managers install, update, and remove software on Linux systems.
# In Ubuntu/Debian systems, the package manager is apt.
#
# TODO: Install the apache2 web server package using apt-get
#       The -y flag accepts prompts automatically (required for scripting)
#       The DEBIAN_FRONTEND=noninteractive variable is already set in the Dockerfile
#
# TODO: Verify the installation succeeded before continuing
#       Hint: check the exit code ($?) after the install command
#       If it failed, log a message and exit with a non-zero status
#
# TODO: Add comments explaining:
#         - Why apache2 and not another web server?
#         - What does the -y flag do and why is it necessary in a script?
#         - What does verifying the exit code protect against?

# YOUR CODE HERE:
apt-get update

apt-get install -y apache2



log "Section 3 complete"


# ── SECTION 4: Enable and Start the Service ───────────────────
# systemd manages services on modern Linux systems.
# Two separate steps: enable (start at boot) and start (start now).
#
# TODO: Enable the apache2 service to start automatically at boot
#       Command: systemctl enable apache2
#
# TODO: Start the apache2 service
#       Command: systemctl start apache2
#
# TODO: IMPORTANT — Document your container observations:
#       Run these commands and note what happens.
#       In a standard Docker container, systemctl may print an error or behave
#       differently than on a real server. This is expected.
#
# TODO: Add comments explaining:
#         - What is the difference between systemctl enable and systemctl start?
#         - What would you run on a real server to verify the service is running?
#         - What did you observe when you ran systemctl in this container?
#           (Document the actual output or error you saw)
#         - Why does systemctl behave differently in a container vs. a real server?

# YOUR CODE HERE:
systemctl enable apache2

systemctl start apache2


#system enable is to start the service on boot
#system start starts it immediately 
#systemctl status <service-name> would be run to check the status of a service
#the two behave differently because docker containers dont fun Linux in full and servers will.
# recieved bash: docker: command not found
log "Section 4 complete"


# ── SECTION 5: Configure Firewall ────────────────────────────
# A firewall controls which network traffic is allowed in and out.
# ufw (Uncomplicated Firewall) provides a simplified interface to iptables.
#
# TODO: Allow inbound HTTP traffic (port 80/tcp)
# TODO: Allow inbound HTTPS traffic (port 443/tcp)
# TODO: Enable the firewall
#       Use --force flag to avoid interactive "y/n" prompt in a script
#
# TODO: Add comments explaining:
#         - Why do we need both port 80 and port 443?
#         - What is the default ufw policy for inbound traffic before you run these commands?
#         - What container-specific behavior did you observe with ufw?
#           (ufw may print warnings in a container — document what you saw)
#
# HINT: ufw --help or man ufw
#       ufw allow PORT/PROTOCOL, then ufw --force enable

# YOUR CODE HERE:
#install ufw
apt-get update
apt-get install -y ufw
#allow inbound by port 80 http
ufw allow 80/tcp
#allow inbound by port 443 https
ufw allow 443/tcp
#enable firewall
ufw --force enable
#verify
ufw status verbose

log "Section 5 complete"


# ── SECTION 6: Log Rotation Cron Job ─────────────────────────
# Log files grow indefinitely without rotation. Log rotation compresses
# old logs and removes files beyond a retention limit.
# A cron job schedules this task to run automatically.
#
# TODO: Add a cron job that runs logrotate weekly
#       The cron job should run as root (add to root's crontab)
#       Cron syntax: minute hour day month weekday command
#       For weekly: 0 2 * * 0 (2am every Sunday)
#       Command: /usr/sbin/logrotate /etc/logrotate.conf
#
# TODO: Log a confirmation that the cron entry was added
#
# TODO: Add comments explaining: 
#         - What happens if log rotation is never configured?
#         - What does each field in the cron expression mean?
#         - What is /etc/logrotate.conf and what does it control?
#
# HINT: To add a cron job from a script without overwriting existing crontab:
#       (crontab -l 2>/dev/null; echo "0 2 * * 0 /usr/sbin/logrotate /etc/logrotate.conf") | crontab -

# YOUR CODE HERE:
crontab -e
#add logrotate entry without overwriting
#    crontab -l gets existing root cron jobs
#    2>/dev/null hides the "no crontab" error if none exist
#    echo adds your new job
#    crontab - installs the combined file

(crontab -l 2>/dev/null; echo "0 2 * * 0 /usr/sbin/logrotate /etc/logrotate.conf") | crontab -
#verify
crontab -l


log "Section 6 complete"
log "============================================================"
log "Deployment script completed"
log "Run test_deploy.sh to verify your deployment"
log "============================================================"
