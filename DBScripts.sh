#!/bin/bash
source ./config.sh

function createDatabase {
    read -p "Enter new database name: " dbname
    if [[ -d "$DB_Dir/$dbname" ]]; then
        echo "❌ Database '$dbname' already exists!"
    else
        mkdir "$DB_Dir/$dbname"
        echo "✅ Database '$dbname' created."
    fi
}

function listDatabases {
    echo "📂 Existing Databases:"
    ls "$DB_Dir" | awk '{ print NR ". " $0 }'
}


function connectDatabase {
    listDatabases
    read -p "Enter database name to connect: " dbname
    if [[ -d "$DB_Dir/$dbname" ]]; then
        echo "🔌 Connected to '$dbname'"

        while true; do
            echo "----------------------------------------"
            echo "     Table Menu - [$dbname]"
            echo "----------------------------------------"
            echo "1. Create Table"
            echo "2. List Tables"
            echo "3. Drop Table"
            echo "4. Insert into Table"
            echo "5. Select From Table"
            echo "6. Delete From Table"
            echo "7. Update Table"
            echo "8. Back to Main Menu"
            echo "----------------------------------------"
            read -p "Choose an option [1-8]: " table_choice

            case $table_choice in
                1)
                    createTable ;;
                2)
                    listTables ;;
                3)
                    dropTable ;;
                4) 
                    insertIntoTable ;;
                5) 
                    selectFromTable ;;
                6) 
                    deleteFromTable ;;
                7) 
                    updateTable ;;
                8)
                    echo "↩️ Returning to Main Menu..."
                    break
                    ;;
                *)
                    echo "⚠️ Invalid option. Please choose between 1-4."
                    ;;
            esac

            echo ""  
        done

    else
        echo "❌ Database '$dbname' does not exist!"
    fi
}

function dropDatabase {
    read -p "Enter database name to drop: " dbname
    if [[ -d "$DB_Dir/$dbname" ]]; then
        rm -r "$DB_Dir/$dbname"
        echo "🗑️ Database '$dbname' deleted."
    else
        echo "❌ Database '$dbname' not found!"
    fi
}

function createTable {
    read -p "Enter new table name: " tablename
    table_path="$DB_Dir/$dbname/$tablename"
    if [[ -f "$table_path" ]]; then
        echo "❌ Table '$tablename' already exists!"
    else
        touch "$table_path"
        echo "✅ Table '$tablename' created."
    fi
}

function listTables {
    echo "📄 Tables in '$dbname':"
    ls "$DB_Dir/$dbname" | awk '{ print NR ". " $0 }'
}

function dropTable {
    read -p "Enter table name to drop: " tablename
    table_path="$DB_Dir/$dbname/$tablename"
    if [[ -f "$table_path" ]]; then
        rm "$table_path"
        echo "🗑️ Table '$tablename' deleted."
    else
        echo "❌ Table '$tablename' not found!"
    fi
}

function insertIntoTable {
    
}

function selectFromTable {

}

function deleteFromTable {

}

function updateTable {

}