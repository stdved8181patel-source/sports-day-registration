#!/bin/bash
# ============================================================
# L81 - SPORTS DAY REGISTRATION
# Linux Operating System Lab
# Student: PATEL VED VIPULKUMAR   Roll: D39   Div: H
# Enrollment: 24004501210289
# Folder: ~/linux_project/sportsday
# Run: bash setup_sportsday.sh
# ============================================================

P="$HOME/linux_project/sportsday"

if [ -d "$P" ]; then
    echo "Folder already exists: $P"
    echo "Please rename or backup the existing folder first."
    exit 1
fi

mkdir -p "$P"/{lib,data,reports,backups,logs}
cd "$P" || exit 1

# ------------------------------------------------------------
# SAMPLE DATA  (32 registrations)
# columns: roll,name,house,event
# ------------------------------------------------------------

cat > data/participants.csv <<'DATA'
roll,name,house,event
G01,AARAV,Red,100m
G02,DIYA,Blue,Chess
G03,KABIR,Red,Long Jump
G04,ISHITA,Green,200m
G05,RUDRA,Yellow,100m
G06,ANANYA,Blue,High Jump
G07,VIHAAN,Green,Shot Put
G08,MEERA,Yellow,Carrom
G09,ADITYA,Red,200m
G10,SANVI,Blue,100m
G11,KRISH,Green,Long Jump
G12,NISHA,Yellow,Chess
G13,YASH,Red,Shot Put
G14,PRIYA,Blue,Carrom
G15,HARSH,Green,100m
G16,TANVI,Yellow,High Jump
G17,DEV,Red,Relay
G18,RIYA,Blue,Relay
G19,JAY,Green,Relay
G20,KHUSHI,Yellow,Relay
G21,MIHIR,Red,Chess
G22,AVNI,Blue,200m
G23,PARTH,Green,Carrom
G24,SIYA,Yellow,Long Jump
G25,NEEL,Red,High Jump
G26,POOJA,Blue,Shot Put
G27,RAJ,Green,High Jump
G28,KAVYA,Yellow,200m
G29,ARJUN,Red,Carrom
G30,TIYA,Blue,Long Jump
G01,AARAV,Red,Long Jump
G10,SANVI,Blue,200m
DATA

# ------------------------------------------------------------
# FUNCTIONS
# ------------------------------------------------------------

cat > lib/functions.sh <<'FUNCTIONS'
#!/bin/bash
# lib/functions.sh - all functions for Sports Day Registration

DATA="data/participants.csv"
LOG="logs/activity.log"

# the events and houses that are allowed
EVENTS=("100m" "200m" "Long Jump" "High Jump" "Shot Put" "Relay" "Chess" "Carrom")
HOUSES=("Red" "Blue" "Green" "Yellow")

# write one line to the activity log
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $*" >> "$LOG"
}

# check the data file exists before using it
check_data() {
    if [ ! -f "$DATA" ]; then
        echo "Data not found: $DATA"
        return 1
    fi
}

show_help() {
    echo "Sports Day Registration"
    echo "Usage: ./main.sh            -> open the menu"
    echo "       ./main.sh --help     -> show this help"
    echo "       ./main.sh --backup   -> backup data/ now"
    echo "       ./main.sh --cron     -> run the scheduled (crontab) task"
}

# ask the user to pick one event from the list (result in $event)
choose_event() {
    local i=1 c
    echo "Select Event:"
    for e in "${EVENTS[@]}"; do
        echo "  $i) $e"
        i=$((i + 1))
    done
    read -r -p "Choose event number: " c
    if [[ ! $c =~ ^[0-9]+$ ]] || [ "$c" -lt 1 ] || [ "$c" -gt "${#EVENTS[@]}" ]; then
        echo "Invalid event number."
        return 1
    fi
    event="${EVENTS[$((c - 1))]}"
}

