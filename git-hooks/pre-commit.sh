#!/bin/bash

# usage: RunTest ["command"] ["stagelist"]  
RunTest()
{
    if [ -z "$1" ] || [ -z "$2" ];then
        return 1
    else
        CMD=$1
        Staged=$2
        echo "$Staged" | while read -r address;do 
            result=`$CMD "$address" 2>&1`  
            if [ $? != 0 ]; then
                case $CMD in
                    "php -l")
                        echo "Check for file \"$address\" failed, result is : $result"
                        ;;
                    "phpcs --standard=Xamin")
                        echo "Codesniffer check on \"$address\" failed, result is : $result"
                        ;;
                    "jshint")
                        echo "Check for file \"$address\" failed, result is : $result"
                        ;;
                esac
                exit 1
            fi
        done
    fi
}

FindInvalidKeys()
{
    if [ -z "$1" ] || [ -z "$2" ];then 
        return 1
    else
        Staged=$1
        InvalKeys=$2
        echo "$Staged" | while read -r address;do
            for key in $InvalKeys;do
                result=`grep -iHn $key "$address" 2>&1`
                if [ $? == 0 ]; then 
                    echo "Found invalid keyword : $address : $result"
                    exit 1
                fi
            done
        done
    fi
}

PHPInvalidKeys="xdebug_break var_dump print_r"
#echo "pre-commit hook"
Staged=`git diff --staged --cached --name-status`
Staged=`echo "$Staged" | grep -v "^D" | sed -e 's/^.\t//g'`

StagedJS=`echo "$Staged" | grep "\.js$"`
StagedPHP=`echo "$Staged" | grep "\.php$"`
StagedPY=`echo "$Staged" | grep "\.py$"`

RunTest "php -l" "$StagedPHP" 
FindInvalidKeys "$StagedPHP" "$PHPInvalidKeys"
RunTest "phpcs --standard=Xamin" "$StagedPHP" 
RunTest "jshint" "$StagedJS" 



exit 0