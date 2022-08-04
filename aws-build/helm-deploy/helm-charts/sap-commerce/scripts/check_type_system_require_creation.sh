#!/usr/bin/env bash

### Usage sample
#if type_system_exists $1; then echo "ts exists"; else echo "nopes"; fi
#echo $(type_system_exists "tedst")


type_system_exists(){
    type_system=$1
    rm -rf outfile
    lambda_response=$(aws lambda invoke --function-name lambda_deployment_utils --invocation-type RequestResponse --region eu-west-1 outfile | jq '.')

    # status_code="$(cat $lambda_response | jq '.StatusCode') "
    status_code=$(jq -r -c '.StatusCode' <<< "$lambda_response")
    
    if [[ "$status_code" -ne "200" ]]; then
        echo $lambda_response
        exit 1
    fi

    allTypeSystemsString=$(cat outfile | jq -r '.body' | jq -r '.[] | @sh' | tr -d \" | tr -d \' )

    IFS=' ' read -ra allTypeSystems <<< "$allTypeSystemsString"
    if [[ " ${allTypeSystems[*]} " == *" $type_system "* ]]; then
        #type system exists
        return 0
    fi

    #type system does not exists
    return 1

}




if type_system_exists $1; then echo false; else echo true; fi
