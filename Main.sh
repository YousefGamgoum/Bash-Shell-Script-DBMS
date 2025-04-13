#!/bin/bash
source ./config.sh
source ./DBScripts.sh

mkdir -p "$DB_Dir"

while true; do
    echo "------------------------"
    echo "     Main Menu"
    echo "------------------------"
    echo "1. Create Database"
    echo "2. List Databases"
    echo "3. Connect To Database"
    echo "4. Drop Database"
    echo "5. Exit"
    echo "------------------------"
    read -p "Choose an option [1-5]: " choice

    case $choice in
        1)
            createDatabase ;;
        2)
            listDatabases ;;
        3)
            connectDatabase ;;
        4)
            dropDatabase ;;
        5)
            echo "Exiting... Bye!"
            break
            ;;
        *)
            echo "Invalid option. Please choose between 1-5."
            ;;
    esac

    echo ""
done