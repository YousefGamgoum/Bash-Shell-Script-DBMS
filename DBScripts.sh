#!/bin/bash
source ./config.sh

function createDatabase {
    read -p "Enter new database name: " dbname
    if [[ -d "$DB_Dir/$dbname" ]]; then
        echo "Database '$dbname' already exists!"
    else
        mkdir "$DB_Dir/$dbname"
        echo "Database '$dbname' created."
    fi
}

function listDatabases {
    echo "Existing Databases:"
    ls "$DB_Dir" | awk '{ print NR ". " $0 }'
}

function connectDatabase {
    listDatabases
    read -p "Enter database name to connect: " dbname
    if [[ -d "$DB_Dir/$dbname" ]]; then
        echo "Connected to '$dbname'"

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
                    echo "Returning to Main Menu..."
                    break
                    ;;
                *)
                    echo "Invalid option. Please choose between 1-8."
                    ;;
            esac

            echo ""  
        done

    else
        echo "Database '$dbname' does not exist!"
    fi
}

function dropDatabase {
    read -p "Enter database name to drop: " dbname
    if [[ -d "$DB_Dir/$dbname" ]]; then
        rm -r "$DB_Dir/$dbname"
        echo "Database '$dbname' deleted."
    else
        echo "Database '$dbname' not found!"
    fi
}

function listTables {
    echo "Tables in '$dbname':"
    ls "$DB_Dir/$dbname" | awk '{ print NR ". " $0 }'
}

function dropTable {
    read -p "Enter table name to drop: " tablename
    table_path="$DB_Dir/$dbname/$tablename"
    if [[ -f "$table_path" ]]; then
        rm "$table_path"
        echo "Table '$tablename' deleted."
    else
        echo "Table '$tablename' not found!"
    fi
}

function createTable {
    read -p "Enter table name: " tablename
    table_path="$DB_Dir/$dbname/$tablename"

    if [[ -f "$table_path" ]]; then
        echo "Table already exists!"
        return
    fi

    read -p "Enter number of columns: " col_count
    columns=()
    pk_set=false
    pk_name=""

    for ((i=1; i<=col_count; i++)); do
        read -p "Column #$i name: " col_name
        read -p "Column #$i type [int|string]: " col_type
        columns+=("$col_name:$col_type")

        if ! $pk_set; then
            read -p "Is this column a Primary Key? [y/n]: " is_pk
            if [[ "$is_pk" == "y" ]]; then
                pk_name="$col_name"
                pk_set=true
            fi
        fi
    done

    if ! $pk_set; then
        echo "You must specify a Primary Key!"
        return
    fi

    {
        echo "#columns=${columns[*]}"
        echo "#pk=$pk_name"
    } > "$table_path"

    echo "Table '$tablename' created with $col_count columns. Primary Key: $pk_name"
}