# ask the user to pick one house from the list (result in $house)
choose_house() {
    local i=1 c
    echo "Select House:"
    for h in "${HOUSES[@]}"; do
        echo "  $i) $h"
        i=$((i + 1))
    done
    read -r -p "Choose house number: " c
    if [[ ! $c =~ ^[0-9]+$ ]] || [ "$c" -lt 1 ] || [ "$c" -gt "${#HOUSES[@]}" ]; then
        echo "Invalid house number."
        return 1
    fi
    house="${HOUSES[$((c - 1))]}"
}

view_data() {
    check_data || return
    echo
    echo "========== ALL REGISTRATIONS =========="
    cat -n "$DATA"
    echo "Total registrations: $(($(wc -l < "$DATA") - 1))"
    log "Viewed all data"
}

do_backup() {
    check_data || return
    mkdir -p backups
    f="backups/data_$(date +%Y%m%d_%H%M%S).tar.gz"
    if tar -czf "$f" data/; then
        echo "Backup saved: $f ($(du -h "$f" | cut -f1))"
        log "backup created $f"
    else
        echo "Backup failed."
    fi
}

view_log() {
    if [ -f "$LOG" ]; then
        echo "========== ACTIVITY LOG (last 15) =========="
        tail -n 15 "$LOG"
    else
        echo "No activity yet."
    fi
}

# ------------------------------------------------------------
# FEATURE 1: Register a student with a duplicate check
# ------------------------------------------------------------
feature_1() {
    check_data || return
    echo
    echo "========== REGISTER A STUDENT =========="

    read -r -p "Enter roll (e.g. G31): " roll
    read -r -p "Enter name: " name

    # validation: empty values
    if [ -z "$roll" ] || [ -z "$name" ]; then
        echo "Roll and name cannot be empty."
        return
    fi
    # validation: no commas (it would break the CSV)
    if [[ "$roll$name" == *","* ]]; then
        echo "Commas are not allowed."
        return
    fi
    # validation: roll format = one letter + digits
    if [[ ! $roll =~ ^[A-Za-z][0-9]+$ ]]; then
        echo "Roll must be one letter followed by numbers (example: G31)."
        return
    fi

    roll=$(echo "$roll" | tr 'a-z' 'A-Z')
    name=$(echo "$name" | tr 'a-z' 'A-Z')

    # if this roll is already known, reuse the saved name and house
    old=$(grep -m1 -i "^$roll," "$DATA")
    if [ -n "$old" ]; then
        old_name=$(echo "$old" | cut -d',' -f2)
        house=$(echo "$old" | cut -d',' -f3)
        if [ "$old_name" != "$name" ]; then
            echo "Roll $roll already belongs to $old_name. Name does not match."
            return
        fi
        echo "Known student: $old_name ($house house)"
    else
        choose_house || return
    fi

    choose_event || return

    # DUPLICATE CHECK: same roll + same event is not allowed
    if grep -q -i "^$roll,.*,$event$" "$DATA"; then
        echo "DUPLICATE: $roll is already registered for $event. Not saved."
        log "duplicate blocked: $roll $event"
        return
    fi

    echo "$roll,$name,$house,$event" >> "$DATA"
    echo "Saved! $name ($house) registered for $event."
    log "registered $roll $name $house $event"
}

# ------------------------------------------------------------
# FEATURE 2: Show participant count per event (uniq -c)
# ------------------------------------------------------------
feature_2() {
    check_data || return
    echo
    echo "========== PARTICIPANTS PER EVENT =========="
    echo "Count  Event"
    tail -n +2 "$DATA" | cut -d',' -f4 | sort | uniq -c | sort -nr
    echo "-----------------"
    echo "Total registrations: $(($(wc -l < "$DATA") - 1))"
    log "Viewed participant count per event"
}

# ------------------------------------------------------------
# FEATURE 3: Show the list for one house
# ------------------------------------------------------------
feature_3() {
    check_data || return
    echo
    echo "========== HOUSE LIST =========="
    choose_house || return

    echo
    echo "Participants of $house house:"
    printf "%-6s %-10s %s\n" "ROLL" "NAME" "EVENT"
    grep -i ",$house," "$DATA" | sort | awk -F',' '{ printf "%-6s %-10s %s\n", $1, $2, $4 }'
    echo "Total: $(grep -c -i ",$house," "$DATA")"
    log "Viewed list for $house house"
}

