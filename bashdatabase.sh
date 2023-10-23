#!/bin/bash
numf=1;
globalcol=()
dbcreate() {
    local dbname
    dbname="$1"
    touch "$dbname.txt"
    echo "$dbname" > "$dbname.txt"
}

tablecreate() {
    local dbname
    dbname="$1"
    fields=("${@:2}")
    num_fields=${#fields[@]}
    numf="$num_fields"
    #echo "$numf"


    if [ ! -f "$dbname.txt" ]; then
        echo "Error: Database '$dbname' not found."
        return 1
    fi

    linelen=39
    rowlen=7
    numstars=$((4+8*num_fields+num_fields-1))

    if ((numstars > linelen)); then
        echo "Error: Line length is greater than 39 characters. Remove args or give them shorter names."
        exit 1
    fi

    for ((i = 0; i < numstars; i++)); do
        echo -n "*" >> "$dbname.txt"
    done
    
    echo "" >> "$dbname.txt"
    final="*"

    for field in "${fields[@]}"; do
        globalcol+=("$field")
        formatted_field=$(echo "$field" | awk '{printf("* %-*s", 7, $0)}')
        final+="$formatted_field"
    done
    final+="**"

    echo "$final" >> "$dbname.txt"
}

insert_data() {
    local dbname 
    dbname=$1
    local data 
    data=()

    if [ ! -f "$dbname.txt" ]; then
        echo "Error: Database '$dbname' not found."
        return 1
    fi

    for col in "${globalcol[@]}"; do
        read -p "Enter value for $col: " value

        if [ "$col" == "name" ] || [ "$col" == "id" ]; then
            if [ ! -n "$value" ]; then 
                while true; do
                    echo "Error: Field '$col' is mandatory. Please provide a value."
                    read -p "Enter value for $col: " value
                    if [ -n "$value" ]; then
                        break
                    fi
                done
            fi
        fi 

        data+=("${value:-/}")

            
    done
    
    #echo "$numf"
    #echo "$data"
    final="*"

    for field in "${data[@]}"; do
        if [ "${#field}" -gt 8 ]; then
            echo "Error: Field '$field' exceeds 8 characters."
            return 1
        fi
        formatted_field=$(echo "$field" | awk '{printf("* %-*s", 7, $0)}')
        final+="$formatted_field"
    done
    final+="**"

    echo "$final" >> "$dbname.txt"

}

select_data() {
    local dbname
    dbname="$1"
    echo "Enter the field name:"
    read field_name

    if [ -z "$field_name" ]; then
        cat "$dbname.txt"
    else

        echo "Enter the value to search:"
        read search_value


        #echo "Debug: Field Name: $field_name, Search Value: $search_value"
        
        if [ -f "$dbname.txt" ]; then
            
            result=$(awk -F"[ *]+" -v field="$field_name" -v value="$search_value" '
                        NR==3 {
                            for (i=1; i<=NF; i++)
                                if ($i == field)
                                    col=i
                            } 
                        NR>3 && $col == value {
                            print $0
                            }' "$dbname.txt")

            # Check if any result is found
            if [ -n "$result" ]; then
                echo "Results:"
                head -n 3 "$dbname.txt"

                echo "$result"
            else
                echo "No matching records found."
            fi
        else
            echo "Database file not found."
        fi
fi
}

delete_data() {
    local dbname
    dbname=$1

    # Check if the database file exists
    if [ ! -f "$dbname.txt" ]; then
        echo "Error: Database '$dbname' not found."
        return 1
    fi

    echo "Enter the field name:"
    read field_name

    echo "Enter the value to delete:"
    read delete_value

    awk -F"[ *]+" -v field="$field_name" -v value="$delete_value" '
        NR == 3 {
            for (i=1; i<=NF; i++) {
                if ($i == field) {
                    col=i
                    break
                }
            }
        }
        NR <= 3 || $col != value {
            print $0
        }
    ' col=0 "$dbname.txt" > tmp.txt

    mv tmp.txt "$dbname.txt"
    echo "Deletion successful."
}


# Input read
while true; do
    read -p "Enter command (dbcreate, tablecreate, insert_data, select_data, delete_data, exit): " command

    case $command in
        dbcreate)
            read -p "Enter database name: " dbname
            dbcreate "$dbname"
            ;;
        tablecreate)
            read -p "Enter database name: " dbname
            read -p "Enter table fields (space-separated): " fields
            tablecreate "$dbname" $fields
            ;;
        insert_data)
            read -p "Enter database name: " dbname
            insert_data "$dbname" 
            ;;
        select_data)
            read -p "Enter database name: " dbname
            select_data "$dbname"
            ;;
        delete_data)
            read -p "Enter database name: " dbname
            delete_data "$dbname"
            ;;
        exit)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid command. Try again."
            ;;
    esac
done
