#!/bin/bash

SWITCH_IPS=("192.168.88.50")  # Массив IP-адресов коммутаторов
COMMUNITY="public"          # SNMP community string
OUTPUT_FILE="/home/user/8/macs.txt"
PREVIOUS_OUTPUT_FILE="/home/user/8/previous_macs.txt"

# Очищаем файл перед новым сканированием
echo "MAC-адреса, полученные с коммутаторов" > "$OUTPUT_FILE"
echo "==========================" >> "$OUTPUT_FILE"

# Получаем список MAC-адресов и связанных значений из таблицы каждого коммутатора
for SWITCH_IP in "${SWITCH_IPS[@]}"; do
    echo "Сканируем коммутатор: $SWITCH_IP" >> "$OUTPUT_FILE"

    snmpwalk -v2c -c "$COMMUNITY" "$SWITCH_IP" 1.3.6.1.2.1.17.4.3.1.1 | while read -r line; do
        # Извлекаем нужные поля и объединяем их в одну строку
        MAC_INFO=$(echo "$line" | awk '{print $4, $5, $6, $7, $8, $9}')
        echo "$MAC_INFO" >> "$OUTPUT_FILE"
    done

    echo "" >> "$OUTPUT_FILE"  # Добавляем пустую строку между результатами разных коммутаторов
done

# Сравниваем текущие результаты с предыдущими
if [ -f "$PREVIOUS_OUTPUT_FILE" ]; then
    echo "new devices:" > /home/user/8/new_devices.txt

    # Сравниваем текущие MAC-адреса с предыдущими
    while read -r current_mac; do
        # Проверяем, есть ли текущий MAC в предыдущем файле
        if ! grep -qF -- "$current_mac" "$PREVIOUS_OUTPUT_FILE"; then
            echo "$current_mac" >> /home/user/8/new_devices.txt
        fi
    done < "$OUTPUT_FILE"

    # Выводим новые устройства
    if [ -s /home/user/8/new_devices.txt ]; then
        echo "Новые устройства:"
        cat /home/user/8/new_devices.txt

        # Добавляем новые устройства в файл previous_macs.txt
        cat /home/user/8/new_devices.txt >> "$PREVIOUS_OUTPUT_FILE"
    else
        echo "Новых устройств не найдено."
    fi
fi
cat "$PREVIOUS_OUTPUT_FILE"