# ------------------------------------------------------------
# FEATURE 4: Create a certificate text file for each winner
#            (here-document inside a for loop)
# ------------------------------------------------------------
feature_4() {
    check_data || return
    echo
    echo "========== CREATE WINNER CERTIFICATES =========="
    choose_event || return

    mkdir -p reports/certificates
    made=0

    for pos in 1 2 3; do
        case $pos in
            1) place="FIRST" ;;
            2) place="SECOND" ;;
            3) place="THIRD" ;;
        esac

        read -r -p "Roll of $place place winner (Enter to skip): " wroll
        [ -z "$wroll" ] && continue

        # the winner must be registered for this event
        row=$(grep -m1 -i "^$wroll,.*,$event$" "$DATA")
        if [ -z "$row" ]; then
            echo "  $wroll is not registered for $event. Skipped."
            continue
        fi

        wname=$(echo "$row" | cut -d',' -f2)
        whouse=$(echo "$row" | cut -d',' -f3)
        wroll=$(echo "$row" | cut -d',' -f1)
        file="reports/certificates/${wroll}_${event// /_}_${place}.txt"

        cat > "$file" <<CERT
==================================================
              SPORTS DAY CERTIFICATE
==================================================

   This is to certify that

        $wname  (Roll: $wroll)
        of $whouse House

   has secured $place PLACE in the event

        $event

   Date: $(date '+%d-%m-%Y')

   Sports Committee Signature: ____________________
==================================================
CERT
        echo "  Certificate created: $file"
        log "certificate created $file"
        made=$((made + 1))
    done

    echo "Certificates created: $made"
}

# ------------------------------------------------------------
# FEATURE 5: Remove a registration (sed -i)
# ------------------------------------------------------------
feature_5() {
    check_data || return
    echo
    echo "========== REMOVE A REGISTRATION =========="
    read -r -p "Enter roll to remove: " key

    if [ -z "$key" ]; then
        echo "Roll cannot be empty."
        return
    fi
    if [[ ! $key =~ ^[A-Za-z][0-9]+$ ]]; then
        echo "Invalid roll format (example: G31)."
        return
    fi
    if ! grep -q -i "^$key," "$DATA"; then
        echo "Not found"
        return
    fi

    echo "Registrations for $key:"
    grep -i "^$key," "$DATA"

    choose_event || return
    if ! grep -q -i "^$key,.*,$event$" "$DATA"; then
        echo "$key is not registered for $event."
        return
    fi

    read -r -p "Delete $key from $event? (y/n): " ans
    if [ "$ans" != "y" ] && [ "$ans" != "Y" ]; then
        echo "Cancelled."
        return
    fi

    # safety: copy the file first because sed -i changes it directly
    cp "$DATA" "$DATA.bak"
    sed -i "/^$key,.*,$event\$/Id" "$DATA"
    echo "Removed. (safety copy: $DATA.bak)"
    log "removed $key $event"
}

# ------------------------------------------------------------
# CRON TASK: Every day at 6 PM, back up participants.csv with tar -czf
# Runs when crontab calls:  ./main.sh --cron
# ------------------------------------------------------------
cron_task() {
    check_data || return
    mkdir -p backups reports
    f="backups/participants_$(date +%Y%m%d_%H%M%S).tar.gz"
    if tar -czf "$f" "$DATA"; then
        echo "$(date '+%Y-%m-%d %H:%M') cron backup OK: $f ($(du -h "$f" | cut -f1))" >> reports/cron_output.txt
        log "cron task ran - backup $f"
        echo "Cron backup created: $f"
    else
        echo "$(date '+%Y-%m-%d %H:%M') cron backup FAILED" >> reports/cron_output.txt
        log "cron task FAILED"
    fi
}
FUNCTIONS

# ------------------------------------------------------------
# MAIN MENU
# ------------------------------------------------------------