function insertIntoTable {
    listTables
    read -p "Enter table name: " tablename
    table_path="$DB_Dir/$dbname/$tablename"

    if [[ ! -f "$table_path" ]]; then
        echo "Table '$tablename' does not exist!"
        return
    fi

   
    columns_line=$(head -n 1 "$table_path" | cut -d'=' -f2)
    pk_name=$(grep "^#pk=" "$table_path" | cut -d'=' -f2)

    IFS=' ' read -a ColHeaders <<< "$columns_line"
    col_names=()
    col_types=()
    for header in "${ColHeaders[@]}"; do
        name=$(echo "$header" | cut -d':' -f1)
        type=$(echo "$header" | cut -d':' -f2)
        col_names+=("$name")
        col_types+=("$type")
    done

    echo "Columns: ${col_names[*]}"
    echo "1. Insert into selected columns"
    echo "2. Insert into all columns"
    read -p "Choose insertion mode [1/2]: " mode

    row=()
    if [[ "$mode" == "1" ]]; then
        declare -A input_map
        read -p "Enter columns you want to insert into (separated by space): " -a selected_cols

        for col in "${selected_cols[@]}"; do
            for i in "${!col_names[@]}"; do
                if [[ "${col_names[$i]}" == "$col" ]]; then
                    read -p "Enter value for $col: " val
                    
                    if [[ "${col_types[$i]}" == "int" && ! "$val" =~ ^[0-9]+$ ]]; then
                        echo "Invalid int value for $col"
                        return
                    fi
                    input_map[$i]="$val"
                fi
            done
        done

  
        for i in "${!col_names[@]}"; do
            if [[ "${col_names[$i]}" == "$pk_name" ]]; then
                if [[ -z "${input_map[$i]}" ]]; then

                    last_pk=$(awk -F: -v index=$i '!/^#/ { print $index }' "$table_path" | sort -n | tail -n 1)
                    [[ -z "$last_pk" ]] && last_pk=0
                    input_map[$i]=$((last_pk + 1))
                    echo "Auto-incremented $pk_name = ${input_map[$i]}"
                else
           
                    if awk -F: -v index=$i -v val="${input_map[$i]}" '!/^#/ { if($index==val) exit 1 }' "$table_path"; then
                        echo "Primary key is unique"
                    else
                        echo "Duplicate primary key!"
                        return
                    fi
                fi
            fi
        done


        for i in "${!col_names[@]}"; do
            row+=("${input_map[$i]:-NULL}")
        done

    elif [[ "$mode" == "2" ]]; then
        for i in "${!col_names[@]}"; do
            read -p "Enter value for ${col_names[$i]}: " val
     
            if [[ "${col_types[$i]}" == "int" && ! "$val" =~ ^[0-9]+$ ]]; then
                echo "Invalid int value for ${col_names[$i]}"
                return
            fi

            if [[ "${col_names[$i]}" == "$pk_name" ]]; then
          
                if awk -F: -v idx=$i -v val="${input_map[$i]}" '!/^#/ { if($idx==val) exit 1 }' "$table_path"; then
                    echo "Primary key is unique"
                else
                    echo "Duplicate primary key!"
                    return
                fi

            fi
            row+=("$val")
        done
    else
        echo "Invalid option."
        return
    fi


    echo "${row[*]}" | tr ' ' ':' >> "$table_path"
    echo "Row inserted successfully."
}

function selectFromTable {
    listTables
    read -p "Enter table name: " tablename
    table_path="$DB_Dir/$dbname/$tablename"

    if [[ ! -f "$table_path" ]]; then
        echo "Table '$tablename' does not exist!"
        return
    fi

    columns_line=$(head -n 1 "$table_path" | cut -d'=' -f2)
    IFS=' ' read -a ColHeaders <<< "$columns_line"
    col_names=()
    for header in "${ColHeaders[@]}"; do
        col_names+=("$(echo "$header" | cut -d':' -f1)")
    done

    echo "1. Select all records"
    echo "2. Select with condition"
    read -p "Choose option [1/2]: " opt

    if [[ "$opt" == "2" ]]; then
        echo "Available columns: ${col_names[*]}"
        read -p "Enter column to filter by: " condition_col
        read -p "Enter value to match: " condition_value

        condition_index=-1
        for i in "${!col_names[@]}"; do
            if [[ "${col_names[$i]}" == "$condition_col" ]]; then
                condition_index=$i
                break
            fi
        done

        if [[ $condition_index -eq -1 ]]; then
            echo "Column not found!"
            return
        fi
    fi

    echo "3. Display all columns"
    echo "4. Display a specific column"
    read -p "Choose display mode [3/4]: " disp_opt

    if [[ "$disp_opt" == "4" ]]; then
        echo "Available columns: ${col_names[*]}"
        read -p "Enter column name to display: " display_col
        display_index=-1
        for i in "${!col_names[@]}"; do
            if [[ "${col_names[$i]}" == "$display_col" ]]; then
                display_index=$i
                break
            fi
        done

        if [[ $display_index -eq -1 ]]; then
            echo "Column not found!"
            return
        fi
    fi

    echo "Result:"
    echo "----------------------------------------"

    if [[ "$disp_opt" == "3" ]]; then
        printf "| "
        for name in "${col_names[@]}"; do
            printf "%-15s | " "$name"
        done
        echo
        echo "----------------------------------------"
    elif [[ "$disp_opt" == "4" ]]; then
        printf "| %-15s |\n" "$display_col"
        echo "-------------------------"
    fi

    found=false
    while IFS=':' read -a row; do
     
        if [[ "$opt" == "2" && "${row[$condition_index]}" != "$condition_value" ]]; then
            continue
        fi

        found=true
        if [[ "$disp_opt" == "3" ]]; then
            printf "| "
            for val in "${row[@]}"; do
                printf "%-15s | " "$val"
            done
            echo
        elif [[ "$disp_opt" == "4" ]]; then
            printf "| %-15s |\n" "${row[$display_index]}"
        fi
    done < <(tail -n +3 "$table_path")

    if ! $found; then
        echo "No records found matching your criteria."
    else
        echo "----------------------------------------"
    fi
}

