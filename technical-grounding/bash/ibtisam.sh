#!/bin/bash
<<comment
echo "this is ibtisam."
echo "hello $USER"
echo 'hello $USER'
echo "hello \$USER  $HOSTNAME"


read -p "enter your name: " name

echo "welcome $name" 

e-cho $0
echo $?

echo $name

read -p "Enter your marks:  " marks

if [[ $marks -ge 80 ]]; then
    echo "first"
elif [[ $marks -ge 60 ]]; then
    echo "2nd"
elif [[ $marks -ge 40 ]]; then
    echo "3rd"
else
    echo "you are fail"
fi


if [[ $marks -ge 80 ]]; then echo "first"; elif [[ $marks -ge 60 ]]; then echo "2nd"; elif [[ $marks -ge 40 ]]; then echo "3rd"; else echo "you are fail"; fi


#echo "Please choose the one: a for date, b for current path"; read choice
read -p "Please choose the one: a for date, b for current path  " choice
case $choice in
    a) echo "Today is: $(date)"; echo "Gt. Ibtisam";;
    b) pwd;;
    *) echo "Please provide a valid input.";;
esac

comment

read -p "your age: " age; read -p "your country: " country
[[ $age -gt 18 && $country == "Pakistan" ]] && echo "Adult" || echo "Minor"
if [[ $age -gt 18 && $country == "Pakistan" ]]; then
    echo "Adult"
else
    echo "Minor"
fi
if [[ $age -gt 18 && $country == "Pakistan" ]]; then echo "Adult"; else echo "Minor"; fi
