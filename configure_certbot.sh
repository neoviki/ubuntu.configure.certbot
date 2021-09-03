#!/bin/bash
##################################################
#
#	Author	: Viki ( @ ) Vignesh Natarajan		
#	Contact	: vikiworks.io
#
##################################################

########## COMMON_CODE_BEGIN()   ########
CMD=""
DOMAIN=""
INCOMING=""
FORWARDING=""

CLEAN=0

ARG0=$0
ARG1=$1
ARG2=$2
ARG3=$3
ARG4=$4
ARG5=$5

apache=0
nginx=0

os_support_check(){
    OS_SUPPORTED=0

    #Check Ubuntu 18.04 Support    
    cat /etc/lsb-release | grep 18.04 2> /dev/null 1> /dev/null
    if [ $? -eq 0 ]; then
        OS_SUPPORTED=1
    fi

    #Check Ubuntu 16.04 Support    
    cat /etc/lsb-release | grep 18.04 2> /dev/null 1> /dev/null
    if [ $? -eq 0 ]; then
        OS_SUPPORTED=1
    fi

    if [ $OS_SUPPORTED -eq 0 ]; then
	echo
	echo "Utility is not supported in this version of linux"
	echo
	exit 1
    fi

}


get_command(){
    if [ "$ARG0" == "sudo" ]; then
        CMD="$ARG1"
	DOMAIN="$ARG2"
	EMAIL="$ARG3"
    else
        CMD="$ARG0"
	DOMAIN="$ARG1"
	EMAIL="$ARG2"
    fi
}

usage_check(){
	if [[ "$DOMAIN" =~ ^www.* ]]; then
	    echo ""
    	    echo "    error: DOMAIN name should not start with www"
	    echo ""
	    exit 1
	fi

	if [ -z $DOMAIN ]; then
	    echo ""
	    echo " usage: $CMD <domain name>"
	    echo ""
	    echo " ( or )"
	    echo ""
	    echo " usage: $CMD <domain name> <email address>"
	    echo ""
	    exit 1
	fi

	if [ -z $EMAIL ]; then
		EMAIL="admin@$DOMAIN"
	fi

}

check_permission(){
    touch /bin/test.txt 2> /dev/null 1>/dev/null

    if [ $? -ne 0 ]; then
	echo "permission error, try to run this script wih sudo option"; 
	echo ""
	echo "Example: sudo $CMD"
	echo ""
	exit 1; 
    fi 
    
    rm /bin/test.txt
}

init_bash_installer(){
    os_support_check
    get_command
    check_permission
}
########## COMMON_CODE_END()   ########



generate_certbot_config(){
	if [ $nginx -eq 1 ]; then
		certbot --nginx -d $DOMAIN -d "www.$DOMAIN" -m $EMAIL --non-interactive --agree-tos 
	else
		certbot --apache -d $DOMAIN -d "www.$DOMAIN" -m $EMAIL --non-interactive --agree-tos 
	fi
}

verify_certbot_config(){
    ls
    [ $? -ne 0 ] && { echo "error line ( ${LINENO} )"; exit 1; }
}

certbot_autorenew(){
	certbot renew --dry-run
	crontab -l > cron.txt
	#Your command
	echo "0 1 * * * /usr/bin/certbot renew & > /dev/null" >> cron.txt
	crontab cron.txt
	rm cron.txt
}


reload_web_server(){
    service nginx reload 	2> /dev/null 1> /dev/null
    service apache2 restart 	2> /dev/null 1> /dev/null
}

verify_web_server(){
    status=0
    service nginx status 2> /dev/null 1> /dev/null
    [ $? -eq 0 ] && { status=1;}
    
    service apache2 status 2> /dev/null 1> /dev/null
    [ $? -eq 0 ] && { status=1;}

    if [ $status -eq 0 ];then
	    echo "error: ( ${LINENO} ) Web server not running"
	    exit 1
    fi 
}

webserver_check(){
    status=0
    service nginx status 2> /dev/null 1> /dev/null
    [ $? -eq 0 ] && { status=1;nginx=1;}
    
    service apache2 status 2> /dev/null 1> /dev/null
    [ $? -eq 0 ] && { status=1;apache=1;}

    if [ $status -eq 0 ];then
	    echo "error: ( ${LINENO} ) apache or nginx service is not running"
	    exit 1
    fi 
}

print_user_info(){
echo
echo
	echo "Certificate related notification will be sent to ( $EMAIL )"
echo
echo
}

init_bash_installer
usage_check
webserver_check
generate_certbot_config
certbot_autorenew
verify_certbot_config
reload_web_server
verify_web_server
print_user_info