cat > main.sh <<'MAIN'
#!/bin/bash
# main.sh - L81 Sports Day Registration
# Menu-driven shell script (while loop + case)

cd "$(dirname "$0")" || exit 1

source lib/functions.sh

case "$1" in
    --help)   show_help; exit 0 ;;
    --backup) do_backup; exit 0 ;;
    --cron)   cron_task; exit 0 ;;
esac

while true; do
    echo
    echo "========== SPORTS DAY REGISTRATION =========="
    echo "1) Register a student with a duplicate check"
    echo "2) Show participant count per event (uniq -c)"
    echo "3) Show the list for one house"
    echo "4) Create a certificate text file for each winner"
    echo "5) Remove a registration (sed -i)"
    echo "6) View data"
    echo "7) Backup data (tar.gz)"
    echo "8) View activity log"
    echo "0) Exit"
    read -r -p "Choose an option: " ch

    case "$ch" in
        1) feature_1 ;;
        2) feature_2 ;;
        3) feature_3 ;;
        4) feature_4 ;;
        5) feature_5 ;;
        6) view_data ;;
        7) do_backup ;;
        8) view_log ;;
        0) echo "Bye!"; break ;;
        *) echo "Invalid choice, try again." ;;
    esac
done
MAIN

# ------------------------------------------------------------
# README
# ------------------------------------------------------------

cat > README.md <<'README'
# L81 - Sports Day Registration

**Student:** PATEL VED VIPULKUMAR | **Roll:** D39 | **Division:** H | **Enrollment:** 24004501210289

**Subject:** Linux Operating System Lab | **Project ID:** L81

## Problem

Build a sports-day registration system that prevents duplicates and
creates certificates.

## Who will use it

Sports committee members.

## Data file

`data/participants.csv` has 32 registrations with 4 columns:

| Column | Meaning |
|--------|---------|
| roll   | Student roll number (one letter + digits, e.g. G01) |
| name   | Student name in capital letters |
| house  | House team: Red, Blue, Green or Yellow |
| event  | Event: 100m, 200m, Long Jump, High Jump, Shot Put, Relay, Chess, Carrom |

One student can join many events, but the same roll cannot be
registered twice for the same event (duplicate check).

## Folder structure

- main.sh - menu (run with ./main.sh)
- lib/functions.sh - all functions
- data/participants.csv - registrations
- reports/ - certificates (reports/certificates) and cron_output.txt
- backups/ - tar.gz backups
- logs/ - activity.log and cron.log

## Features

1. Register a student with a duplicate check
2. Show participant count per event (uniq -c)
3. Show the list for one house
4. Create a certificate text file for each winner (here-document in a loop)
5. Remove a registration (sed -i)
6. View data
7. Backup data (tar.gz)
8. View activity log

## How to run

    cd ~/linux_project/sportsday
    ./main.sh
    ./main.sh --help
    ./main.sh --backup

## Crontab task

Every day at 6 PM, back up participants.csv with tar -czf

    0 18 * * * /bin/bash $HOME/linux_project/sportsday/main.sh --cron >> $HOME/linux_project/sportsday/logs/cron.log 2>&1

## Commands used

grep, sed -i, sort, uniq -c, here-document, for loop, awk, cut, tar, date, crontab

## What I learned

I learned how to build a menu-driven Bash application with functions,
while loops and case statements. I used grep for the duplicate check,
sort and uniq -c for counting, a here-document inside a for loop to
create certificates, and sed -i to remove a record safely after
taking a copy. I also learned input validation, logging, tar.gz
backups and scheduling a daily task with crontab.
README

# ------------------------------------------------------------
# PERMISSIONS AND INITIAL FILES
# ------------------------------------------------------------

chmod +x main.sh lib/functions.sh
touch logs/activity.log

echo
echo "======================================"
echo " SPORTS DAY REGISTRATION SETUP COMPLETE"
echo "======================================"
echo "Project Folder: $P"
echo
ls -R "$P"

echo
echo "Next Commands:"
echo "cd ~/linux_project/sportsday"
echo "./main.sh"
