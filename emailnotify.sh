# Snippet shell function to send email notifications.
# set EMAIL_RECIPIENTS before calling the function
#EMAIL_RECIPIENTS="configure.a.real@email" 

function emailnotify() {
    # create a temp file to store the message body
    EMAIL_MESSAGE=`mktemp`

    # create the subject and message body, record who is logged in at the time of the restart and from where
    EMAIL_SUBJECT="subject of your email sent from host: `hostname` at: `date +%Y-%m-%d.%H%M`"
    echo "This email was sent from host: `hostname` at: `date +%Y-%m-%d.%H%M`" > $EMAIL_MESSAGE
    echo "" >> $EMAIL_MESSAGE
    echo "Current logins:" >> $EMAIL_MESSAGE
    echo "`who -u -H`" >> $EMAIL_MESSAGE

    # Email the recipients
    cat $EMAIL_MESSAGE | /bin/mail -s "${EMAIL_SUBJECT}" "${EMAIL_RECIPIENTS}"

    # remote the temp file after the email is sent
    rm $EMAIL_MESSAGE
}
