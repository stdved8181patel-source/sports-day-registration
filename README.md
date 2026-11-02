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