function deleteFromTable {
    listTables
    read -p "Enter table name: " tablename
    table_path="$DB_Dir/$dbname/$tablename"

    if [[ ! -f "$table_path" ]]; then
        echo "Table '$tablename' does not exist!"
        return
    fi

 
    columns_line=$(head -n 1 "$table_path" | cut -d'=' -f2)
    IFS=' ' read -a ColHeaders <<< "$columns_line"
    col_names=()
    for header in "${ColHeaders[@]}"; do
        col_names+=("$(echo "$header" | cut -d':' -f1)")
    done

    echo "Available columns: ${col_names[*]}"
    read -p "Enter column to filter by: " condition_col
    read -p "Enter value to match for deletion: " condition_value

    condition_index=-1
    for i in "${!col_names[@]}"; do
        if [[ "${col_names[$i]}" == "$condition_col" ]]; then
            condition_index=$i
            break
        fi
    done

    if [[ $condition_index -eq -1 ]]; then
        echo "Column not found!"
        return
    fi

    tmp_file="${table_path}.tmp"
    header=$(head -n 2 "$table_path")
    echo "$header" > "$tmp_file"

    deleted_count=0

    while IFS=':' read -a row; do
        if [[ "${row[$condition_index]}" != "$condition_value" ]]; then
            echo "${row[*]}" | tr ' ' ':' >> "$tmp_file"
        else
            ((deleted_count++))
        fi
    done < <(tail -n +3 "$table_path")

    mv "$tmp_file" "$table_path"

    if [[ $deleted_count -eq 0 ]]; then
        echo "No matching records found to delete."
    else
        echo "Deleted $deleted_count record(s) from table '$tablename'."
    fi
    rm "$tmp_file"
}

function updateTable {
    listTables
    read -p "Enter table name to update: " tablename
    table_path="$DB_Dir/$dbname/$tablename"

    if [[ ! -f "$table_path" ]]; then
        echo "Table '$tablename' does not exist!"
        return
    fi

    
    columns_line=$(head -n 1 "$table_path" | cut -d'=' -f2)
    pk_name=$(grep "^#pk=" "$table_path" | cut -d'=' -f2)
    
    IFS=' ' read -a ColHeaders <<< "$columns_line"
    col_names=()
    col_types=()
    for header in "${ColHeaders[@]}"; do
        col_names+=("$(echo "$header" | cut -d':' -f1)")
        col_types+=("$(echo "$header" | cut -d':' -f2)")
    done

    echo "Available columns: ${col_names[*]}"
    read -p "Enter column to filter by: " condition_col
    read -p "Enter value to match: " condition_val

    condition_index=-1
    for i in "${!col_names[@]}"; do
        if [[ "${col_names[$i]}" == "$condition_col" ]]; then
            condition_index=$i
            break
        fi
    done

    if [[ $condition_index -eq -1 ]]; then
        echo "Column not found!"
        return
    fi

    read -p "Enter column you want to update: " update_col

   
    if [[ "$update_col" == "$pk_name" ]]; then
        echo "Cannot update the primary key column ($pk_name)!"
        return
    fi

    read -p "Enter new value: " new_value

    update_index=-1
    for i in "${!col_names[@]}"; do
        if [[ "${col_names[$i]}" == "$update_col" ]]; then
            update_index=$i
            break
        fi
    done

    if [[ $update_index -eq -1 ]]; then
        echo "Column to update not found!"
        return
    fi

  
    expected_type="${col_types[$update_index]}"
    if [[ "$expected_type" == "int" && ! "$new_value" =~ ^[0-9]+$ ]]; then
        echo "Invalid int value!"
        return
    fi

    tmp_file="${table_path}.tmp"
    header=$(head -n 2 "$table_path")
    echo "$header" > "$tmp_file"

    updated_count=0

    while IFS=':' read -r -a row; do
        if [[ "${row[$condition_index]}" == "$condition_val" ]]; then
            row[$update_index]="$new_value"
            ((updated_count++))
        fi
        echo "${row[*]}" | tr ' ' ':' >> "$tmp_file"
    done < <(tail -n +3 "$table_path")

    mv "$tmp_file" "$table_path"

    if [[ $updated_count -eq 0 ]]; then
        echo "No matching records found to update."
    else
        echo "Updated $updated_count record(s) successfully."
    fi
    rm "$tmp_file"
}
